import { api } from '../../lib/api.js';
import { activateEvent } from '../app.js';
import { isAdmin, loadEvents } from '../state.js';
import { renderCertificates } from './certificates.js?v=20261107-duration2';
import { renderReports } from './reports.js';
import {
    confirmDialog, emptyState, esc, formData, formatDate, formatDateRange, formatDateTime, formatDuration,
    formatTime, openModal, statusBadge, toast, toastError,
} from '../../lib/ui.js';

const TABS = [
    ['overview', 'Overview', 'info-circle'],
    ['sessions', 'Sessions', 'clock'],
    ['fields', 'Registration form', 'ui-checks'],
    ['registrations', 'Registrations', 'people'],
    ['certificates', 'Certificates', 'award', 'admin'],
    ['reports', 'Reports', 'bar-chart', 'admin'],
];

const HELP_TOPICS = { registrations: 'registrations', certificates: 'certificates', reports: 'reports' };

const NEXT_STATUS = {
    Draft: { status: 'Active', label: 'Publish event', icon: 'send', help: 'Opens registration for this event.' },
    Active: { status: 'Completed', label: 'Mark as completed', icon: 'flag', help: 'Closes registration and scanning. If this is the active event, it will no longer be active.' },
    Completed: { status: 'Archived', label: 'Archive event', icon: 'archive', help: 'Archived events are permanently locked and cannot be edited.' },
};

const FIELD_TYPES = { text: 'Text', number: 'Number', select: 'Dropdown', checkbox: 'Checkbox' };

export async function renderEventDetail(eventId, tab = 'overview') {
    const tabs = TABS.filter(([, , , access]) => access !== 'admin' || isAdmin());
    if (!tabs.some(([key]) => key === tab)) tab = 'overview';
    const { event } = await api(`/events/${eventId}`);
    const view = document.getElementById('view');
    const editable = isAdmin() && event.status !== 'Archived';
    const isActive = Number(event.is_active) === 1;
    const next = NEXT_STATUS[event.status];

    view.innerHTML = `
        <div class="d-flex align-items-start gap-3 mb-2">
            <nav aria-label="breadcrumb" class="me-auto"><ol class="breadcrumb small mb-0">
                <li class="breadcrumb-item"><a href="#/events">Events</a></li>
                <li class="breadcrumb-item active">${esc(event.title)}</li>
            </ol></nav>
            <a class="small text-muted text-nowrap" href="#/help/${HELP_TOPICS[tab] || 'events'}"><i class="bi bi-question-circle me-1"></i>Help with this page</a>
        </div>
        <div class="d-flex flex-wrap gap-3 align-items-start justify-content-between mb-3">
            <div>
                <h1 class="h3 page-title d-flex flex-wrap align-items-center gap-2">${esc(event.title)} ${statusBadge(event.status)}
                    ${isActive ? '<span class="badge text-bg-warning"><i class="bi bi-broadcast"></i> Active event</span>' : ''}</h1>
                <div class="text-muted small mt-1"><i class="bi bi-geo-alt me-1"></i>${esc(event.venue)}
                    <span class="mx-2">&middot;</span><i class="bi bi-calendar3 me-1"></i>${formatDateRange(event.start_date, event.end_date)}
                    <span class="mx-2">&middot;</span>${esc(event.event_type)}</div>
            </div>
            ${isAdmin() ? `
            <div class="d-flex flex-wrap gap-2">
                ${['Draft', 'Active'].includes(event.status) && !isActive ? '<button class="btn btn-accent" id="activate"><i class="bi bi-broadcast me-1"></i>Set as active event</button>' : ''}
                ${editable ? `<a class="btn btn-outline-primary" href="#/events/${event.event_id}/edit"><i class="bi bi-pencil me-1"></i>Edit</a>` : ''}
                ${next ? `<button class="btn btn-outline-secondary" id="transition"><i class="bi bi-${next.icon} me-1"></i>${next.label}</button>` : ''}
            </div>` : ''}
        </div>
        ${event.status === 'Archived' ? '<div class="alert alert-secondary small"><i class="bi bi-lock me-1"></i>This event is archived and locked for audit. Data can be viewed but not changed.</div>' : ''}
        <ul class="nav nav-tabs mb-4">
            ${tabs.map(([key, label, icon]) => `<li class="nav-item"><a class="nav-link ${key === tab ? 'active' : ''}" href="#/events/${event.event_id}/${key}">
                <i class="bi bi-${icon} me-1"></i>${label}${tabCount(event, key)}</a></li>`).join('')}
        </ul>
        <div id="tab-content"></div>`;

    document.getElementById('activate')?.addEventListener('click', () => activateEvent(event.event_id));
    document.getElementById('transition')?.addEventListener('click', async () => {
        const ok = await confirmDialog({
            title: next.label,
            message: `${esc(next.help)}<br><br>Move <strong>${esc(event.title)}</strong> from ${event.status} to <strong>${next.status}</strong>?`,
            confirmLabel: next.label,
            confirmClass: next.status === 'Archived' ? 'btn-danger' : 'btn-primary',
        });
        if (!ok) return;
        try {
            await api(`/events/${event.event_id}/status`, { method: 'POST', body: { status: next.status } });
            await loadEvents();
            toast(`Event moved to ${next.status}.`);
            renderEventDetail(eventId, tab);
        } catch (err) {
            toastError(err);
        }
    });

    const reload = () => renderEventDetail(eventId, tab);
    const content = document.getElementById('tab-content');
    if (tab === 'overview') renderOverview(content, event);
    if (tab === 'sessions') renderSessions(content, event, editable, reload);
    if (tab === 'fields') renderFields(content, event, editable, reload);
    if (tab === 'registrations') await renderRegistrations(content, event);
    if (tab === 'certificates') await renderCertificates(content, event, reload);
    if (tab === 'reports') await renderReports(content, event);
    view.querySelector('.nav-tabs .active')?.scrollIntoView({ block: 'nearest', inline: 'nearest' });
}

