require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');
const http = require('http');

const sequelize = require('./src/config/db');
const { initializeRealtime } = require('./src/services/realtime');

// models (perlu di-require supaya asosiasi & sync jalan)
require('./src/models/User');
require('./src/models/Location');
require('./src/models/WorkSchedule');
require('./src/models/WorkAssignment');
require('./src/models/Absensi');
require('./src/models/Cuti');
require('./src/models/Laporan');
require('./src/models/JenisKegiatan');
require('./src/models/Notifikasi');

const authRoutes = require('./src/routes/authRoutes');
const absensiRoutes = require('./src/routes/absensiRoutes');
const cutiRoutes = require('./src/routes/cutiRoutes');
const laporanRoutes = require('./src/routes/laporanRoutes');
const karyawanRoutes = require('./src/routes/karyawanRoutes');
const notifikasiRoutes = require('./src/routes/notifikasiRoutes');
const locationRoutes = require('./src/routes/locationRoutes');
const workAssignmentRoutes = require('./src/routes/workAssignmentRoutes');
const jenisKegiatanRoutes = require('./src/routes/jenisKegiatanRoutes');

const app = express();
const server = http.createServer(app);

app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// akses file foto absen/cuti/laporan/profil
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

app.use('/api/auth', authRoutes);
app.use('/api/absensi', absensiRoutes);
app.use('/api/cuti', cutiRoutes);
app.use('/api/laporan', laporanRoutes);
app.use('/api/karyawan', karyawanRoutes);
app.use('/api/notifikasi', notifikasiRoutes);
app.use('/api/lokasi', locationRoutes);
app.use('/api/jadwal-kerja', workAssignmentRoutes);
app.use('/api/jenis-kegiatan', jenisKegiatanRoutes);

app.get('/', (req, res) => res.json({ message: 'Absensi API aktif' }));

const PORT = process.env.PORT || 3000;
const { exec } = require('child_process');
const bcrypt = require('bcryptjs');
const mysql = require('mysql2/promise');
const { DataTypes, Op } = require('sequelize');
const User = require('./src/models/User');
const Location = require('./src/models/Location');
const JenisKegiatan = require('./src/models/JenisKegiatan');
const Laporan = require('./src/models/Laporan');

const DEFAULT_LOCATIONS = [
  'Dhoho I',
  'Dhoho II',
  'Lumajang I',
  'Lumajang II',
  'Mumbul I',
  'Mumbul II',
  'Kalitelepak',
  'Banyuwangi',
  'CIMA I',
  'CIMA II',
  'Bungamayang',
];

async function ensureDatabaseExists() {
  const host = process.env.DB_HOST || 'localhost';
  const port = Number(process.env.DB_PORT) || 3306;
  const user = process.env.DB_USER || 'root';
  const password = process.env.DB_PASS || '';
  const dbName = process.env.DB_NAME || 'absensi_db';
  let connection;

  try {
    connection = await mysql.createConnection({
      host,
      port,
      user,
      password,
    });
    await connection.query(
      `CREATE DATABASE IF NOT EXISTS \`${dbName}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;`
    );
    console.log(`✓ Database '${dbName}' diverifikasi / dibuat otomatis.`);
  } catch (err) {
    console.warn(
      `[Peringatan DB] Tidak dapat membuat database '${dbName}' otomatis: ${err.message || err.code || err}`
    );
  } finally {
    if (connection) {
      try {
        await connection.end();
      } catch (err) {
        console.warn(`[Peringatan DB] Gagal menutup koneksi pemeriksaan: ${err.message || err}`);
      }
    }
  }
}

function tryAdbReverse(port) {
  exec(`adb reverse tcp:${port} tcp:${port}`, (err, stdout) => {
    if (!err && stdout && stdout.trim().length > 0) {
      console.log(`[ADB] Port forwarding otomatis aktif untuk HP via USB: tcp:${port} -> tcp:${port}`);
    }
  });
}

