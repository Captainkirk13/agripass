import { api, ApiError } from '../lib/api.js';
import * as store from './store.js';

const SCAN_TIMEOUT_MS = 4000;
const SYNC_TIMEOUT_MS = 20000;
const SYNC_BATCH = 500;
const RETRY_MS = 15000;
const REFRESH_MS = 60000;
const SYNCED_RESULTS = ['valid', 'already_synced', 'duplicate'];
const FIX_MAX_AGE_MS = 20000;
const LOCATE_TIMEOUT_MS = 12000;

export const MESSAGES = {
    valid: 'Welcome!',
    duplicate: 'Already Checked In for this Session.',
    wrong_event: 'This pass is for a different event.',
    invalid: 'Unrecognized or tampered QR pass.',
    not_in_roster: 'Pass not in the offline roster. It may be a new registration — direct to the Registration Desk.',
    outside_fence: 'Outside the venue. Scan again inside the allowed radius.',
    fence_incomplete: 'Venue radius is turned on, but the event location is incomplete. An admin needs to set it before scanning.',
};

function locationError(err) {
    if (!window.isSecureContext) {
        return 'Location needs a secure page. Open the scanner with the https address, allow location, then scan again inside the venue.';
    }
    if (err?.code === 1) return 'Location is blocked. Allow location for this site, then scan again inside the venue.';
    if (err?.code === 3) return 'Location timed out. Move closer to a window or the entrance and scan again.';
    return 'Location is unavailable. Turn on location services and scan again inside the venue.';
}

/** The venue circle from the roster, or null when the event does not restrict scans. */
function activeFence(roster) {
    const g = roster?.geofence;
    if (!g?.enabled) return null;
    const latitude = Number(g.latitude);
    const longitude = Number(g.longitude);
    const radius = Number(g.radius_m);
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || !Number.isFinite(radius)) {
        return { incomplete: true };
    }
    return { latitude, longitude, radius };
}

function positionBody(fix) {
    return fix ? { latitude: fix.latitude, longitude: fix.longitude } : {};
}

function metersBetween(lat1, lng1, lat2, lng2) {
    const earth = 6371000;
    const toRad = (deg) => deg * Math.PI / 180;
    const dLat = toRad(lat2 - lat1);
    const dLng = toRad(lng2 - lng1);
    const a = Math.sin(dLat / 2) ** 2
        + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLng / 2) ** 2;
    return 2 * earth * Math.asin(Math.min(1, Math.sqrt(a)));
}

const key = (registrationId, sessionId) => `${registrationId}:${sessionId}`;

/**
 * Check-in state for one event on this device. Scans go to the server while it is reachable;
 * otherwise they are validated against the cached roster and queued in IndexedDB for /api/sync-attendance.
 * Dispatches 'change' whenever counts, connectivity or the queue change.
 */
export class CheckInEngine extends EventTarget {
    constructor(eventId, deviceId) {
        super();
        this.eventId = eventId;
        this.deviceId = deviceId;
        this.roster = null;
        this.sessionId = null;
        this.reachable = navigator.onLine;
        this.needsLogin = false;
        this.syncing = false;
        this.pending = 0;
        this.problems = [];
        this.byToken = new Map();
        this.attendance = new Map();
        this.timers = [];
        this.fix = null;
        this.watchId = null;
    }

    async load() {
        const cached = await store.getRoster(this.eventId);
        if (cached) await this.index(cached);
        try {
            if (!this.reachable) throw new TypeError('offline');
            await this.refreshRoster();
        } catch (err) {
            if (!(err instanceof ApiError)) this.reachable = false;
            if (!this.roster) {
                throw err instanceof ApiError ? err : new Error('No roster downloaded for this event yet. Connect to the internet once to download it.');
            }
        }
        await this.countQueue();
        this.timers.push(setInterval(() => this.tick(), RETRY_MS));
        this.onOnline = () => { this.reachable = true; this.tick(); };
        this.onOffline = () => this.setReachable(false);
        window.addEventListener('online', this.onOnline);
        window.addEventListener('offline', this.onOffline);
        this.sync();
    }

