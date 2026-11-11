-- Attendance certificates. Applied automatically on a fresh database;
-- for an existing one run: docker compose exec -T db sh -c 'mysql -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" "$MYSQL_DATABASE"' < database/schema/003_certificates.sql

-- Name and attendance are snapshotted at issuance so later profile or event edits
-- never change a certificate that has already been handed out.
CREATE TABLE certificates (
    certificate_id INT AUTO_INCREMENT PRIMARY KEY,
    registration_id INT NOT NULL,
    certificate_no VARCHAR(40) NOT NULL,
    verification_code CHAR(16) NOT NULL,
    attendee_name VARCHAR(120) NOT NULL,
    sessions_attended SMALLINT UNSIGNED NOT NULL,
    sessions_total SMALLINT UNSIGNED NOT NULL,
    issued_by INT NULL,
    issued_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    emailed_at DATETIME NULL,
    revoked_at DATETIME NULL,
    revoked_reason VARCHAR(255) NULL,
    FOREIGN KEY (registration_id) REFERENCES registrations(registration_id) ON DELETE CASCADE,
    FOREIGN KEY (issued_by) REFERENCES users(user_id) ON DELETE SET NULL,
    UNIQUE KEY unique_certificate_registration (registration_id),
    UNIQUE KEY unique_certificate_no (certificate_no),
    UNIQUE KEY unique_verification_code (verification_code)
) ENGINE=InnoDB;
