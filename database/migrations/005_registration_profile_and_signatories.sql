-- Additional registration/member profile fields and dual certificate signatories.
-- Legacy payment and PAA ID data is removed in the final ALTER statements.
ALTER TABLE members
    ADD COLUMN designation VARCHAR(100) NULL AFTER contact_number,
    ADD COLUMN nickname VARCHAR(50) NULL AFTER designation,
    ADD COLUMN birthdate DATE NULL AFTER nickname,
    ADD COLUMN flight_arrival VARCHAR(100) NULL AFTER birthdate,
    ADD COLUMN flight_departure VARCHAR(100) NULL AFTER flight_arrival,
    ADD COLUMN food_allergies TEXT NULL AFTER flight_departure;

ALTER TABLE events
    ADD COLUMN cert_signatory_2_name VARCHAR(100) NULL AFTER cert_signatory_title,
    ADD COLUMN cert_signatory_2_title VARCHAR(150) NULL AFTER cert_signatory_2_name,
    ADD COLUMN cert_signature_2_path VARCHAR(255) NULL AFTER cert_signature_path;

-- Remove legacy fields and data not used by this system anymore.
ALTER TABLE members DROP COLUMN paa_id_number;
ALTER TABLE events DROP COLUMN registration_fee;
ALTER TABLE registrations DROP COLUMN payment_status, DROP COLUMN payment_reference, DROP COLUMN amount_paid;