    destroy() {
        this.timers.forEach(clearInterval);
        window.removeEventListener('online', this.onOnline);
        window.removeEventListener('offline', this.onOffline);
        this.clearWatch();
    }

    /** One line for the setup screen when this event only accepts scans near the venue. */
    fenceLabel() {
        const fence = activeFence(this.roster);
        if (!fence) return '';
        if (fence.incomplete) return MESSAGES.fence_incomplete;
        return `Venue radius is on: scans must be within ${fence.radius} m. Allow location when the browser asks.`;
    }

    get sessions() {
        return this.roster?.sessions || [];
    }

    get session() {
        return this.sessions.find((s) => Number(s.session_id) === Number(this.sessionId)) || null;
    }

    stats() {
        let checkedIn = 0;
        for (const k of this.attendance.keys()) {
            if (k.endsWith(`:${this.sessionId}`)) checkedIn++;
        }
        const registrations = this.roster?.registrations || [];
        return {
            checkedIn,
            registered: registrations.length,
            pending: this.pending,
            problems: this.problems.length,
        };
    }

    async refreshRoster() {
        const roster = await api(`/events/${this.eventId}/roster`, { timeout: SYNC_TIMEOUT_MS });
        this.setReachable(true);
        await this.index({ ...roster, event_id: this.eventId, downloaded_at: new Date().toISOString() });
        await store.saveRoster(this.roster);
        this.emit();
    }

    async index(roster) {
        this.roster = roster;
        this.byToken = new Map(roster.registrations.map((r) => [r.qr_token, r]));
        this.attendance = new Map(roster.attendances.map((a) => [key(a.registration_id, a.session_id), a.check_in_time]));
        for (const record of await store.allQueued()) {
            if (record.event_id === this.eventId && record.status === 'pending') {
                this.attendance.set(key(record.registration_id, record.session_id), record.check_in_time);
            }
        }
        this.watchFence();
    }

    watchFence() {
        const fence = activeFence(this.roster);
        if (!fence || fence.incomplete || !navigator.geolocation || !window.isSecureContext) {
            this.clearWatch();
            return;
        }
        if (this.watchId != null) return;
        this.watchId = navigator.geolocation.watchPosition(
            (pos) => {
                this.fix = {
                    latitude: pos.coords.latitude,
                    longitude: pos.coords.longitude,
                    at: Date.now(),
                };
            },
            () => {},
            { enableHighAccuracy: true, maximumAge: FIX_MAX_AGE_MS, timeout: LOCATE_TIMEOUT_MS },
        );
    }

    clearWatch() {
        if (this.watchId != null && navigator.geolocation) {
            navigator.geolocation.clearWatch(this.watchId);
        }
        this.watchId = null;
    }

    freshFix() {
        if (!this.fix || Date.now() - this.fix.at > FIX_MAX_AGE_MS) return null;
        return this.fix;
    }

    locate() {
        const cached = this.freshFix();
        if (cached) return Promise.resolve(cached);
        if (!navigator.geolocation || !window.isSecureContext) {
            return Promise.reject({ code: window.isSecureContext ? 2 : 1 });
        }
        return new Promise((resolve, reject) => {
            navigator.geolocation.getCurrentPosition((pos) => {
                this.fix = {
                    latitude: pos.coords.latitude,
                    longitude: pos.coords.longitude,
                    at: Date.now(),
                };
                resolve(this.fix);
            }, reject, { enableHighAccuracy: true, maximumAge: FIX_MAX_AGE_MS, timeout: LOCATE_TIMEOUT_MS });
        });
    }

