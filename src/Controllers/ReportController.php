<?php

declare(strict_types=1);

namespace AgriPass\Controllers;

use AgriPass\Core\AuditLog;
use AgriPass\Core\Auth;
use AgriPass\Core\Database;
use AgriPass\Core\Request;
use AgriPass\Core\Response;
use AgriPass\Services\CertificateService;
use AgriPass\Services\EventContext;
use AgriPass\Services\EventReport;
use AgriPass\Services\ReportPdf;
use AgriPass\Services\TableExport;

/** Event analytics and data exports. Admins only, since exports contain personal data. */
final class ReportController
{
    public static function show(Request $request): void
    {
        Auth::require(Auth::ADMINS);
        $event = EventContext::find($request->param('id'));
        Response::json(['report' => EventReport::build($event)]);
    }

    public static function pdf(Request $request): void
    {
        $user = Auth::require(Auth::ADMINS);
        $event = EventContext::find($request->param('id'));
        $pdf = ReportPdf::render($event, EventReport::build($event));
        AuditLog::record($user['user_id'], 'report.export', 'event', (int) $event['event_id'], ['format' => 'summary.pdf']);

        header('Content-Type: application/pdf');
        header('Content-Disposition: inline; filename="' . self::slug($event) . '-summary.pdf"');
        header('Content-Length: ' . strlen($pdf));
        header('Cache-Control: private, no-store');
        echo $pdf;
    }

    public static function attendanceCsv(Request $request): void
    {
        self::exportAttendance($request, TableExport::CSV);
    }

    public static function attendanceXlsx(Request $request): void
    {
        self::exportAttendance($request, TableExport::XLSX);
    }

    public static function checkinsCsv(Request $request): void
    {
        self::exportCheckins($request, TableExport::CSV);
    }

    public static function checkinsXlsx(Request $request): void
    {
        self::exportCheckins($request, TableExport::XLSX);
    }

    public static function membersCsv(Request $request): void
    {
        self::exportMembers($request, TableExport::CSV);
    }

    public static function membersXlsx(Request $request): void
    {
        self::exportMembers($request, TableExport::XLSX);
    }

    /** One row per registrant with per-session check-in times and certificate eligibility: the attendance export. */
    private static function exportAttendance(Request $request, string $format): void
    {
        $user = Auth::require(Auth::ADMINS);
        $event = EventContext::find($request->param('id'));
        $sessions = Database::all('SELECT session_id, session_name FROM event_sessions WHERE event_id = ? ORDER BY session_date, start_time', [$event['event_id']]);
        $fields = Database::all('SELECT field_id, field_label, field_type FROM event_custom_fields WHERE event_id = ? ORDER BY field_id', [$event['event_id']]);
        $eligibility = array_column(CertificateService::eligibility($event), null, 'registration_id');

        $registrants = Database::all(
            'SELECT r.registration_id, r.registration_date, r.custom_responses,
                    m.last_name, m.first_name, m.email, m.contact_number, m.designation, m.nickname, m.birthdate, m.flight_arrival, m.flight_departure, m.food_allergies, m.prc_license_number, m.chapter_region, m.membership_status
             FROM registrations r JOIN members m ON m.member_id = r.member_id
             WHERE r.event_id = ? ORDER BY m.last_name, m.first_name',
            [$event['event_id']],
        );
        $checkins = [];
        foreach (Database::all(
            'SELECT a.registration_id, a.session_id, a.check_in_time FROM attendances a
             JOIN event_sessions s ON s.session_id = a.session_id WHERE s.event_id = ?',
            [$event['event_id']],
        ) as $a) {
            $checkins[$a['registration_id']][$a['session_id']] = $a['check_in_time'];
        }

        $header = ['Last name', 'First name', 'Email', 'Contact number', 'Designation / position', 'Nickname', 'Birthdate', 'Flight arrival', 'Flight departure', 'Food allergies', 'PRC license no.', 'Chapter / region', 'PAA membership', 'Registered at'];
        foreach ($sessions as $s) {
            $header[] = "Check-in: {$s['session_name']}";
        }
        array_push($header, 'Sessions attended', 'Sessions total', 'Attendance %', 'Certificate eligible', 'Not eligible because', 'Certificate no.');
        foreach ($fields as $f) {
            $header[] = $f['field_label'];
        }

        $rows = array_map(static function (array $r) use ($sessions, $fields, $eligibility, $checkins, $event): array {
            $certificate = $eligibility[(int) $r['registration_id']];
            $answers = json_decode((string) $r['custom_responses'], true) ?: [];
            $hasCertificate = $certificate['certificate_id'] !== null && $certificate['revoked_at'] === null;
            $line = [$r['last_name'], $r['first_name'], $r['email'], $r['contact_number'], $r['designation'], $r['nickname'], $r['birthdate'], $r['flight_arrival'], $r['flight_departure'], $r['food_allergies'], $r['prc_license_number'], $r['chapter_region'], $r['membership_status'], $r['registration_date']];
            foreach ($sessions as $s) {
                $line[] = $checkins[$r['registration_id']][$s['session_id']] ?? '';
            }
            array_push($line, $certificate['sessions_attended'], $certificate['sessions_total'], $certificate['attendance_pct'], $certificate['eligible'] ? 'Yes' : 'No',
                $certificate['reason'], $hasCertificate ? $certificate['certificate_no'] : '');
            foreach ($fields as $f) {
                $value = $answers[(string) $f['field_id']] ?? '';
                $line[] = is_bool($value) ? ($value ? 'Yes' : 'No') : $value;
            }

            return $line;
        }, $registrants);

        TableExport::send($format, self::slug($event) . '-attendance', 'Attendance', $header, $rows);
        AuditLog::record($user['user_id'], 'report.export', 'event', (int) $event['event_id'], ['format' => "attendance.{$format}", 'rows' => count($rows)]);
    }