function totalSessionHours(sessions = []) {
    return sessions.reduce((total, session) => {
        const [startHour, startMinute] = String(session.start_time).split(':').map(Number);
        const [endHour, endMinute] = String(session.end_time).split(':').map(Number);
        let minutes = endHour * 60 + endMinute - (startHour * 60 + startMinute);
        if (minutes < 0) minutes += 24 * 60;
        return total + minutes / 60;
    }, 0);
}

function tabCount(event, key) {
    const count = { sessions: event.sessions.length, fields: event.custom_fields.length, registrations: event.stats.registrations }[key];
    return count === undefined ? '' : ` <span class="badge rounded-pill text-bg-light border ms-1">${count}</span>`;
}

function fenceSummary(event) {
    if (Number(event.geofence_enabled) !== 1) return 'Off';
    const lat = event.geofence_latitude;
    const lng = event.geofence_longitude;
    const radius = event.geofence_radius_m;
    if (lat == null || lng == null || radius == null) return 'On, but the venue location is incomplete';
    return `On · scans within ${esc(radius)} m of ${esc(lat)}, ${esc(lng)}`;
}

function renderOverview(el, event) {
    const { stats } = event;
    const row = (label, value) => `<dt class="col-sm-5 text-muted fw-normal">${label}</dt><dd class="col-sm-7">${value || '<span class="text-muted">—</span>'}</dd>`;

    el.innerHTML = `
        <div class="row g-4">
            <div class="col-lg-7">
                <div class="card h-100">
                    <div class="card-header bg-white py-3"><h2 class="h6 mb-0 fw-semibold">Event information</h2></div>
                    <div class="card-body">
                        <dl class="row mb-0">
                            ${row('Event type', esc(event.event_type))}
                            ${row('Venue', esc(event.venue))}
                            ${row('Check-in radius', fenceSummary(event))}
                            ${row('Dates', formatDateRange(event.start_date, event.end_date))}
                            ${row('Scheduled attendance', formatDuration(totalSessionHours(event.sessions)))}
                            ${row('Certificate attendance requirement', `${esc(event.certificate_min_attendance_pct)}% of sessions attended`)}
                            ${row('Certificate signatories', [event.cert_signatory_name, event.cert_signatory_2_name].filter(Boolean).map((n, i) => `${esc(n)}<div class="small text-muted">${esc(i ? event.cert_signatory_2_title : event.cert_signatory_title)}</div>`).join(''))}
                            ${row('Created', formatDateTime(event.created_at))}
                        </dl>
                        ${event.description ? `<hr><p class="mb-0" style="white-space:pre-line">${esc(event.description)}</p>` : ''}
                    </div>
                </div>
            </div>
            <div class="col-lg-5">
                <div class="card h-100">
                    <div class="card-header bg-white py-3"><h2 class="h6 mb-0 fw-semibold">At a glance</h2></div>
                    <ul class="list-group list-group-flush">
                        <li class="list-group-item d-flex justify-content-between"><span>Total registrations</span><strong>${stats.registrations}</strong></li>
                        <li class="list-group-item d-flex justify-content-between"><span>Checked in (any session)</span><strong>${stats.checked_in}</strong></li>

                    </ul>
                </div>
            </div>
        </div>`;
}

