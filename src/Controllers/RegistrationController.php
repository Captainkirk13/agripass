<?php

declare(strict_types=1);

namespace AgriPass\Controllers;

use AgriPass\Core\AuditLog;
use AgriPass\Core\Auth;
use AgriPass\Core\Database;
use AgriPass\Core\HttpException;
use AgriPass\Core\Request;
use AgriPass\Core\Response;
use AgriPass\Core\RateLimiter;
use AgriPass\Services\EventContext;
use AgriPass\Services\PassMailer;
use AgriPass\Services\QrToken;

final class RegistrationController
{
    /** Public registration for an open event. Existing members (matched by email) are reused. */
    public static function store(Request $request): void
    {
        $event = EventContext::find($request->param('id'));
        if ($event['status'] !== 'Active') {
            throw new HttpException(409, 'Registration is not open for this event.');
        }

        $data = $request->validate([
            'first_name' => 'required',
            'last_name' => 'required',
            'email' => 'required',
            'contact_number' => 'optional',
            'chapter_region' => 'optional',
            'designation' => 'optional',
            'nickname' => 'optional',
            'birthdate' => 'optional',
            'flight_arrival' => 'optional',
            'flight_departure' => 'optional',
            'food_allergies' => 'optional',
        ]);
        $errors = [];
        if (!filter_var($data['email'], FILTER_VALIDATE_EMAIL)) {
            $errors['email'] = 'Must be a valid email address.';
        }
        if ($data['birthdate'] !== null && $data['birthdate'] !== '') {
            $date = \DateTime::createFromFormat('!Y-m-d', (string) $data['birthdate']);
            if ($date === false || $date->format('Y-m-d') !== $data['birthdate']) {
                $errors['birthdate'] = 'Enter a valid date in YYYY-MM-DD format.';
            }
        }
        foreach (['designation' => 100, 'nickname' => 50, 'flight_arrival' => 100, 'flight_departure' => 100, 'food_allergies' => 1000] as $field => $max) {
            if ($data[$field] !== null && mb_strlen((string) $data[$field]) > $max) {
                $errors[$field] = "Use {$max} characters or fewer.";
            }
        }
        if ($request->input('privacy_consent') !== true) {
            $errors['privacy_consent'] = 'You must agree to the data privacy notice to register.';
        }
        if ($errors) {
            throw new HttpException(422, 'Validation failed.', $errors);
        }
        $data['email'] = strtolower((string) $data['email']);
        $responses = self::validatedResponses((int) $event['event_id'], $request->input('custom_responses', []));

        $pdo = Database::pdo();
        $pdo->beginTransaction();
        try {
            $memberId = self::upsertMember($data);

            if (Database::one('SELECT 1 FROM registrations WHERE event_id = ? AND member_id = ?', [$event['event_id'], $memberId])) {
                throw new HttpException(409, 'This email is already registered for this event.');
            }

            $registrationId = Database::insert(
                'INSERT INTO registrations (event_id, member_id, qr_token, custom_responses) VALUES (?, ?, ?, ?)',
                [$event['event_id'], $memberId, 'pending:' . bin2hex(random_bytes(16)), json_encode((object) $responses)],
            );
            $token = QrToken::make((int) $event['event_id'], $registrationId);
            Database::run('UPDATE registrations SET qr_token = ? WHERE registration_id = ?', [$token, $registrationId]);
            $pdo->commit();
        } catch (\Throwable $e) {
            $pdo->rollBack();
            throw $e;
        }

        $member = Database::one('SELECT * FROM members WHERE member_id = ?', [$memberId]);
        $emailed = PassMailer::send($event, $member, $token);

        AuditLog::record(null, 'registration.create', 'registration', $registrationId, ['event_id' => (int) $event['event_id'], 'emailed' => $emailed]);
        Response::json(['registration' => [
            'registration_id' => $registrationId,
            'event_id' => (int) $event['event_id'],
            'qr_token' => $token,
            'email' => $member['email'],
            'emailed' => $emailed,
        ]], 201);
    }