    /**
     * When the event has a venue radius, a scan needs a recent location inside that circle.
     * The same reading is sent to the server, which checks it again.
     */
    async gateLocation() {
        const fence = activeFence(this.roster);
        if (!fence) return { fix: null };
        if (fence.incomplete) {
            return { blocked: { result: 'outside_fence', message: MESSAGES.fence_incomplete, offline: !this.reachable } };
        }
        let fix;
        try {
            fix = await this.locate();
        } catch (err) {
            return { blocked: { result: 'outside_fence', message: locationError(err), offline: !this.reachable } };
        }
        const away = metersBetween(fence.latitude, fence.longitude, fix.latitude, fix.longitude);
        if (away > fence.radius) {
            return {
                blocked: {
                    result: 'outside_fence',
                    message: `Outside the venue. This scan is about ${Math.round(away)} m away, and only scans within ${fence.radius} m are accepted.`,
                    offline: !this.reachable,
                },
            };
        }
        return { fix };
    }

    search(query) {
        const q = query.trim().toLowerCase();
        if (q.length < 2) return [];
        return this.roster.registrations
            .filter((r) => `${r.name} ${r.chapter_region || ''}`.toLowerCase().includes(q))
            .slice(0, 25)
            .map((r) => ({ ...r, checked_in_at: this.attendance.get(key(r.registration_id, this.sessionId)) || null }));
    }

    async checkIn(rawToken) {
        const token = rawToken.trim();
        const clientUuid = store.uuid();
        const checkInTime = new Date().toISOString();
        const sessionId = Number(this.sessionId);
        const gate = await this.gateLocation();
        if (gate.blocked) return gate.blocked;
        const fix = gate.fix;

        if (this.reachable && !this.needsLogin) {
            try {
                const res = await api('/checkin', {
                    method: 'POST',
                    headers: { 'X-Event-ID': String(this.eventId) },
                    body: {
                        qr_token: token,
                        session_id: sessionId,
                        device_id: this.deviceId,
                        client_uuid: clientUuid,
                        ...positionBody(fix),
                    },
                    timeout: SCAN_TIMEOUT_MS,
                });
                this.setReachable(true);
                return this.afterServerResult(token, sessionId, res);
            } catch (err) {
                if (!(err instanceof ApiError)) {
                    this.setReachable(false);
                } else if (err.status === 401) {
                    this.setNeedsLogin(true);
                } else {
                    return { result: 'error', message: err.message, offline: false };
                }
            }
        }

        return this.checkInOffline(token, sessionId, clientUuid, checkInTime, fix);
    }

    afterServerResult(token, sessionId, res) {
        const local = this.byToken.get(token);
        const attendee = res.attendee || (local && { ...local });
        if (attendee && SYNCED_RESULTS.includes(res.result)) {
            this.recordAttendance(attendee.registration_id, sessionId, res.check_in_time);
        }
        this.emit();
        return { ...res, result: res.result === 'already_synced' ? 'valid' : res.result, attendee, offline: false };
    }

    async checkInOffline(token, sessionId, clientUuid, checkInTime, fix = null) {
        const parts = token.split('|');
        if (parts.length !== 4 || parts[0] !== 'AGRIPASS') {
            return { result: 'invalid', message: MESSAGES.invalid, offline: true };
        }
        if (Number(parts[1]) !== this.eventId) {
            return { result: 'wrong_event', message: MESSAGES.wrong_event, offline: true };
        }
        const registration = this.byToken.get(token);
        if (!registration) {
            return { result: 'invalid', message: MESSAGES.not_in_roster, offline: true };
        }
        const attendee = { ...registration };
        const previous = this.attendance.get(key(registration.registration_id, sessionId));
        if (previous) {
            return { result: 'duplicate', message: MESSAGES.duplicate, check_in_time: previous, attendee, offline: true };
        }

        await store.enqueue({
            client_uuid: clientUuid,
            event_id: this.eventId,
            session_id: sessionId,
            registration_id: registration.registration_id,
            qr_token: token,
            name: registration.name,
            check_in_time: checkInTime,
            latitude: fix?.latitude ?? null,
            longitude: fix?.longitude ?? null,
            status: 'pending',
        });
        this.recordAttendance(registration.registration_id, sessionId, checkInTime);
        this.pending++;
        this.emit();
        this.sync();
        return { result: 'valid', message: MESSAGES.valid, check_in_time: checkInTime, attendee, offline: true };
    }