async function seedDefaultLocations() {
  await sequelize.query(`
    CREATE TABLE IF NOT EXISTS app_settings (
      setting_key VARCHAR(100) NOT NULL PRIMARY KEY,
      setting_value VARCHAR(255) NOT NULL
    )
  `);
  const [settings] = await sequelize.query(
    'SELECT setting_value FROM app_settings WHERE setting_key = ?',
    { replacements: ['default_locations_seeded'] },
  );
  if (settings.length > 0) {
    console.log('✓ Inisialisasi lokasi default sudah pernah dilakukan.');
    return;
  }

  const existingCount = await Location.count();
  if (existingCount === 0) {
    for (const nama of DEFAULT_LOCATIONS) {
      await Location.findOrCreate({ where: { nama } });
    }
    console.log(`✓ ${DEFAULT_LOCATIONS.length} lokasi kerja siap digunakan.`);
  } else {
    console.log(`✓ ${existingCount} lokasi kerja tersimpan.`);
  }

  await sequelize.query(
    'INSERT INTO app_settings (setting_key, setting_value) VALUES (?, ?)',
    { replacements: ['default_locations_seeded', '1'] },
  );
}

async function seedDefaultUsers() {
  try {
    const adminPass = await bcrypt.hash('admin123', 10);
    const karyawanPass = await bcrypt.hash('karyawan123', 10);

    // 1. Pastikan Admin selalu ada
    const [adminUser, adminCreated] = await User.findOrCreate({
      where: { email: 'admin@mail.com' },
      defaults: {
        nama: 'Admin',
        email: 'admin@mail.com',
        password: adminPass,
        role: 'admin',
        jabatan: 'Administrator',
        is_active: true,
      },
    });
    if (!adminCreated && !adminUser.is_active) {
      adminUser.is_active = true;
      await adminUser.save();
    }

    // 2. Pastikan Karyawan Demo selalu ada
    const [karyawanUser, karyawanCreated] = await User.findOrCreate({
      where: { email: 'karyawan@mail.com' },
      defaults: {
        nama: 'Karyawan Demo',
        email: 'karyawan@mail.com',
        password: karyawanPass,
        role: 'karyawan',
        jabatan: 'Staff IT',
        no_hp: '081234567890',
        is_active: true,
      },
    });

    if (karyawanCreated) {
      console.log('✓ Akun Karyawan Demo (karyawan@mail.com) berhasil dibuat otomatis.');
    } else if (!karyawanUser.is_active) {
      karyawanUser.is_active = true;
      await karyawanUser.save();
      console.log('✓ Status aktif akun Karyawan Demo disinkronkan kembali.');
    }

    console.log('✓ Akun default demo (admin & karyawan) siap digunakan.');
  } catch (err) {
    console.warn('Gagal seed default users:', err.message);
  }
}

async function syncExistingCutiNotifications() {
  try {
    const Cuti = require('./src/models/Cuti');
    const Notifikasi = require('./src/models/Notifikasi');
    const listCuti = await Cuti.findAll({ order: [['id', 'ASC']] });
    for (const c of listCuti) {
      if (c.status === 'diterima' || c.status === 'ditolak') {
        const isAcc = c.status === 'diterima';
        const judul = isAcc ? 'Pengajuan Cuti Disetujui' : 'Pengajuan Cuti Ditolak';
        const pesan = isAcc
          ? `Pengajuan cuti ${c.jenis_cuti} (${c.tanggal_mulai} s/d ${c.tanggal_selesai}) telah disetujui admin.`
          : `Pengajuan cuti ${c.jenis_cuti} (${c.tanggal_mulai} s/d ${c.tanggal_selesai}) ditolak. Alasan: ${c.catatan_admin || 'Tidak ada catatan.'}`;

        const existing = await Notifikasi.findOne({
          where: {
            user_id: c.user_id,
            tipe: 'cuti',
            judul,
            pesan,
          },
        });

        if (!existing) {
          await Notifikasi.create({
            user_id: c.user_id,
            tipe: 'cuti',
            judul,
            pesan,
            cta_text: 'Lihat Status & Riwayat Cuti →',
            data: JSON.stringify({ cuti_id: c.id, tabIndex: 1 }),
            is_read: false,
          });
        }
      }
    }
  } catch (err) {
    console.warn('Gagal sync notifikasi cuti:', err.message);
  }
}

