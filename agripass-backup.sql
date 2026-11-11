-- MySQL dump 10.13  Distrib 8.4.13, for Linux (x86_64)
--
-- Host: localhost    Database: agripass
-- ------------------------------------------------------
-- Server version	8.4.13

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `attendances`
--

DROP TABLE IF EXISTS `attendances`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `attendances` (
  `attendance_id` int NOT NULL AUTO_INCREMENT,
  `registration_id` int NOT NULL,
  `session_id` int NOT NULL,
  `scanned_by` int DEFAULT NULL,
  `device_id` varchar(64) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `client_uuid` char(36) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `check_in_time` datetime NOT NULL,
  `scan_latitude` decimal(9,6) DEFAULT NULL,
  `scan_longitude` decimal(9,6) DEFAULT NULL,
  `is_offline_sync` tinyint(1) DEFAULT '0',
  `synced_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`attendance_id`),
  UNIQUE KEY `unique_registration_session` (`registration_id`,`session_id`),
  UNIQUE KEY `unique_client_uuid` (`client_uuid`),
  KEY `session_id` (`session_id`),
  KEY `scanned_by` (`scanned_by`),
  CONSTRAINT `attendances_ibfk_1` FOREIGN KEY (`registration_id`) REFERENCES `registrations` (`registration_id`) ON DELETE CASCADE,
  CONSTRAINT `attendances_ibfk_2` FOREIGN KEY (`session_id`) REFERENCES `event_sessions` (`session_id`) ON DELETE CASCADE,
  CONSTRAINT `attendances_ibfk_3` FOREIGN KEY (`scanned_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `attendances`
--

LOCK TABLES `attendances` WRITE;
/*!40000 ALTER TABLE `attendances` DISABLE KEYS */;
INSERT INTO `attendances` VALUES (1,1,1,1,NULL,NULL,'2026-09-15 07:30:00',NULL,NULL,0,'2026-10-31 14:45:37'),(2,1,2,1,NULL,NULL,'2026-09-15 12:46:00',NULL,NULL,0,'2026-10-31 14:45:37'),(3,1,3,1,NULL,NULL,'2026-09-16 07:55:00',NULL,NULL,0,'2026-10-31 14:45:37'),(4,1,4,1,NULL,NULL,'2026-09-16 13:07:00',NULL,NULL,0,'2026-10-31 14:45:37'),(5,2,1,1,NULL,NULL,'2026-09-15 08:05:00',NULL,NULL,0,'2026-10-31 14:45:37'),(6,2,2,1,NULL,NULL,'2026-09-15 13:11:00',NULL,NULL,0,'2026-10-31 14:45:37'),(7,2,3,1,NULL,NULL,'2026-09-16 09:00:00',NULL,NULL,0,'2026-10-31 14:45:37'),(8,3,1,1,NULL,NULL,'2026-09-15 08:09:00',NULL,NULL,0,'2026-10-31 14:45:37'),(9,3,2,1,NULL,NULL,'2026-09-15 12:39:00',NULL,NULL,0,'2026-10-31 14:45:37'),(10,4,1,1,NULL,NULL,'2026-09-15 07:46:00',NULL,NULL,0,'2026-10-31 14:45:37'),(11,4,2,1,NULL,NULL,'2026-09-15 13:58:00',NULL,NULL,0,'2026-10-31 14:45:37'),(12,4,3,1,NULL,NULL,'2026-09-16 08:44:00',NULL,NULL,0,'2026-10-31 14:45:37'),(13,4,4,1,NULL,NULL,'2026-09-16 14:09:00',NULL,NULL,0,'2026-10-31 14:45:37'),(15,9,11,1,'scanner-52c84745','429c3622-922a-4775-b083-231122a06edf','2026-11-11 18:44:23',14.198700,121.156500,0,'2026-11-11 10:44:23'),(16,10,11,1,'scanner-52c84745','426c5a1d-9550-4d99-9619-7de2549a8e9a','2026-11-11 23:48:10',NULL,NULL,0,'2026-11-11 15:48:10'),(17,11,11,1,'scanner-52c84745','6fab4ca4-04d9-43ff-b7ce-258e782abe61','2026-11-11 23:54:41',NULL,NULL,1,'2026-11-11 15:55:12');
/*!40000 ALTER TABLE `attendances` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `certificates`
--

DROP TABLE IF EXISTS `certificates`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `certificates` (
  `certificate_id` int NOT NULL AUTO_INCREMENT,
  `registration_id` int NOT NULL,
  `certificate_no` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `verification_code` char(16) COLLATE utf8mb4_unicode_ci NOT NULL,
  `attendee_name` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `prc_license_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sessions_attended` smallint unsigned NOT NULL,
  `sessions_total` smallint unsigned NOT NULL,
  `issued_by` int DEFAULT NULL,
  `issued_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `emailed_at` datetime DEFAULT NULL,
  `revoked_at` datetime DEFAULT NULL,
  `revoked_reason` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`certificate_id`),
  UNIQUE KEY `unique_certificate_registration` (`registration_id`),
  UNIQUE KEY `unique_certificate_no` (`certificate_no`),
  UNIQUE KEY `unique_verification_code` (`verification_code`),
  KEY `issued_by` (`issued_by`),
  CONSTRAINT `certificates_ibfk_1` FOREIGN KEY (`registration_id`) REFERENCES `registrations` (`registration_id`) ON DELETE CASCADE,
  CONSTRAINT `certificates_ibfk_2` FOREIGN KEY (`issued_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `certificates`
--

LOCK TABLES `certificates` WRITE;
/*!40000 ALTER TABLE `certificates` DISABLE KEYS */;
/*!40000 ALTER TABLE `certificates` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_custom_fields`
--

DROP TABLE IF EXISTS `event_custom_fields`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event_custom_fields` (
  `field_id` int NOT NULL AUTO_INCREMENT,
  `event_id` int NOT NULL,
  `field_label` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `field_type` enum('text','number','select','checkbox') COLLATE utf8mb4_unicode_ci NOT NULL,
  `field_options` json DEFAULT NULL,
  `is_required` tinyint(1) DEFAULT '0',
  PRIMARY KEY (`field_id`),
  KEY `event_id` (`event_id`),
  CONSTRAINT `event_custom_fields_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`event_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_custom_fields`
--

LOCK TABLES `event_custom_fields` WRITE;
/*!40000 ALTER TABLE `event_custom_fields` DISABLE KEYS */;
INSERT INTO `event_custom_fields` VALUES (1,2,'T-Shirt Size','select','[\"XS\", \"S\", \"M\", \"L\", \"XL\", \"2XL\"]',1),(2,2,'Dietary Restrictions','text',NULL,0),(3,2,'School','text',NULL,1);
/*!40000 ALTER TABLE `event_custom_fields` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `event_sessions`
--

DROP TABLE IF EXISTS `event_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `event_sessions` (
  `session_id` int NOT NULL AUTO_INCREMENT,
  `event_id` int NOT NULL,
  `session_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `session_date` date NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  PRIMARY KEY (`session_id`),
  KEY `event_id` (`event_id`),
  CONSTRAINT `event_sessions_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`event_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=16 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `event_sessions`
--

LOCK TABLES `event_sessions` WRITE;
/*!40000 ALTER TABLE `event_sessions` DISABLE KEYS */;
INSERT INTO `event_sessions` VALUES (1,1,'Day 1 Opening Plenary','2026-09-15','08:00:00','12:00:00'),(2,1,'Day 1 Climate-Smart Farming Track','2026-09-15','13:00:00','17:00:00'),(3,1,'Day 2 Precision Agriculture Workshop','2026-09-16','08:00:00','12:00:00'),(4,1,'Day 2 Field Visit','2026-09-16','13:00:00','16:00:00'),(5,2,'Day 1 Morning Plenary','2026-11-18','08:00:00','12:00:00'),(6,2,'Day 1 Afternoon Technical Track','2026-11-18','13:00:00','17:00:00'),(7,2,'Day 2 Breakout Sessions','2026-11-19','08:00:00','12:00:00'),(8,2,'Day 2 Field Demonstration','2026-11-19','13:00:00','16:00:00'),(11,3,'Day 1','2026-11-20','13:00:00','18:00:00'),(14,3,'Day 2','2026-11-21','08:00:00','17:00:00'),(15,3,'Day 3','2026-11-22','09:00:00','12:00:00');
/*!40000 ALTER TABLE `event_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `events`
--

DROP TABLE IF EXISTS `events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `events` (
  `event_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_type` enum('Convention','General Assembly','Seminar','Workshop','Field Demo') COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `venue` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `certificate_min_attendance_pct` tinyint unsigned DEFAULT '80',
  `geofence_enabled` tinyint(1) NOT NULL DEFAULT '0',
  `geofence_latitude` decimal(9,6) DEFAULT NULL,
  `geofence_longitude` decimal(9,6) DEFAULT NULL,
  `geofence_radius_m` smallint unsigned DEFAULT NULL,
  `prc_accreditation_no` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cert_signatory_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cert_signatory_title` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cert_signatory_2_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cert_signatory_2_title` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cert_signature_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `cert_signature_2_path` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `is_active` tinyint(1) DEFAULT '0',
  `status` enum('Draft','Active','Completed','Archived') COLLATE utf8mb4_unicode_ci DEFAULT 'Draft',
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`event_id`),
  KEY `created_by` (`created_by`),
  CONSTRAINT `events_ibfk_1` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `events`
--

LOCK TABLES `events` WRITE;
/*!40000 ALTER TABLE `events` DISABLE KEYS */;
INSERT INTO `events` VALUES (1,'PAA Luzon Agri-Innovation Seminar 2026','Seminar','Two-day seminar on climate-smart farming and agri-technology.','University of the Philippines Los Baños, Laguna','2026-09-15','2026-09-16',75,0,NULL,NULL,NULL,'PRC-AIPO-2026-0412','Dr. Ramon C. Bautista','National President, Philippine Association of Agriculturists, Inc.',NULL,NULL,NULL,NULL,0,'Archived',1,'2026-10-31 14:45:37'),(2,'PAA National Convention 2026','Convention','Annual national convention of agriculturists.','Central Luzon State University, Science City of Muñoz, Nueva Ecija','2026-11-18','2026-11-19',80,0,NULL,NULL,NULL,'PRC-AIPO-2026-0001',NULL,NULL,NULL,NULL,NULL,NULL,0,'Archived',1,'2026-10-31 14:45:37'),(3,'STRATEGIC PLANNING WORKSHOP','Workshop','Annual national convention of agriculturists.','Golden Prince Hotel, Cebu City','2026-10-20','2026-11-22',50,0,14.198700,121.156500,300,'0','Dr. Roberto f. rañola, jr','Chairman, Philippine Association of Agriculturists, Inc.','Dr. Fernando c. sanchez, jr','National President, Philippine Association of Agriculturists, Inc.',NULL,NULL,1,'Active',1,'2026-11-03 03:22:58');
/*!40000 ALTER TABLE `events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `logs`
--

DROP TABLE IF EXISTS `logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `logs` (
  `log_id` bigint NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `action` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity_type` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `entity_id` int DEFAULT NULL,
  `details` json DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `user_id` (`user_id`),
  KEY `idx_logs_entity` (`entity_type`,`entity_id`),
  KEY `idx_logs_rate` (`action`,`ip_address`,`created_at`),
  CONSTRAINT `logs_ibfk_1` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL
) ENGINE=InnoDB AUTO_INCREMENT=143 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs`
--

LOCK TABLES `logs` WRITE;
/*!40000 ALTER TABLE `logs` DISABLE KEYS */;
INSERT INTO `logs` VALUES (1,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:07'),(2,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:15'),(3,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:21'),(4,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:28'),(5,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:39'),(6,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:44'),(7,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:45'),(8,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:34:51'),(9,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:35:08'),(10,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"admin@paa.local\"}','172.18.0.1','2026-10-31 14:35:18'),(11,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-10-31 14:49:21'),(12,1,'custom_field.create','event_custom_field',3,NULL,'172.18.0.1','2026-10-31 14:50:45'),(13,NULL,'registration.create','registration',5,'{\"emailed\": true, \"event_id\": 2}','172.18.0.1','2026-10-31 14:52:37'),(14,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-10-31 15:00:33'),(15,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-01 13:30:32'),(16,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-03 02:53:17'),(17,1,'event.create','event',3,NULL,'172.18.0.1','2026-11-03 03:22:58'),(18,1,'event.activate','event',3,NULL,'172.18.0.1','2026-11-03 03:24:06'),(19,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-03 03:24:41'),(20,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-03 03:27:02'),(21,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-05 06:45:18'),(22,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-05 06:50:06'),(23,NULL,'registration.create','registration',6,'{\"emailed\": true, \"event_id\": 3}','172.18.0.1','2026-11-05 06:52:57'),(24,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-05 06:54:10'),(25,NULL,'registration.create','registration',7,'{\"emailed\": true, \"event_id\": 3}','172.18.0.1','2026-11-07 10:36:43'),(26,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-07 10:38:27'),(27,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-07 10:40:18'),(28,1,'event.update','event',2,NULL,'172.18.0.1','2026-11-07 10:41:39'),(29,NULL,'auth.login_failed',NULL,NULL,'{\"email\": \"kfgdrgiurgnrg\"}','172.18.0.1','2026-11-07 10:45:15'),(30,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-07 10:46:20'),(31,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-07 12:22:23'),(32,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-07 12:30:29'),(33,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-07 12:38:13'),(34,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-07 12:40:46'),(35,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-07 12:49:30'),(36,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-07 12:53:51'),(37,1,'report.export','event',3,'{\"format\": \"summary.pdf\"}','172.18.0.1','2026-11-07 12:54:14'),(38,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-07 13:10:51'),(39,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-07 13:11:20'),(40,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-09 12:30:05'),(41,1,'report.export','event',3,'{\"rows\": 2, \"format\": \"attendance.xlsx\"}','172.18.0.1','2026-11-09 12:50:37'),(42,1,'report.export','event',3,'{\"rows\": 2, \"format\": \"attendance.xlsx\"}','172.18.0.1','2026-11-09 12:50:37'),(43,1,'report.export','event',3,'{\"rows\": 2, \"format\": \"attendance.xlsx\"}','172.18.0.1','2026-11-09 12:50:37'),(44,1,'report.export','event',3,'{\"rows\": 2, \"format\": \"attendance.csv\"}','172.18.0.1','2026-11-09 12:50:37'),(45,1,'report.export','event',3,'{\"rows\": 2, \"format\": \"attendance.xlsx\"}','172.18.0.1','2026-11-09 12:50:37'),(46,1,'report.export','event',3,'{\"format\": \"summary.pdf\"}','172.18.0.1','2026-11-09 12:50:43'),(47,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-09 16:40:18'),(48,1,'event.status','event',1,'{\"to\": \"Archived\", \"from\": \"Completed\"}','172.18.0.1','2026-11-09 16:40:47'),(49,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-09 16:42:19'),(50,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:41:59'),(51,1,'user.create','user',2,'{\"role\": \"RegionalOfficer\"}','172.18.0.1','2026-11-10 05:42:26'),(52,1,'user.create','user',3,'{\"role\": \"Staff\"}','172.18.0.1','2026-11-10 05:44:20'),(53,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:44:58'),(54,2,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:45:41'),(55,2,'auth.password_changed','user',2,NULL,'172.18.0.1','2026-11-10 05:46:33'),(56,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:48:32'),(57,3,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:49:11'),(58,3,'auth.password_changed','user',3,NULL,'172.18.0.1','2026-11-10 05:50:03'),(59,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:51:22'),(60,2,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:51:48'),(61,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 05:52:10'),(62,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-10 06:21:40'),(63,NULL,'registration.resend','event',3,NULL,'172.18.0.1','2026-11-10 07:22:09'),(64,NULL,'registration.create','registration',8,'{\"emailed\": false, \"event_id\": 3}','172.18.0.1','2026-11-10 07:23:07'),(65,1,'event.status','event',2,'{\"to\": \"Completed\", \"from\": \"Active\"}','172.18.0.1','2026-11-10 07:24:52'),(66,1,'event.status','event',2,'{\"to\": \"Archived\", \"from\": \"Completed\"}','172.18.0.1','2026-11-10 07:24:54'),(67,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 04:43:12'),(68,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 04:45:41'),(69,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 04:46:56'),(70,1,'session.create','event_session',9,NULL,'172.18.0.1','2026-11-11 04:48:44'),(71,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 05:37:23'),(72,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 05:37:23'),(73,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 05:37:49'),(74,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 05:38:46'),(75,1,'member.update','member',2,'{\"changed\": [\"prc_license_number\"]}','172.18.0.1','2026-11-11 05:39:27'),(76,1,'session.delete','event_session',9,NULL,'172.18.0.1','2026-11-11 05:51:34'),(77,1,'session.create','event_session',10,NULL,'172.18.0.1','2026-11-11 05:51:41'),(78,1,'session.delete','event_session',10,NULL,'172.18.0.1','2026-11-11 05:51:48'),(79,1,'session.create','event_session',11,NULL,'172.18.0.1','2026-11-11 05:52:09'),(80,1,'session.create','event_session',12,NULL,'172.18.0.1','2026-11-11 05:52:27'),(81,1,'session.create','event_session',13,NULL,'172.18.0.1','2026-11-11 05:52:43'),(82,1,'session.delete','event_session',13,NULL,'172.18.0.1','2026-11-11 05:52:58'),(83,1,'session.delete','event_session',12,NULL,'172.18.0.1','2026-11-11 05:53:00'),(84,1,'session.create','event_session',14,NULL,'172.18.0.1','2026-11-11 05:53:14'),(85,1,'session.create','event_session',15,NULL,'172.18.0.1','2026-11-11 05:53:30'),(86,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 07:01:13'),(87,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-11 07:02:35'),(88,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 07:06:31'),(89,1,'event.signature','event',3,NULL,'172.18.0.1','2026-11-11 08:22:15'),(90,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 08:31:44'),(91,1,'event.signature_removed','event',3,'{\"signatory\": 1}','172.18.0.1','2026-11-11 08:31:44'),(92,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 08:33:06'),(93,1,'event.signature','event',3,NULL,'172.18.0.1','2026-11-11 08:33:45'),(94,1,'event.signature_removed','event',3,'{\"signatory\": 1}','172.18.0.1','2026-11-11 08:33:53'),(95,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-11 08:41:32'),(96,2,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 08:41:55'),(97,3,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 08:43:04'),(98,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 08:46:37'),(99,1,'user.update','user',3,'{\"is_active\": {\"to\": false, \"from\": true}}','172.18.0.1','2026-11-11 08:48:36'),(100,1,'user.update','user',3,'{\"is_active\": {\"to\": true, \"from\": false}}','172.18.0.1','2026-11-11 08:48:41'),(101,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:11:38'),(102,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:12:05'),(103,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:12:24'),(104,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:12:30'),(105,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:12:59'),(106,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:13:47'),(107,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:14:10'),(108,1,'report.export','event',3,'{\"rows\": 0, \"format\": \"checkins.xlsx\"}','172.18.0.1','2026-11-11 10:27:36'),(109,1,'report.export','event',3,'{\"rows\": 3, \"format\": \"attendance.xlsx\"}','172.18.0.1','2026-11-11 10:27:36'),(110,1,'report.export','event',3,'{\"rows\": 3, \"format\": \"attendance.csv\"}','172.18.0.1','2026-11-11 10:27:36'),(111,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:31:39'),(112,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:31:52'),(113,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:32:48'),(114,NULL,'portal.signin','member',5,NULL,'172.18.0.1','2026-11-11 10:38:45'),(115,NULL,'registration.create','registration',9,'{\"emailed\": true, \"event_id\": 3}','172.18.0.1','2026-11-11 10:42:44'),(116,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 10:43:15'),(117,NULL,'portal.signin','member',8,NULL,'172.18.0.1','2026-11-11 10:43:26'),(118,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 12:46:09'),(119,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 13:04:50'),(120,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 13:53:45'),(121,NULL,'portal.signin','member',6,NULL,'172.18.0.1','2026-11-11 13:54:39'),(122,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 14:12:17'),(123,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 14:36:56'),(124,1,'member.update','member',5,'{\"email\": {\"to\": \"kirkcarpio@gmail.com\", \"from\": \"kirkcarpio45@gmail.com\"}, \"changed\": [\"first_name\", \"last_name\", \"email\"]}','172.18.0.1','2026-11-11 14:37:29'),(125,NULL,'registration.create','registration',10,'{\"emailed\": true, \"event_id\": 3}','172.18.0.1','2026-11-11 14:40:45'),(126,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 14:41:39'),(127,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-11 14:44:32'),(128,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 14:48:05'),(129,1,'member.update','member',9,'{\"email\": {\"to\": \"carpiokirk@gmail.com\", \"from\": \"kirkcarpio45@gmail.com\"}, \"changed\": [\"first_name\", \"last_name\", \"email\"]}','172.18.0.1','2026-11-11 14:49:20'),(130,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 14:51:29'),(131,NULL,'registration.create','registration',11,'{\"emailed\": true, \"event_id\": 3}','172.18.0.1','2026-11-11 14:56:32'),(132,1,'auth.login',NULL,NULL,NULL,'172.18.0.1','2026-11-11 14:57:13'),(133,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 15:24:06'),(134,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 15:24:44'),(135,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 15:26:01'),(136,NULL,'portal.signin','member',10,NULL,'172.18.0.1','2026-11-11 15:26:16'),(137,1,'member.update','member',8,'{\"email\": {\"to\": \"kirkcarpio54@gmail.com\", \"from\": \"carpiokirk0@gmail.com\"}, \"changed\": [\"email\"]}','172.18.0.1','2026-11-11 15:27:32'),(138,1,'member.update','member',9,'{\"email\": {\"to\": \"carpiokirk0@gmail.com\", \"from\": \"carpiokirk@gmail.com\"}, \"changed\": [\"chapter_region\", \"email\", \"membership_status\"], \"membership_status\": {\"to\": \"Active\", \"from\": \"NonMember\"}}','172.18.0.1','2026-11-11 15:28:39'),(139,NULL,'portal.link_requested',NULL,NULL,NULL,'172.18.0.1','2026-11-11 15:28:47'),(140,NULL,'portal.signin','member',9,NULL,'172.18.0.1','2026-11-11 15:29:14'),(141,1,'event.update','event',3,NULL,'172.18.0.1','2026-11-11 15:40:56'),(142,1,'attendance.sync','event',3,'{\"summary\": {\"valid\": 1}, \"device_id\": \"scanner-52c84745\"}','172.18.0.1','2026-11-11 15:55:12');
/*!40000 ALTER TABLE `logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `member_login_tokens`
--

DROP TABLE IF EXISTS `member_login_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `member_login_tokens` (
  `token_id` int NOT NULL AUTO_INCREMENT,
  `member_id` int NOT NULL,
  `token_hash` char(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expires_at` datetime NOT NULL,
  `used_at` datetime DEFAULT NULL,
  `ip_address` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`token_id`),
  UNIQUE KEY `unique_token_hash` (`token_hash`),
  KEY `idx_member_created` (`member_id`,`created_at`),
  CONSTRAINT `member_login_tokens_ibfk_1` FOREIGN KEY (`member_id`) REFERENCES `members` (`member_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=18 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `member_login_tokens`
--

LOCK TABLES `member_login_tokens` WRITE;
/*!40000 ALTER TABLE `member_login_tokens` DISABLE KEYS */;
INSERT INTO `member_login_tokens` VALUES (1,5,'51cf38d8b84e0ebce5191b625d3351665f3c210b0a6c1041f4318d14e88da9b9','2026-11-05 15:15:18','2026-11-11 18:38:45','172.18.0.1','2026-11-05 06:45:18'),(2,5,'66f4e398c7e223587e1c22bff351aa3cf2147f0a973ff17e77b89f4763edab45','2026-11-05 15:24:10','2026-11-11 18:38:45','172.18.0.1','2026-11-05 06:54:10'),(3,6,'87a0420abc7ddb7b4424a8e2443480f287f175eac3017bd8f1d4072fe360115f','2026-11-07 19:08:27','2026-11-11 21:54:39','172.18.0.1','2026-11-07 10:38:27'),(4,6,'59fd63d5eeb2e0a2e1c0c173d78d625a67c241eafc09efc8f9570c59a380c801','2026-11-11 15:36:31','2026-11-11 21:54:39','172.18.0.1','2026-11-11 07:06:31'),(10,6,'8113c1400681f436f81746dd34b1716e6ae0387cfcf9bd22ebb1ab56bf760a2e','2026-11-11 19:01:52','2026-11-11 21:54:39','172.18.0.1','2026-11-11 10:31:52'),(11,5,'cc3f15b6bf22687c72b60e15bcdf8bea71595f52668bcc172357d93cc9cb4faa','2026-11-11 19:02:48','2026-11-11 18:38:45','172.18.0.1','2026-11-11 10:32:48'),(12,8,'e631878aa07bcd0ca93b3b1404d1f65fbd682f5b11de1a154060c8d5d94b8adc','2026-11-11 19:13:15','2026-11-11 18:43:26','172.18.0.1','2026-11-11 10:43:15'),(13,6,'b756a57ab886ef98ad032a3fad3d8738b9be14a7037a84029c12599c923db956','2026-11-11 22:23:45','2026-11-11 21:54:39','172.18.0.1','2026-11-11 13:53:45'),(14,6,'a7af527ae8af31028033778839ad57cd73ed5a9c97df67d8866fe0fc1f38e084','2026-11-11 23:54:06',NULL,'172.18.0.1','2026-11-11 15:24:06'),(15,8,'5f8eaa7bd99c81a2cdaa82a958b995cb83c59c1d9ac2909f4881943028ed76d8','2026-11-11 23:54:44','2026-11-11 23:27:32','172.18.0.1','2026-11-11 15:24:44'),(16,10,'af4faf845e72c13e5ec5634fc27d14837a00ba26d55befa57feed3975f901afa','2026-11-11 23:56:01','2026-11-11 23:26:16','172.18.0.1','2026-11-11 15:26:01'),(17,9,'f21108412a56999d754a74c16b06563a7bc159947c4cf65e33e9b50bcbb8d120','2026-11-11 23:58:47','2026-11-11 23:29:14','172.18.0.1','2026-11-11 15:28:47');
/*!40000 ALTER TABLE `member_login_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `members`
--

DROP TABLE IF EXISTS `members`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `members` (
  `member_id` int NOT NULL AUTO_INCREMENT,
  `prc_license_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `first_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_number` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `designation` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nickname` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `birthdate` date DEFAULT NULL,
  `flight_arrival` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `flight_departure` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `food_allergies` text COLLATE utf8mb4_unicode_ci,
  `chapter_region` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `membership_status` enum('Active','Inactive','NonMember') COLLATE utf8mb4_unicode_ci DEFAULT 'NonMember',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `last_portal_login_at` datetime DEFAULT NULL,
  PRIMARY KEY (`member_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `members`
--

LOCK TABLES `members` WRITE;
/*!40000 ALTER TABLE `members` DISABLE KEYS */;
INSERT INTO `members` VALUES (1,'0071234','Carmela','Villanueva','carmela.villanueva@example.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Region IV-A - CALABARZON','NonMember','2026-10-31 14:45:37',NULL),(2,NULL,'Rafael','Mendoza','rafael.mendoza@example.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Region III - Central Luzon','NonMember','2026-10-31 14:45:37',NULL),(3,'0059310','Teresa','Aquino','teresa.aquino@example.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'NCR - National Capital Region','NonMember','2026-10-31 14:45:37',NULL),(4,'0080127','Benjamin','Ocampo','benjamin.ocampo@example.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Region I - Ilocos Region','NonMember','2026-10-31 14:45:37',NULL),(5,NULL,'Ben','Carpio','kirkcarpio@gmail.com','09064152705',NULL,NULL,NULL,NULL,NULL,NULL,'Region IV-A - CALABARZON','NonMember','2026-10-31 14:52:37','2026-11-11 18:38:45'),(6,NULL,'Kirk','games','kitrixegames@gmail.com','09064152705',NULL,NULL,NULL,NULL,NULL,NULL,NULL,'NonMember','2026-11-07 10:36:41','2026-11-11 21:54:39'),(7,NULL,'mark','Carpio','markcarpio@gmail.com','09064152705','asdawdawd','mark','2000-01-08','asdawdawdawd','asdawdawd','asdasdawdawd','Region IV-A - CALABARZON','NonMember','2026-11-10 07:23:06',NULL),(8,NULL,'Kirk','Carpio','kirkcarpio54@gmail.com','09064152705',NULL,'kit','2005-02-01',NULL,NULL,'nuts','Region III - Central Luzon','NonMember','2026-11-11 10:42:39','2026-11-11 18:43:26'),(9,NULL,'carpio','kirk','carpiokirk0@gmail.com',NULL,NULL,'kirk',NULL,NULL,NULL,NULL,'Region IV-A - CALABARZON','Active','2026-11-11 14:40:41','2026-11-11 23:29:14'),(10,NULL,'kirk','Carpio','kirkcarpio45@gmail.com',NULL,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'NonMember','2026-11-11 14:56:27','2026-11-11 23:26:16');
/*!40000 ALTER TABLE `members` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `registrations`
--

DROP TABLE IF EXISTS `registrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `registrations` (
  `registration_id` int NOT NULL AUTO_INCREMENT,
  `event_id` int NOT NULL,
  `member_id` int NOT NULL,
  `qr_token` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `custom_responses` json DEFAULT NULL,
  `registration_date` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`registration_id`),
  UNIQUE KEY `qr_token` (`qr_token`),
  UNIQUE KEY `unique_event_member` (`event_id`,`member_id`),
  KEY `member_id` (`member_id`),
  CONSTRAINT `registrations_ibfk_1` FOREIGN KEY (`event_id`) REFERENCES `events` (`event_id`) ON DELETE CASCADE,
  CONSTRAINT `registrations_ibfk_2` FOREIGN KEY (`member_id`) REFERENCES `members` (`member_id`) ON DELETE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `registrations`
--

LOCK TABLES `registrations` WRITE;
/*!40000 ALTER TABLE `registrations` DISABLE KEYS */;
INSERT INTO `registrations` VALUES (1,1,1,'AGRIPASS|1|1|e0d558af3cb3d27dc032c9f1a64f4c9b',NULL,'2026-10-31 14:45:37'),(2,1,2,'AGRIPASS|1|2|90fcf84854d217d1aeec5adaaa82aeb4',NULL,'2026-10-31 14:45:37'),(3,1,3,'AGRIPASS|1|3|b680afa85dc6ff825ea4b3ed4824c516',NULL,'2026-10-31 14:45:37'),(4,1,4,'AGRIPASS|1|4|645cfee1adaee7ead3470b80d2e95148',NULL,'2026-10-31 14:45:37'),(5,2,5,'AGRIPASS|2|5|595eb58babfb7beedad09d0e72221cb3','{\"1\": \"L\", \"3\": \"San pablo colleges\"}','2026-10-31 14:52:37'),(6,3,5,'AGRIPASS|3|6|f414ff58eb8fb718a169446d4d0a64b9','{}','2026-11-05 06:52:55'),(7,3,6,'AGRIPASS|3|7|aa2af435b3236443887e3c83e5b096c5','{}','2026-11-07 10:36:41'),(8,3,7,'AGRIPASS|3|8|08c72d955455ea0495353409734fc3dd','{}','2026-11-10 07:23:06'),(9,3,8,'AGRIPASS|3|9|c76884a8afe5d36a69862734ab4dffbe','{}','2026-11-11 10:42:39'),(10,3,9,'AGRIPASS|3|10|a8a46aed5172947e30c680dec3173dc6','{}','2026-11-11 14:40:41'),(11,3,10,'AGRIPASS|3|11|51c629192468a1aeecf40d158d4a8749','{}','2026-11-11 14:56:27');
/*!40000 ALTER TABLE `registrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `password_hash` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('SuperAdmin','RegionalOfficer','Staff') COLLATE utf8mb4_unicode_ci DEFAULT 'Staff',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `must_change_password` tinyint(1) NOT NULL DEFAULT '0',
  `last_login_at` datetime DEFAULT NULL,
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES (1,'PAA Super Admin','admin@paa.local','$2y$10$evFVZrLLzaxITPRXzmge9.JBZZAj3VxuJAXIkGnW4LHSIDkrlv52.','SuperAdmin',1,0,'2026-11-11 22:57:13','2026-10-31 14:42:55'),(2,'Teresa Carpio','paa.staff@gmail.com','$2y$10$nBbXgB6zf6RDyETJYwkLaecnVL0AX4S5ZB3hjiy/guZq/i6dNMtNm','RegionalOfficer',1,0,'2026-11-11 16:41:55','2026-11-10 05:42:26'),(3,'Jeremiah Lasprillas','paa.philippines@gmail.com','$2y$10$99/3xY3UsyoAKrvcCU5CkOFf/XVsZ6bHoTOkUapuyiRbGd4mWQr5S','Staff',1,0,'2026-11-11 16:43:04','2026-11-10 05:44:20');
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-12  0:55:38
