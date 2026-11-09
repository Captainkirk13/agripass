import { esc, formatDate, formatDateRange, formatDateTime, formatTime } from '../lib/ui.js';

const qrUrl = (token, extra = '') => `/api/passes/qr?token=${encodeURIComponent(token)}${extra}`;
export const passPageUrl = (token) => `/pass/?token=${encodeURIComponent(token)}`;

export function passCard(pass, token) {
    const checkedIn = pass.sessions.filter((s) => s.check_in_time).length;

    return `
        <div class="pass-card">
            <div class="pass-head d-flex gap-3 align-items-center">
                <img src="/assets/img/paa-logo-yellow.png" alt="">
                <div>
                    <div class="pass-event">${esc(pass.title)}</div>
                    <div class="small opacity-75">${esc(pass.venue)}</div>
                    <div class="small opacity-75">${formatDateRange(pass.start_date, pass.end_date)}</div>
                </div>
            </div>
            <div class="pass-qr">
                <img src="${qrUrl(token)}" alt="Your QR pass">
                <div class="small text-muted">Show this QR code at the entrance of every session.</div>
            </div>
            <div class="pass-divider"></div>
            <div class="pass-body">
                <div class="label">Attendee</div>
                <div class="pass-name mb-2">${esc(pass.first_name)} ${esc(pass.last_name)}</div>
                <div class="row g-2 mb-3 small">
                    ${pass.chapter_region ? `<div class="col-6"><div class="label">Chapter</div>${esc(pass.chapter_region)}</div>` : ''}
                    ${pass.prc_license_number ? `<div class="col-6"><div class="label">PRC license</div>${esc(pass.prc_license_number)}</div>` : ''}
                    ${Number(pass.cpd_units) > 0 ? `<div class="col-6"><div class="label">CPD units</div>${esc(Number(pass.cpd_units))}</div>` : ''}
                </div>
                ${pass.sessions.length ? `
                <div class="mt-3">
                    <div class="label mb-1">Sessions &middot; ${checkedIn} of ${pass.sessions.length} attended</div>
                    ${pass.sessions.map((s) => `
                    <div class="session-row small">
                        <i class="bi ${s.check_in_time ? 'bi-check-circle-fill' : 'bi-circle text-muted'}"></i>
                        <div class="flex-grow-1">
                            <div class="fw-semibold">${esc(s.session_name)}</div>
                            <div class="text-muted">${formatDate(s.session_date, { weekday: 'short', month: 'short', day: 'numeric' })},
                                ${formatTime(s.start_time)} – ${formatTime(s.end_time)}</div>
                        </div>
                        ${s.check_in_time ? `<span class="text-success text-nowrap">${formatDateTime(s.check_in_time)}</span>` : ''}
                    </div>`).join('')}
                </div>` : ''}
            </div>
        </div>`;
}

export function passActions(token, { showPassLink = false } = {}) {
    return `
        <div class="d-flex flex-wrap gap-2 justify-content-center mt-4 no-print">
            <a class="btn btn-primary" href="${qrUrl(token, '&format=png&download=1')}"><i class="bi bi-download me-1"></i>Download QR</a>
            ${showPassLink ? `<a class="btn btn-outline-primary" href="${passPageUrl(token)}"><i class="bi bi-ticket-perforated me-1"></i>Open my pass page</a>` : ''}
            <button class="btn btn-outline-primary" type="button" onclick="window.print()"><i class="bi bi-printer me-1"></i>Print</button>
        </div>`;
}