    recordAttendance(registrationId, sessionId, time) {
        const k = key(registrationId, sessionId);
        if (!this.attendance.has(k)) this.attendance.set(k, time);
    }

    /** Uploads every pending scan on this device (all events), then refreshes counts. Safe to call often. */
    async sync() {
        if (this.syncing || !this.reachable || this.needsLogin) return;
        this.syncing = true;
        this.emit();
        try {
            const pending = (await store.allQueued()).filter((r) => r.status === 'pending');
            const byEvent = new Map();
            pending.forEach((r) => byEvent.set(r.event_id, [...(byEvent.get(r.event_id) || []), r]));
            for (const [eventId, records] of byEvent) {
                for (let i = 0; i < records.length; i += SYNC_BATCH) {
                    await this.syncBatch(eventId, records.slice(i, i + SYNC_BATCH));
                }
            }
        } catch (err) {
            if (!(err instanceof ApiError)) this.setReachable(false);
            else if (err.status === 401) this.setNeedsLogin(true);
        } finally {
            this.syncing = false;
            await this.countQueue();
        }
    }

    async syncBatch(eventId, records) {
        let res;
        try {
            res = await api('/sync-attendance', {
                method: 'POST',
                headers: { 'X-Event-ID': String(eventId) },
                body: {
                    device_id: this.deviceId,
                    records: records.map(({ client_uuid, session_id, qr_token, check_in_time, latitude, longitude }) => ({
                        client_uuid,
                        session_id,
                        qr_token,
                        check_in_time,
                        ...positionBody(latitude == null || longitude == null ? null : { latitude, longitude }),
                    })),
                },
                timeout: SYNC_TIMEOUT_MS,
            });
        } catch (err) {
            if (!(err instanceof ApiError) || err.status === 401) throw err;
            // The server rejected the whole batch (for example, the event was archived): keep the scans for review.
            res = { results: records.map((r) => ({ client_uuid: r.client_uuid, result: 'rejected', message: err.message })) };
        }
        this.setReachable(true);

        const done = [];
        const failed = [];
        for (const outcome of res.results) {
            const record = records.find((r) => r.client_uuid === outcome.client_uuid);
            if (!record) continue;
            if (SYNCED_RESULTS.includes(outcome.result)) done.push(record.client_uuid);
            else failed.push({ ...record, status: 'error', result: outcome.result, message: outcome.message });
        }
        await store.dequeue(done);
        await store.enqueueAll(failed);
        if (eventId === this.eventId && failed.length) {
            failed.forEach((r) => this.attendance.delete(key(r.registration_id, r.session_id)));
        }
    }

    async countQueue() {
        const all = await store.allQueued();
        this.pending = all.filter((r) => r.status === 'pending').length;
        this.problems = all.filter((r) => r.status === 'error');
        this.emit();
    }

    async dismissProblems() {
        await store.dequeue(this.problems.map((r) => r.client_uuid));
        await this.countQueue();
    }

    async tick() {
        if (!this.reachable) {
            try {
                await api('/health', { timeout: 4000 });
                this.setReachable(true);
            } catch {
                return;
            }
        }
        await this.sync();
        const age = Date.now() - new Date(this.roster.downloaded_at).getTime();
        if (!this.syncing && age > REFRESH_MS && !this.needsLogin) {
            await this.refreshRoster().catch((err) => {
                if (!(err instanceof ApiError)) this.setReachable(false);
            });
        }
    }

    setReachable(value) {
        if (this.reachable === value) return;
        this.reachable = value;
        this.emit();
        if (value) this.sync();
    }

    setNeedsLogin(value) {
        this.needsLogin = value;
        this.emit();
        if (!value) this.sync();
    }

    emit() {
        this.dispatchEvent(new Event('change'));
    }
}
