-- Schema: create_schema.sql
-- Creates tables: locations, users, work_schedules, absensi, cuti, laporan
-- Run after creating the database (example: USE absensi_db;)

SET FOREIGN_KEY_CHECKS = 0;

CREATE TABLE IF NOT EXISTS `locations` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nama` VARCHAR(255) NOT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `locations_nama_unique` (`nama`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO `locations` (`nama`) VALUES
('Dhoho I'),
('Dhoho II'),
('Lumajang I'),
('Lumajang II'),
('Mumbul I'),
('Mumbul II'),
('Kalitelepak'),
('Banyuwangi'),
('CIMA I'),
('CIMA II'),
('Bungamayang');

CREATE TABLE IF NOT EXISTS `users` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `nama` VARCHAR(255) NOT NULL,
  `email` VARCHAR(255) NOT NULL,
  `password` VARCHAR(255) NOT NULL,
  `role` ENUM('karyawan','admin') NOT NULL DEFAULT 'karyawan',
  `jabatan` VARCHAR(255) DEFAULT NULL,
  `no_hp` VARCHAR(50) DEFAULT NULL,
  `foto_profil` VARCHAR(255) DEFAULT NULL,
  `location_id` INT DEFAULT NULL,
  `is_active` TINYINT(1) NOT NULL DEFAULT 1,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_email_unique` (`email`),
  KEY `users_location_id_idx` (`location_id`),
  CONSTRAINT `users_location_fk` FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `absensi` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `tanggal` DATE NOT NULL,
  `jam_masuk` TIME DEFAULT NULL,
  `jam_masuk_target` TIME DEFAULT NULL,
  `jam_pulang` TIME DEFAULT NULL,
  `foto_masuk` VARCHAR(255) DEFAULT NULL,
  `foto_pulang` VARCHAR(255) DEFAULT NULL,
  `lat_masuk` DECIMAL(10,7) DEFAULT NULL,
  `lng_masuk` DECIMAL(10,7) DEFAULT NULL,
  `lat_pulang` DECIMAL(10,7) DEFAULT NULL,
  `lng_pulang` DECIMAL(10,7) DEFAULT NULL,
  `status` ENUM('hadir','telat','alpha') NOT NULL DEFAULT 'hadir',
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `absensi_user_id_idx` (`user_id`),
  CONSTRAINT `absensi_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `work_schedules` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `location_id` INT NOT NULL,
  `tanggal` DATE NOT NULL,
  `jam_masuk` TIME NOT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `work_schedules_location_tanggal_unique` (`location_id`, `tanggal`),
  CONSTRAINT `work_schedules_location_fk` FOREIGN KEY (`location_id`) REFERENCES `locations`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `cuti` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `jenis_cuti` VARCHAR(255) NOT NULL,
  `tanggal_mulai` DATE NOT NULL,
  `tanggal_selesai` DATE NOT NULL,
  `alasan` TEXT NOT NULL,
  `lampiran` VARCHAR(255) DEFAULT NULL,
  `status` ENUM('menunggu','diterima','ditolak') NOT NULL DEFAULT 'menunggu',
  `catatan_admin` TEXT DEFAULT NULL,
  `diproses_oleh` INT DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `cuti_user_id_idx` (`user_id`),
  KEY `cuti_diproses_oleh_idx` (`diproses_oleh`),
  CONSTRAINT `cuti_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `cuti_diproses_by_fk` FOREIGN KEY (`diproses_oleh`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS `laporan` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `user_id` INT NOT NULL,
  `tanggal` DATE NOT NULL,
  `judul` VARCHAR(255) NOT NULL,
  `isi_laporan` TEXT NOT NULL,
  `lampiran` VARCHAR(255) DEFAULT NULL,
  `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  KEY `laporan_user_id_idx` (`user_id`),
  CONSTRAINT `laporan_user_fk` FOREIGN KEY (`user_id`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

SET FOREIGN_KEY_CHECKS = 1;

-- Akun Default Demo (Admin & Karyawan)
INSERT IGNORE INTO `users` (`id`, `nama`, `email`, `password`, `role`, `jabatan`, `no_hp`, `is_active`, `createdAt`, `updatedAt`) VALUES
(1, 'Admin', 'admin@mail.com', '$2a$10$y2cHQ3/HxHkKJuBWU1.oq.dKHl8vzwkxHLIEkKDF0rgRqPoD94Dba', 'admin', 'Administrator', NULL, 1, NOW(), NOW()),
(2, 'Karyawan Demo', 'karyawan@mail.com', '$2a$10$ZMTRXxbpY355bQy0TDQBauPNir52e6o74lW4pdd0xLb1ZgiIDjZIS', 'karyawan', 'Staff IT', '081234567890', 1, NOW(), NOW());
