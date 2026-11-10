-- Optional venue radius for QR check-in. Scans outside the circle are rejected.
-- Back up the database before applying this migration.
SET @has_enabled = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'geofence_enabled'
);
SET @ddl = IF(@has_enabled = 0,
    'ALTER TABLE events
        ADD COLUMN geofence_enabled TINYINT(1) NOT NULL DEFAULT 0 AFTER certificate_min_attendance_pct,
        ADD COLUMN geofence_latitude DECIMAL(9,6) NULL AFTER geofence_enabled,
        ADD COLUMN geofence_longitude DECIMAL(9,6) NULL AFTER geofence_latitude,
        ADD COLUMN geofence_radius_m SMALLINT UNSIGNED NULL AFTER geofence_longitude',
    'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_scan_lat = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'attendances' AND COLUMN_NAME = 'scan_latitude'
);
SET @ddl = IF(@has_scan_lat = 0,
    'ALTER TABLE attendances
        ADD COLUMN scan_latitude DECIMAL(9,6) NULL AFTER check_in_time,
        ADD COLUMN scan_longitude DECIMAL(9,6) NULL AFTER scan_latitude',
    'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
