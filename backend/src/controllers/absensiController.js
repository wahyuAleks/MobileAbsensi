const { Op } = require('sequelize');
const Absensi = require('../models/Absensi');
const User = require('../models/User');
const WorkAssignment = require('../models/WorkAssignment');
const Location = require('../models/Location');
const { isDalamRadiusLokasi, validCoordinatePair } = require('../utils/geo');
const { canCheckIn, canCheckOut, checkInWindow, isLate } = require('../utils/attendanceRules');

function waktuWib() {
  const parts = new Intl.DateTimeFormat('en-GB', {
    timeZone: 'Asia/Jakarta',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hourCycle: 'h23',
  }).formatToParts(new Date());
  const value = Object.fromEntries(parts.map(({ type, value: part }) => [type, part]));
  return {
    tanggal: `${value.year}-${value.month}-${value.day}`,
    jam: `${value.hour}:${value.minute}:${value.second}`,
  };
}

function hariIni() {
  return waktuWib().tanggal;
}

function jamSekarang() {
  return waktuWib().jam;
}

async function jadwalAbsensi(req, res, jenis) {
  const assignmentId = Number(req.body.jadwal_id);
  if (!Number.isInteger(assignmentId) || assignmentId <= 0) {
    res.status(400).json({ message: 'Slot jadwal kerja wajib dipilih' });
    return null;
  }
  const assignment = await WorkAssignment.findOne({
    where: { id: assignmentId, user_id: req.user.id, tanggal: hariIni() },
    include: [{ model: Location, attributes: ['id', 'nama', 'latitude', 'longitude', 'radius_meters'] }],
  });
  if (!assignment) {
    res.status(404).json({ message: 'Slot jadwal kerja hari ini tidak ditemukan' });
    return null;
  }
  const now = jamSekarang();
  if (jenis === 'masuk') {
    if (!canCheckIn(now, assignment.jam_mulai, assignment.jam_selesai)) {
      const window = checkInWindow(assignment.jam_mulai, assignment.jam_selesai);
      res.status(400).json({
        message: `Absen masuk hanya tersedia pukul ${window.opens} sampai ${window.closes}.`,
      });
      return null;
    }
  } else if (!canCheckOut(now, assignment.jam_selesai)) {
    res.status(400).json({
      message: `Absen pulang tersedia setelah pukul ${assignment.jam_selesai.slice(0, 5)} WIB.`,
    });
    return null;
  }
  return assignment;
}

