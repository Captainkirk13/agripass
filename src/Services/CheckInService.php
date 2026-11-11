<?php

declare(strict_types=1);

namespace AgriPass\Services;

use AgriPass\Core\Database;
use PDOException;

final class CheckInService
{
    public const VALID = 'valid';
    public const INVALID = 'invalid';
    public const WRONG_EVENT = 'wrong_event';
    public const DUPLICATE = 'duplicate';
    public const ALREADY_SYNCED = 'already_synced';
    public const OUTSIDE = 'outside_fence';

    /**
     * @param array $session row from event_sessions; must belong to the scanner's event context
     * @param array $event event row, including geofence columns when the radius option is on
     */
    public static function checkIn(
        string $qrToken,
        array $session,
        ?int $scannedBy,
        ?string $deviceId = null,
        ?string $clientUuid = null,
        ?string $checkInTime = null,
        bool $offline = false,
        array $event = [],
        ?float $latitude = null,
        ?float $longitude = null,
    ): array {
        if ($clientUuid !== null) {
            $existing = Database::one('SELECT attendance_id, check_in_time FROM attendances WHERE client_uuid = ?', [$clientUuid]);
            if ($existing !== null) {
                return ['result' => self::ALREADY_SYNCED, 'check_in_time' => $existing['check_in_time']];
            }
        }

        $parsed = QrToken::parse($qrToken);
        if ($parsed === null) {
            return ['result' => self::INVALID, 'message' => 'Unrecognized or tampered QR pass.'];
        }
        if ($parsed['event_id'] !== (int) $session['event_id']) {
            return ['result' => self::WRONG_EVENT, 'message' => 'This pass is for a different event.'];
        }

        $registration = Database::one(
            'SELECT r.registration_id, r.event_id, r.qr_token,
                    m.member_id, m.first_name, m.last_name, m.chapter_region
             FROM registrations r JOIN members m ON m.member_id = r.member_id
             WHERE r.registration_id = ? AND r.qr_token = ?',
            [$parsed['registration_id'], $qrToken],
        );
        if ($registration === null) {
            return ['result' => self::INVALID, 'message' => 'Registration not found.'];
        }

        $attendee = [
            'registration_id' => (int) $registration['registration_id'],
            'name' => $registration['first_name'] . ' ' . $registration['last_name'],
            'chapter_region' => $registration['chapter_region'],
        ];

        $blocked = self::outsideVenue($event, $latitude, $longitude);
        if ($blocked !== null) {
            return $blocked;
        }

        $duplicate = self::existingAttendance($attendee['registration_id'], (int) $session['session_id']);
        if ($duplicate !== null) {
            return [
                'result' => self::DUPLICATE,
                'message' => 'Already Checked In for this Session.',
                'check_in_time' => $duplicate['check_in_time'],
                'attendee' => $attendee,
            ];
        }

        $time = $checkInTime !== null ? date('Y-m-d H:i:s', strtotime($checkInTime)) : date('Y-m-d H:i:s');

        try {
            Database::run(
                'INSERT INTO attendances (registration_id, session_id, scanned_by, device_id, client_uuid, check_in_time, scan_latitude, scan_longitude, is_offline_sync)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [$attendee['registration_id'], $session['session_id'], $scannedBy, $deviceId, $clientUuid, $time, $latitude, $longitude, $offline ? 1 : 0],
            );
        } catch (PDOException $e) {
            if ($e->getCode() !== '23000') {
                throw $e;
            }
            $duplicate = self::existingAttendance($attendee['registration_id'], (int) $session['session_id']);

            return [
                'result' => self::DUPLICATE,
                'message' => 'Already Checked In for this Session.',
                'check_in_time' => $duplicate['check_in_time'] ?? null,
                'attendee' => $attendee,
            ];
        }

        return ['result' => self::VALID, 'message' => 'Welcome!', 'check_in_time' => $time, 'attendee' => $attendee];
    }

    /** Rejects the scan when the event requires the device to be inside the venue radius. */
    private static function outsideVenue(array $event, ?float $latitude, ?float $longitude): ?array
    {
        if (!(int) ($event['geofence_enabled'] ?? 0)) {
            return null;
        }
        $centerLat = $event['geofence_latitude'] ?? null;
        $centerLng = $event['geofence_longitude'] ?? null;
        $radius = $event['geofence_radius_m'] ?? null;
        if ($centerLat === null || $centerLng === null || $radius === null) {
            return [
                'result' => self::OUTSIDE,
                'message' => 'Venue radius is turned on, but the event location is incomplete. An admin needs to set it before scanning.',
            ];
        }
        if ($latitude === null || $longitude === null) {
            return [
                'result' => self::OUTSIDE,
                'message' => 'Location is required. Allow location access and scan again inside the venue.',
            ];
        }

        $away = GeoFence::meters((float) $centerLat, (float) $centerLng, $latitude, $longitude);
        if ($away > (float) $radius) {
            return [
                'result' => self::OUTSIDE,
                'message' => 'Outside the venue. This scan is about ' . (int) round($away) . ' m away, and only scans within ' . (int) $radius . ' m are accepted.',
            ];
        }

        return null;
    }

    private static function existingAttendance(int $registrationId, int $sessionId): ?array
    {
        return Database::one(
            'SELECT attendance_id, check_in_time FROM attendances WHERE registration_id = ? AND session_id = ?',
            [$registrationId, $sessionId],
        );
    }
}