function renderSessions(el, event, editable, reload) {
    el.innerHTML = `
        <div class="card">
            <div class="card-header bg-white py-3 d-flex align-items-center justify-content-between">
                <div>
                    <h2 class="h6 mb-0 fw-semibold">Sessions</h2>
                    <div class="small text-muted">Each session is checked in separately using the same QR pass.</div>
                </div>
                ${editable ? '<button class="btn btn-primary btn-sm" id="add-session"><i class="bi bi-plus-lg me-1"></i>Add session</button>' : ''}
            </div>
            ${event.sessions.length ? `
            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead><tr><th>Session</th><th>Date</th><th>Time</th><th class="text-center">Checked in</th><th></th></tr></thead>
                    <tbody>
                        ${event.sessions.map((s) => `
                        <tr>
                            <td class="fw-semibold">${esc(s.session_name)}</td>
                            <td>${formatDate(s.session_date, { weekday: 'short', month: 'short', day: 'numeric', year: 'numeric' })}</td>
                            <td>${formatTime(s.start_time)} – ${formatTime(s.end_time)}</td>
                            <td class="text-center">${event.stats.session_attendance[s.session_id] || 0}</td>
                            <td class="text-end">${editable ? `<button class="btn btn-sm btn-outline-danger" data-delete="${s.session_id}" title="Delete session"><i class="bi bi-trash"></i></button>` : ''}</td>
                        </tr>`).join('')}
                    </tbody>
                </table>
            </div>` : `<div class="card-body">${emptyState('clock', 'No sessions yet', 'Add at least one session (e.g. "Day 1 Morning Plenary") so scanners can record attendance.')}</div>`}
        </div>`;

    el.querySelector('#add-session')?.addEventListener('click', () => {
        const lastDate = event.sessions.at(-1)?.session_date || event.start_date;
        openModal({
            title: 'Add session',
            submitLabel: 'Add session',
            body: `
                <div class="mb-3">
                    <label class="form-label" for="session_name">Session name</label>
                    <input class="form-control" id="session_name" name="session_name" maxlength="100" placeholder="e.g. Day 1 Morning Plenary" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="session_date">Date</label>
                    <input class="form-control" type="date" id="session_date" name="session_date" min="${event.start_date}" max="${event.end_date}" value="${lastDate}" required>
                </div>
                <div class="row g-3">
                    <div class="col"><label class="form-label" for="start_time">Starts</label>
                        <input class="form-control" type="time" id="start_time" name="start_time" value="08:00" required></div>
                    <div class="col"><label class="form-label" for="end_time">Ends</label>
                        <input class="form-control" type="time" id="end_time" name="end_time" value="12:00" required></div>
                </div>`,
            onSubmit: async (form) => {
                await api(`/events/${event.event_id}/sessions`, { method: 'POST', body: formData(form) });
                toast('Session added.');
                reload();
            },
        });
    });

    el.querySelectorAll('[data-delete]').forEach((btn) => btn.addEventListener('click', async () => {
        const session = event.sessions.find((s) => String(s.session_id) === btn.dataset.delete);
        const attended = event.stats.session_attendance[session.session_id] || 0;
        const ok = await confirmDialog({
            title: 'Delete session',
            message: `Delete <strong>${esc(session.session_name)}</strong>?${attended ? ` Its <strong>${attended}</strong> attendance record(s) will also be deleted.` : ''}`,
            confirmLabel: 'Delete',
            confirmClass: 'btn-danger',
        });
        if (!ok) return;
        try {
            await api(`/events/${event.event_id}/sessions/${session.session_id}`, { method: 'DELETE' });
            toast('Session deleted.');
            reload();
        } catch (err) {
            toastError(err);
        }
    }));
}