// ABSENSI MASUK: ambil foto + validasi GPS
exports.absenMasuk = async (req, res) => {
  try {
    const { lat, lng } = req.body;
    if (!validCoordinatePair(lat, lng)) {
      return res.status(400).json({ message: 'Koordinat GPS (lat, lng) tidak valid' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'Foto absen wajib diupload' });
    }

    const assignment = await jadwalAbsensi(req, res, 'masuk');
    if (!assignment) return;
    const gps = isDalamRadiusLokasi(lat, lng, assignment.Location);
    if (!gps.configured) {
      return res.status(409).json({
        message: 'Koordinat GPS lokasi kerja belum dikonfigurasi admin.',
      });
    }
    if (!gps.valid) {
      return res.status(400).json({
        message: `Lokasi di luar radius kerja (jarak ${Math.round(gps.jarak)}m). Absen ditolak.`,
      });
    }

    const tanggal = hariIni();
    const sudah = await Absensi.findOne({
      where: { user_id: req.user.id, work_assignment_id: assignment.id },
    });
    if (sudah && sudah.jam_masuk) {
      return res.status(400).json({ message: 'Anda sudah absen masuk untuk slot ini' });
    }

    const jam = jamSekarang();
    const batasJamMasuk = assignment.jam_mulai;
    const status = isLate(jam, batasJamMasuk) ? 'telat' : 'hadir';

    const data = sudah || await Absensi.create({
      user_id: req.user.id,
      tanggal,
      work_assignment_id: assignment.id,
    });
    data.jam_masuk = jam;
    data.jam_masuk_target = batasJamMasuk;
    data.foto_masuk = `/uploads/absensi/${req.file.filename}`;
    data.lat_masuk = lat;
    data.lng_masuk = lng;
    data.status = status;
    await data.save();

    res.json({
      message: 'Absen masuk berhasil',
      data,
      jam_masuk_target: batasJamMasuk,
      nama_lokasi: assignment.Location.nama,
    });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// ABSENSI PULANG: ambil foto + validasi GPS setelah jam selesai slot
exports.absenPulang = async (req, res) => {
  try {
    const { lat, lng } = req.body;
    if (!validCoordinatePair(lat, lng)) {
      return res.status(400).json({ message: 'Koordinat GPS (lat, lng) tidak valid' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'Foto absen wajib diupload' });
    }

    const assignment = await jadwalAbsensi(req, res, 'pulang');
    if (!assignment) return;

    const gps = isDalamRadiusLokasi(lat, lng, assignment.Location);
    if (!gps.configured) {
      return res.status(409).json({
        message: 'Koordinat GPS lokasi kerja belum dikonfigurasi admin.',
      });
    }
    if (!gps.valid) {
      return res.status(400).json({
        message: `Lokasi di luar radius kerja (jarak ${Math.round(gps.jarak)}m). Absen ditolak.`,
      });
    }

    const tanggal = hariIni();
    const data = await Absensi.findOne({
      where: { user_id: req.user.id, tanggal, work_assignment_id: assignment.id },
    });
    if (!data || !data.jam_masuk) {
      return res.status(400).json({ message: 'Anda belum absen masuk untuk slot ini' });
    }
    if (data.jam_pulang) {
      return res.status(400).json({ message: 'Anda sudah absen pulang untuk slot ini' });
    }

    data.jam_pulang = jamSekarang();
    data.foto_pulang = `/uploads/absensi/${req.file.filename}`;
    data.lat_pulang = lat;
    data.lng_pulang = lng;
    await data.save();

    res.json({ message: 'Absen pulang berhasil', data });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// status absen hari ini (dipakai HOME screen utk cek "SUDAH ABSEN MASUK?")
exports.statusHariIni = async (req, res) => {
  try {
    const [data, assignments] = await Promise.all([
      Absensi.findOne({
        where: { user_id: req.user.id, tanggal: hariIni(), work_assignment_id: null },
        order: [['id', 'DESC']],
      }),
      WorkAssignment.findAll({
        where: { user_id: req.user.id, tanggal: hariIni() },
        include: [
          { model: Location, attributes: ['id', 'nama'] },
          { model: Absensi, as: 'absensi' },
        ],
        order: [['jam_mulai', 'ASC'], ['id', 'ASC']],
      }),
    ]);
    const target = data?.jam_masuk_target ?? null;
    res.json({
      sudah_absen_masuk: !!(data && data.jam_masuk),
      sudah_absen_pulang: !!(data && data.jam_pulang),
      data: data || null,
      jam_masuk_target: target,
      assignments,
    });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// RIWAYAT ABSEN milik karyawan yang login
exports.riwayatSaya = async (req, res) => {
  try {
    const { bulan, tahun } = req.query;
    const where = { user_id: req.user.id };

    if (bulan && tahun) {
      const start = `${tahun}-${String(bulan).padStart(2, '0')}-01`;
      const endDate = new Date(tahun, bulan, 0).getDate();
      const end = `${tahun}-${String(bulan).padStart(2, '0')}-${endDate}`;
      where.tanggal = { [Op.between]: [start, end] };
    }

    const data = await Absensi.findAll({
      where,
      include: [{
        model: User,
        attributes: ['id', 'nama', 'email', 'jabatan', 'foto_profil', 'location_id'],
        include: [{ model: Location, attributes: ['id', 'nama'] }],
      }, {
        model: WorkAssignment,
        as: 'jadwal_kerja',
        include: [{ model: Location, attributes: ['id', 'nama'] }],
      }],
      order: [['tanggal', 'DESC'], ['id', 'DESC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// REKAP ABSENSI untuk admin - semua karyawan
exports.rekapAdmin = async (req, res) => {
  try {
    const { tanggal, user_id, bulan, tahun } = req.query;
    const where = {};
    if (tanggal) where.tanggal = tanggal;
    if (user_id) where.user_id = user_id;

    if (bulan && tahun) {
      const start = `${tahun}-${String(bulan).padStart(2, '0')}-01`;
      const endDate = new Date(tahun, bulan, 0).getDate();
      const end = `${tahun}-${String(bulan).padStart(2, '0')}-${endDate}`;
      where.tanggal = { [Op.between]: [start, end] };
    }

    const data = await Absensi.findAll({
      where,
      include: [{
        model: User,
        attributes: ['id', 'nama', 'email', 'jabatan', 'foto_profil', 'location_id'],
        include: [{ model: Location, attributes: ['id', 'nama'] }],
      }, {
        model: WorkAssignment,
        as: 'jadwal_kerja',
        include: [{ model: Location, attributes: ['id', 'nama'] }],
      }],
      order: [['tanggal', 'DESC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};
