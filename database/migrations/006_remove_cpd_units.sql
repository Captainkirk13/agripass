-- Remove certificate unit values; eligibility now uses session attendance only.
-- Back up the database before applying this migration.
SET @has_old_threshold = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'cpd_min_attendance_pct'
);
SET @ddl = IF(@has_old_threshold > 0,
    'ALTER TABLE events CHANGE COLUMN cpd_min_attendance_pct certificate_min_attendance_pct TINYINT UNSIGNED DEFAULT 80',
    'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_event_units = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'cpd_units'
);
SET @ddl = IF(@has_event_units > 0, 'ALTER TABLE events DROP COLUMN cpd_units', 'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_certificate_units = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'certificates' AND COLUMN_NAME = 'cpd_units'
);
SET @ddl = IF(@has_certificate_units > 0, 'ALTER TABLE certificates DROP COLUMN cpd_units', 'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