async function ensureAttendanceScheduleColumns() {
  const queryInterface = sequelize.getQueryInterface();
  const locations = await queryInterface.describeTable('locations');
  if (!locations.latitude) {
    await queryInterface.addColumn('locations', 'latitude', {
      type: DataTypes.DECIMAL(10, 7),
      allowNull: true,
    });
  }
  if (!locations.longitude) {
    await queryInterface.addColumn('locations', 'longitude', {
      type: DataTypes.DECIMAL(10, 7),
      allowNull: true,
    });
  }
  if (!locations.radius_meters) {
    await queryInterface.addColumn('locations', 'radius_meters', {
      type: DataTypes.INTEGER,
      allowNull: false,
      defaultValue: 250,
    });
  }

  const users = await queryInterface.describeTable('users');
  if (!users.location_id) {
    await queryInterface.addColumn('users', 'location_id', {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: { model: 'locations', key: 'id' },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  }

  const absensi = await queryInterface.describeTable('absensi');
  if (!absensi.jam_masuk_target) {
    await queryInterface.addColumn('absensi', 'jam_masuk_target', {
      type: DataTypes.TIME,
      allowNull: true,
    });
  }
  if (!absensi.work_assignment_id) {
    await queryInterface.addColumn('absensi', 'work_assignment_id', {
      type: DataTypes.INTEGER,
      allowNull: true,
      references: { model: 'work_assignments', key: 'id' },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  }
  const indexes = await queryInterface.showIndex('absensi');
  if (!indexes.some((index) => index.name === 'absensi_work_assignment_unique')) {
    await queryInterface.addIndex('absensi', ['work_assignment_id'], {
      name: 'absensi_work_assignment_unique',
      unique: true,
    });
  }
  const [assignmentConstraints] = await sequelize.query(`
    SELECT CONSTRAINT_NAME
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'absensi'
      AND COLUMN_NAME = 'work_assignment_id'
      AND REFERENCED_TABLE_NAME = 'work_assignments'
  `);
  if (assignmentConstraints.length === 0) {
    await queryInterface.addConstraint('absensi', {
      fields: ['work_assignment_id'],
      type: 'foreign key',
      name: 'absensi_work_assignment_fk',
      references: { table: 'work_assignments', field: 'id' },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  }
}

async function ensureJenisKegiatanMaster() {
  const queryInterface = sequelize.getQueryInterface();
  const laporanColumns = await queryInterface.describeTable('laporan');
  const reportColumns = {
    jenis_kegiatan: { type: DataTypes.STRING, allowNull: true },
    jenis_kegiatan_id: { type: DataTypes.INTEGER, allowNull: true },
    lokasi: { type: DataTypes.STRING, allowNull: true },
    unit_drone: { type: DataTypes.STRING, allowNull: true },
    luas_area: { type: DataTypes.STRING, allowNull: true },
    uraian_pekerjaan: { type: DataTypes.TEXT, allowNull: true },
    hasil: { type: DataTypes.TEXT, allowNull: true },
    rencana_esok: { type: DataTypes.TEXT, allowNull: true },
    status: { type: DataTypes.STRING, allowNull: false, defaultValue: 'Terkirim' },
  };
  for (const [column, definition] of Object.entries(reportColumns)) {
    if (!laporanColumns[column]) {
      await queryInterface.addColumn('laporan', column, definition);
    }
  }
  const reportIndexes = await queryInterface.showIndex('laporan');
  if (!reportIndexes.some((index) => index.name === 'laporan_jenis_kegiatan_id_idx')) {
    await queryInterface.addIndex('laporan', ['jenis_kegiatan_id'], {
      name: 'laporan_jenis_kegiatan_id_idx',
    });
  }

  const [constraints] = await sequelize.query(`
    SELECT CONSTRAINT_NAME
    FROM information_schema.KEY_COLUMN_USAGE
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'laporan'
      AND COLUMN_NAME = 'jenis_kegiatan_id'
      AND REFERENCED_TABLE_NAME = 'jenis_kegiatan'
  `);
  if (constraints.length === 0) {
    await queryInterface.addConstraint('laporan', {
      fields: ['jenis_kegiatan_id'],
      type: 'foreign key',
      name: 'laporan_jenis_kegiatan_fk',
      references: { table: 'jenis_kegiatan', field: 'id' },
      onUpdate: 'CASCADE',
      onDelete: 'SET NULL',
    });
  }

  const defaults = [
    'Penyemprotan Pestisida',
    'Survei dan Pemetaan',
    'Survei dan Pemetaan Lahan',
    'Pemeliharaan Drone',
    'Pemeliharaan Rutin Drone',
    'Penyebaran Pupuk',
    'Penyebaran Pupuk Urea',
    'Operasional Lapangan',
  ];
  for (const nama of defaults) {
    await JenisKegiatan.findOrCreate({
      where: { nama },
      defaults: { nama, is_active: true },
    });
  }

  const legacyTypes = await Laporan.findAll({
    attributes: ['jenis_kegiatan'],
    where: { jenis_kegiatan: { [Op.ne]: null } },
    group: ['jenis_kegiatan'],
    raw: true,
  });
  for (const { jenis_kegiatan: namaRaw } of legacyTypes) {
    const nama = typeof namaRaw === 'string' ? namaRaw.trim() : '';
    if (nama) {
      await JenisKegiatan.findOrCreate({
        where: { nama },
        defaults: { nama, is_active: true },
      });
    }
  }

  const unlinkedReports = await Laporan.findAll({
    where: { jenis_kegiatan_id: null },
    attributes: ['id', 'jenis_kegiatan'],
  });
  for (const report of unlinkedReports) {
    if (!report.jenis_kegiatan) continue;
    const jenis = await JenisKegiatan.findOne({
      where: { nama: report.jenis_kegiatan.trim() },
    });
    if (jenis) {
      await report.update({ jenis_kegiatan_id: jenis.id });
    }
  }
}

async function startServer() {
  try {
    await ensureDatabaseExists();
    await sequelize.sync(); // ganti { alter: true } saat development kalau skema berubah
    await ensureAttendanceScheduleColumns();
    await ensureJenisKegiatanMaster();
    console.log('✓ Database terhubung & model tersinkronisasi');
    await seedDefaultLocations();
    await seedDefaultUsers();
    await syncExistingCutiNotifications();
    initializeRealtime(server);
    server.listen(PORT, '0.0.0.0', () => {
      console.log(`✓ Server jalan di port ${PORT} (http://0.0.0.0:${PORT})`);
      tryAdbReverse(PORT);
      // Keep USB port forwarding alive while the server is running.
      const adbReverseInterval = setInterval(() => {
        exec(`adb reverse tcp:${PORT} tcp:${PORT}`, () => {});
      }, 3000);
      adbReverseInterval.unref();
    });
  } catch (err) {
    console.error('✗ Gagal menyiapkan backend/database:', err);
    console.error('Tips: Pastikan MySQL sudah dijalankan di XAMPP/Laragon dan konfigurasi .env sudah sesuai.');
    try {
      await sequelize.close();
    } catch (closeError) {
      console.error('✗ Gagal menutup koneksi database:', closeError);
    }
    process.exitCode = 1;
  }
}

startServer();