function renderFields(el, event, editable, reload) {
    el.innerHTML = `
        <div class="card">
            <div class="card-header bg-white py-3 d-flex align-items-center justify-content-between">
                <div>
                    <h2 class="h6 mb-0 fw-semibold">Custom registration fields</h2>
                    <div class="small text-muted">Asked in addition to the standard name, email, contact and chapter fields.</div>
                </div>
                ${editable ? '<button class="btn btn-primary btn-sm" id="add-field"><i class="bi bi-plus-lg me-1"></i>Add field</button>' : ''}
            </div>
            ${event.custom_fields.length ? `
            <div class="table-responsive">
                <table class="table align-middle mb-0">
                    <thead><tr><th>Label</th><th>Type</th><th>Options</th><th>Required</th><th></th></tr></thead>
                    <tbody>
                        ${event.custom_fields.map((f) => `
                        <tr>
                            <td class="fw-semibold">${esc(f.field_label)}</td>
                            <td>${FIELD_TYPES[f.field_type]}</td>
                            <td>${(f.field_options || []).map((o) => `<span class="badge text-bg-light border me-1">${esc(o)}</span>`).join('') || '<span class="text-muted">—</span>'}</td>
                            <td>${Number(f.is_required) ? '<i class="bi bi-check-circle-fill text-success"></i>' : '<span class="text-muted">Optional</span>'}</td>
                            <td class="text-end">${editable ? `<button class="btn btn-sm btn-outline-danger" data-delete="${f.field_id}" title="Delete field"><i class="bi bi-trash"></i></button>` : ''}</td>
                        </tr>`).join('')}
                    </tbody>
                </table>
            </div>` : `<div class="card-body">${emptyState('ui-checks', 'No custom fields', 'Add fields like T-shirt size, dietary restrictions or sub-discipline.')}</div>`}
        </div>`;

    el.querySelector('#add-field')?.addEventListener('click', () => {
        const form = openModal({
            title: 'Add registration field',
            submitLabel: 'Add field',
            body: `
                <div class="mb-3">
                    <label class="form-label" for="field_label">Label</label>
                    <input class="form-control" id="field_label" name="field_label" maxlength="100" placeholder="e.g. T-Shirt Size" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="field_type">Type</label>
                    <select class="form-select" id="field_type" name="field_type">
                        ${Object.entries(FIELD_TYPES).map(([value, label]) => `<option value="${value}">${label}</option>`).join('')}
                    </select>
                </div>
                <div class="mb-3 d-none" id="options-group">
                    <label class="form-label" for="field_options">Options</label>
                    <input class="form-control" id="field_options" name="field_options" placeholder="XS, S, M, L, XL">
                    <div class="form-text">Separate options with commas.</div>
                </div>
                <div class="form-check">
                    <input class="form-check-input" type="checkbox" id="is_required" name="is_required">
                    <label class="form-check-label" for="is_required">Required</label>
                </div>`,
            onSubmit: async (f) => {
                const data = formData(f);
                data.field_options = data.field_type === 'select'
                    ? data.field_options.split(',').map((o) => o.trim()).filter(Boolean)
                    : null;
                await api(`/events/${event.event_id}/fields`, { method: 'POST', body: data });
                toast('Field added.');
                reload();
            },
        });
        form.querySelector('#field_type').addEventListener('change', (e) => {
            form.querySelector('#options-group').classList.toggle('d-none', e.target.value !== 'select');
        });
    });

    el.querySelectorAll('[data-delete]').forEach((btn) => btn.addEventListener('click', async () => {
        const field = event.custom_fields.find((f) => String(f.field_id) === btn.dataset.delete);
        const ok = await confirmDialog({
            title: 'Delete field',
            message: `Delete the <strong>${esc(field.field_label)}</strong> field? Answers already submitted will no longer be shown.`,
            confirmLabel: 'Delete',
            confirmClass: 'btn-danger',
        });
        if (!ok) return;
        try {
            await api(`/events/${event.event_id}/fields/${field.field_id}`, { method: 'DELETE' });
            toast('Field deleted.');
            reload();
        } catch (err) {
            toastError(err);
        }
    }));
}

