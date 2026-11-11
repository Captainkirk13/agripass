-- PRC accreditation and license numbers are no longer collected.
-- Back up the database before applying this migration.
SET @has_member_license = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'members' AND COLUMN_NAME = 'prc_license_number'
);
SET @ddl = IF(@has_member_license = 1, 'ALTER TABLE members DROP COLUMN prc_license_number', 'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_certificate_license = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'certificates' AND COLUMN_NAME = 'prc_license_number'
);
SET @ddl = IF(@has_certificate_license = 1, 'ALTER TABLE certificates DROP COLUMN prc_license_number', 'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;

SET @has_accreditation = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'events' AND COLUMN_NAME = 'prc_accreditation_no'
);
SET @ddl = IF(@has_accreditation = 1, 'ALTER TABLE events DROP COLUMN prc_accreditation_no', 'SELECT 1');
PREPARE stmt FROM @ddl; EXECUTE stmt; DEALLOCATE PREPARE stmt;