    /** Raw scan log, one row per check-in, for audits of when and how attendance was recorded. */
    private static function exportCheckins(Request $request, string $format): void
    {
        $user = Auth::require(Auth::ADMINS);
        $event = EventContext::find($request->param('id'));
        $rows = Database::all(
            'SELECT s.session_name, s.session_date, m.last_name, m.first_name, m.prc_license_number, a.check_in_time,
                    a.scan_latitude, a.scan_longitude,
                    u.full_name AS scanned_by, IF(a.is_offline_sync, "Yes", "No") AS offline, a.synced_at, a.device_id
             FROM attendances a
             JOIN event_sessions s ON s.session_id = a.session_id
             JOIN registrations r ON r.registration_id = a.registration_id
             JOIN members m ON m.member_id = r.member_id
             LEFT JOIN users u ON u.user_id = a.scanned_by
             WHERE s.event_id = ? ORDER BY a.check_in_time, a.attendance_id',
            [$event['event_id']],
        );

        TableExport::send($format, self::slug($event) . '-checkins', 'Check-ins',
            ['Session', 'Session date', 'Last name', 'First name', 'PRC license no.', 'Checked in at', 'Scan latitude', 'Scan longitude', 'Scanned by', 'Recorded offline', 'Synced at', 'Device'],
            array_map('array_values', $rows));
        AuditLog::record($user['user_id'], 'report.export', 'event', (int) $event['event_id'], ['format' => "checkins.{$format}", 'rows' => count($rows)]);
    }

    private static function exportMembers(Request $request, string $format): void
    {
        $user = Auth::require(Auth::ADMINS);
        $rows = Database::all(
            'SELECT m.last_name, m.first_name, m.email, m.contact_number, m.designation, m.nickname, m.birthdate, m.flight_arrival, m.flight_departure, m.food_allergies, m.prc_license_number, m.chapter_region,
                    m.membership_status, m.created_at,
                    (SELECT COUNT(*) FROM registrations r WHERE r.member_id = m.member_id) AS events
             FROM members m ORDER BY m.last_name, m.first_name',
        );

        TableExport::send($format, 'agripass-members-' . date('Y-m-d'), 'Members',
            ['Last name', 'First name', 'Email', 'Contact number', 'Designation / position', 'Nickname', 'Birthdate', 'Flight arrival', 'Flight departure', 'Food allergies', 'PRC license no.', 'Chapter / region', 'PAA membership',
             'First registered', 'Events registered'],
            array_map('array_values', $rows));
        AuditLog::record($user['user_id'], 'report.export', 'member', null, ['format' => "members.{$format}", 'rows' => count($rows)]);
    }

    private static function slug(array $event): string
    {
        return trim((string) preg_replace('/[^a-z0-9]+/', '-', strtolower($event['title'])), '-') ?: 'event-' . $event['event_id'];
    }
}