async function renderRegistrations(el, event) {
    let { registrations } = await api(`/events/${event.event_id}/registrations`);

    const totalSessions = event.sessions.length;
    let search = '';


    el.innerHTML = `
        <div class="card">
            <div class="card-header bg-white py-3 d-flex flex-wrap gap-2 align-items-center">
                <input type="search" class="form-control form-control-sm" style="max-width:280px" placeholder="Search name, email, chapter…" id="reg-search">
                <span class="ms-auto small text-muted" id="reg-count"></span>
            </div>
            <div id="reg-table"></div>
        </div>`;

    const draw = () => {
        const rows = registrations.filter((r) => [r.first_name, r.last_name, r.email, r.chapter_region, r.designation, r.nickname, r.contact_number, r.flight_arrival, r.flight_departure, r.food_allergies]
                .join(' ').toLowerCase().includes(search));
        const count = el.querySelector('#reg-count');
        if (!count || !el.isConnected) return;
        count.textContent = `${rows.length} of ${registrations.length}`;
        const table = document.getElementById('reg-table');

        if (!rows.length) {
            table.innerHTML = emptyState('people', registrations.length ? 'No registrations match your filters' : 'No registrations yet',
                registrations.length ? '' : 'Registrations will appear here once members sign up.');
            return;
        }

        table.innerHTML = `
            <div class="table-responsive">
                <table class="table table-hover align-middle mb-0">
                    <thead><tr>
                        <th>Attendee</th><th>Chapter</th>
                        ${event.custom_fields.map((f) => `<th>${esc(f.field_label)}</th>`).join('')}
                        <th class="text-center">Sessions</th><th>Registered</th>
                    </tr></thead>
                    <tbody>
                        ${rows.map((r) => {
                            const responses = JSON.parse(r.custom_responses || '{}');
                            return `<tr>
                                <td><div class="fw-semibold">${isAdmin()
                                    ? `<a class="text-decoration-none" href="#/members/${r.member_id}">${esc(r.last_name)}, ${esc(r.first_name)}</a>`
                                    : `${esc(r.last_name)}, ${esc(r.first_name)}`}</div><div class="small text-muted">${esc(r.email)}</div></td>
                                <td class="small">${esc(r.chapter_region) || '<span class="text-muted">—</span>'}</td>
                                ${event.custom_fields.map((f) => {
                                    const value = responses[f.field_id];
                                    const shown = typeof value === 'boolean' ? (value ? 'Yes' : 'No') : value;
                                    return `<td class="small">${shown === undefined || shown === '' ? '<span class="text-muted">—</span>' : esc(shown)}</td>`;
                                }).join('')}
                                <td class="text-center">${r.sessions_attended} / ${totalSessions}</td>
                                <td class="small text-nowrap">${formatDateTime(r.registration_date)}</td>

                            </tr>`;
                        }).join('')}
                    </tbody>
                </table>
            </div>`;


    };

    el.querySelector('#reg-search')?.addEventListener('input', (e) => { search = e.target.value.trim().toLowerCase(); draw(); });
    draw();
}