    /** Re-sends an existing pass. Unknown addresses get the same reply; a mail failure is reported so it can be retried. */
    public static function resend(Request $request): void
    {
        RateLimiter::assertUnder('registration.resend', 5, 15);
        $event = EventContext::find($request->param('id'));
        $email = strtolower((string) $request->validate(['email' => 'required'])['email']);

        $row = Database::one(
            'SELECT r.qr_token, m.* FROM registrations r JOIN members m ON m.member_id = r.member_id
             WHERE r.event_id = ? AND m.email = ?',
            [$event['event_id'], $email],
        );
        $sent = $row === null || PassMailer::send($event, $row, $row['qr_token']);
        AuditLog::record(null, 'registration.resend', 'event', (int) $event['event_id']);
        if (!$sent) {
            throw new HttpException(502, 'The email could not be sent. Please try again in a few minutes.');
        }

        Response::json(['message' => 'If this email is registered for the event, the pass has been sent to it.']);
    }

    public static function index(Request $request): void
    {
        Auth::require();
        $event = EventContext::find($request->param('id'));
        Response::json(['registrations' => Database::all(
            'SELECT r.registration_id, r.custom_responses, r.registration_date,
                    m.member_id, m.first_name, m.last_name, m.email, m.chapter_region, m.contact_number,
                    m.designation, m.nickname, m.birthdate, m.flight_arrival, m.flight_departure, m.food_allergies,
                    (SELECT COUNT(*) FROM attendances a WHERE a.registration_id = r.registration_id) AS sessions_attended
             FROM registrations r JOIN members m ON m.member_id = r.member_id
             WHERE r.event_id = ? ORDER BY m.last_name, m.first_name',
            [$event['event_id']],
        )]);
    }

    private static function upsertMember(array $data): int
    {
        $existing = Database::one('SELECT member_id FROM members WHERE email = ?', [$data['email']]);
        if ($existing === null) {
            return Database::insert(
                'INSERT INTO members (first_name, last_name, email, contact_number, chapter_region, designation, nickname, birthdate, flight_arrival, flight_departure, food_allergies)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
                [$data['first_name'], $data['last_name'], $data['email'], $data['contact_number'], $data['chapter_region'], $data['designation'], $data['nickname'], $data['birthdate'], $data['flight_arrival'], $data['flight_departure'], $data['food_allergies']],
            );
        }
        Database::run(
            'UPDATE members SET contact_number = COALESCE(contact_number, ?),
                                chapter_region = COALESCE(chapter_region, ?), designation = COALESCE(designation, ?), nickname = COALESCE(nickname, ?),
                                birthdate = COALESCE(birthdate, ?), flight_arrival = COALESCE(flight_arrival, ?), flight_departure = COALESCE(flight_departure, ?),
                                food_allergies = COALESCE(food_allergies, ?) WHERE member_id = ?',
            [$data['contact_number'], $data['chapter_region'], $data['designation'], $data['nickname'], $data['birthdate'], $data['flight_arrival'], $data['flight_departure'], $data['food_allergies'], $existing['member_id']],
        );
        return (int) $existing['member_id'];
    }

    private static function validatedResponses(int $eventId, mixed $input): array
    {
        if (!is_array($input)) {
            throw new HttpException(422, 'Validation failed.', ['custom_responses' => 'Must be an object keyed by field_id.']);
        }

        $responses = [];
        $errors = [];
        foreach (Database::all('SELECT * FROM event_custom_fields WHERE event_id = ?', [$eventId]) as $field) {
            $id = (string) $field['field_id'];
            $value = $input[$id] ?? null;
            if (is_string($value)) {
                $value = trim($value);
            }
            if ($value === null || $value === '') {
                if ($field['is_required'] && $field['field_type'] !== 'checkbox') {
                    $errors[$id] = "{$field['field_label']} is required.";
                }
                continue;
            }

            $valid = match ($field['field_type']) {
                'number' => is_numeric($value),
                'checkbox' => is_bool($value),
                'select' => in_array($value, json_decode((string) $field['field_options'], true) ?? [], true),
                default => is_string($value) && mb_strlen($value) <= 500,
            };
            if (!$valid) {
                $errors[$id] = "Invalid value for {$field['field_label']}.";
                continue;
            }
            $responses[$id] = $field['field_type'] === 'number' ? $value + 0 : $value;
        }
        if ($errors) {
            throw new HttpException(422, 'Validation failed.', ['custom_responses' => $errors]);
        }

        return $responses;
    }
}
