import { api } from '../../lib/api.js';
import { clearFormErrors, esc, formData, showFormErrors, toast, withBusy } from '../../lib/ui.js';
import { isAdmin, loadEvents } from '../state.js';

const TYPES = ['Convention', 'General Assembly', 'Seminar', 'Workshop', 'Field Demo'];

export async function renderEventForm(eventId = null) {
    const view = document.getElementById('view');
    if (!isAdmin()) {
        view.innerHTML = '<div class="alert alert-warning">Only administrators can create or edit events.</div>';
        return;
    }

    const event = eventId ? (await api(`/events/${eventId}`)).event : {};
    if (event.status === 'Archived') {
        view.innerHTML = `<div class="alert alert-warning">Archived events are locked. <a href="#/events/${eventId}">Back to event</a></div>`;
        return;
    }
    const v = (key, fallback = '') => esc(event[key] ?? fallback);
    const back = eventId ? `#/events/${eventId}` : '#/events';
    const fenceOn = Number(event.geofence_enabled) === 1;
    const radius = event.geofence_radius_m == null || event.geofence_radius_m === '' ? '200' : event.geofence_radius_m;

    view.innerHTML = `
        <nav aria-label="breadcrumb"><ol class="breadcrumb small mb-2">
            <li class="breadcrumb-item"><a href="#/events">Events</a></li>
            ${eventId ? `<li class="breadcrumb-item"><a href="${back}">${v('title')}</a></li>` : ''}
            <li class="breadcrumb-item active">${eventId ? 'Edit' : 'New event'}</li>
        </ol></nav>
        <h1 class="h3 page-title mb-4">${eventId ? 'Edit event' : 'Create a new event'}</h1>

        <form id="event-form" novalidate>
            <div class="row g-4">
                <div class="col-lg-8">
                    <div class="card mb-4">
                        <div class="card-header bg-white py-3"><h2 class="h6 mb-0 fw-semibold">Event details</h2></div>
                        <div class="card-body row g-3">
                            <div class="col-12">
                                <label class="form-label" for="title">Event title <span class="text-danger">*</span></label>
                                <input class="form-control" id="title" name="title" value="${v('title')}" maxlength="150" required
                                       placeholder="e.g. PAA National Convention 2026">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label" for="event_type">Event type <span class="text-danger">*</span></label>
                                <select class="form-select" id="event_type" name="event_type" required>
                                    ${TYPES.map((t) => `<option ${event.event_type === t ? 'selected' : ''}>${t}</option>`).join('')}
                                </select>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label" for="venue">Venue <span class="text-danger">*</span></label>
                                <input class="form-control" id="venue" name="venue" value="${v('venue')}" maxlength="255" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label" for="start_date">Start date <span class="text-danger">*</span></label>
                                <input class="form-control" type="date" id="start_date" name="start_date" value="${v('start_date')}" required>
                            </div>
                            <div class="col-md-6">
                                <label class="form-label" for="end_date">End date <span class="text-danger">*</span></label>
                                <input class="form-control" type="date" id="end_date" name="end_date" value="${v('end_date')}" required>
                            </div>
                            <div class="col-12">
                                <label class="form-label" for="description">Description</label>
                                <textarea class="form-control" id="description" name="description" rows="4">${v('description')}</textarea>
                            </div>
                        </div>
                    </div>
                    <div class="card mb-4">
                        <div class="card-header bg-white py-3"><h2 class="h6 mb-0 fw-semibold">Check-in location</h2></div>
                        <div class="card-body row g-3">
                            <div class="col-12">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="geofence_enabled" name="geofence_enabled" ${fenceOn ? 'checked' : ''}>
                                    <label class="form-check-label" for="geofence_enabled">Only accept scans inside a radius of the venue</label>
                                </div>
                                <div class="form-text">Phone location indoors is often 50–100 m off. About 200 m covers a venue without rejecting people at the door. Scanners must use the https address so the browser can read location.</div>
                            </div>
                            <div class="col-md-4">
                                <label class="form-label" for="geofence_latitude">Latitude</label>
                                <input class="form-control" id="geofence_latitude" name="geofence_latitude" inputmode="decimal" value="${v('geofence_latitude')}" placeholder="14.599512">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label" for="geofence_longitude">Longitude</label>
                                <input class="form-control" id="geofence_longitude" name="geofence_longitude" inputmode="decimal" value="${v('geofence_longitude')}" placeholder="120.984222">
                            </div>
                            <div class="col-md-4">
                                <label class="form-label" for="geofence_radius_m">Radius</label>
                                <div class="input-group">
                                    <input class="form-control" type="number" min="10" max="5000" step="1" id="geofence_radius_m" name="geofence_radius_m" value="${esc(radius)}">
                                    <span class="input-group-text">m</span>
                                </div>
                            </div>
                            <div class="col-12">
                                <button class="btn btn-outline-secondary btn-sm" type="button" id="use-location"><i class="bi bi-geo-alt me-1"></i>Use this device's location</button>
                            </div>
                        </div>
                    </div>
                </div>

                <div class="col-lg-4">
                    <div class="card mb-4">
                        <div class="card-header bg-white py-3"><h2 class="h6 mb-0 fw-semibold">Certificate &amp; PRC details</h2></div>
                        <div class="card-body row g-3">
                            <div class="col-12">
                                <label class="form-label" for="certificate_min_attendance_pct">Minimum attendance for certificate</label>
                                <div class="input-group">
                                    <input class="form-control" type="number" min="0" max="100" id="certificate_min_attendance_pct" name="certificate_min_attendance_pct" value="${v('certificate_min_attendance_pct', '80')}">
                                    <span class="input-group-text">% of sessions</span>
                                </div>
                            </div>
                            <div class="col-12">
                                <label class="form-label" for="prc_accreditation_no">PRC accreditation no.</label>
                                <input class="form-control" id="prc_accreditation_no" name="prc_accreditation_no" value="${v('prc_accreditation_no')}" maxlength="100">
                            </div>
                        </div>
                    </div>
                    <div class="card mb-4">
                        <div class="card-header bg-white py-3"><h2 class="h6 mb-0 fw-semibold">Certificate signatory 1</h2></div>
                        <div class="card-body row g-3">
                            <div class="col-12">
                                <label class="form-label" for="cert_signatory_name">Name</label>
                                <input class="form-control" id="cert_signatory_name" name="cert_signatory_name" value="${v('cert_signatory_name')}" maxlength="100"
                                       placeholder="e.g. Dr. Ramon C. Bautista">
                            </div>
                            <div class="col-12">
                                <label class="form-label" for="cert_signatory_title">Position</label>
                                <input class="form-control" id="cert_signatory_title" name="cert_signatory_title" value="${v('cert_signatory_title')}" maxlength="150"
                                       placeholder="e.g. National President, PAA">
                            </div>
                            <div class="col-12"><label class="form-label" for="cert_signatory_2_name">Second signatory name</label>
                                <input class="form-control" id="cert_signatory_2_name" name="cert_signatory_2_name" value="${v('cert_signatory_2_name')}" maxlength="100"></div>
                            <div class="col-12"><label class="form-label" for="cert_signatory_2_title">Second signatory position</label>
                                <input class="form-control" id="cert_signatory_2_title" name="cert_signatory_2_title" value="${v('cert_signatory_2_title')}" maxlength="150"></div>
                            <div class="col-12 form-text mt-2">Printed on attendance certificates. Upload the two signature images from the event's Certificates tab.</div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="d-flex gap-2 justify-content-end border-top pt-3">
                <a class="btn btn-light" href="${back}">Cancel</a>
                <button class="btn btn-primary px-4" type="submit">${eventId ? 'Save changes' : 'Create event'}</button>
            </div>
        </form>`;

    const form = document.getElementById('event-form');
    document.getElementById('use-location').addEventListener('click', () => {
        if (!navigator.geolocation || !window.isSecureContext) {
            toast('Location needs a secure page (https or localhost) and a browser that can read it.', 'warning');
            return;
        }
        navigator.geolocation.getCurrentPosition((pos) => {
            form.geofence_latitude.value = pos.coords.latitude.toFixed(6);
            form.geofence_longitude.value = pos.coords.longitude.toFixed(6);
            toast('Venue location filled in from this device.');
        }, (err) => {
            toast(err.code === 1
                ? 'Location is blocked. Allow location for this site and try again.'
                : 'Could not read this device\'s location.', 'warning');
        }, { enableHighAccuracy: true, timeout: 12000, maximumAge: 0 });
    });
    form.addEventListener('submit', async (e) => {
        e.preventDefault();
        clearFormErrors(form);
        await withBusy(form.querySelector('[type=submit]'), async () => {
            try {
                const body = formData(form);
                const res = eventId
                    ? await api(`/events/${eventId}`, { method: 'PUT', body })
                    : await api('/events', { method: 'POST', body });
                await loadEvents();
                toast(eventId ? 'Event updated.' : 'Event created. Add sessions next.');
                location.hash = eventId ? `#/events/${eventId}` : `#/events/${res.event.event_id}/sessions`;
            } catch (err) {
                showFormErrors(form, err);
                form.querySelector('.is-invalid, .form-alert')?.scrollIntoView({ behavior: 'smooth', block: 'center' });
            }
        });
    });
}
