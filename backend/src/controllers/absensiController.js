const { Op } = require('sequelize');
const Absensi = require('../models/Absensi');
const User = require('../models/User');
const WorkSchedule = require('../models/WorkSchedule');
const Location = require('../models/Location');
const { isDalamRadiusKantor } = require('../utils/geo');

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

async function jamMasukTarget(userId, tanggal) {
  const user = await User.findByPk(userId, { attributes: ['location_id'] });
  if (!user || !user.location_id) return '08:00:00';
  const jadwal = await WorkSchedule.findOne({
    where: { location_id: user.location_id, tanggal },
  });
  return jadwal ? jadwal.jam_masuk : '08:00:00';
}

// ABSENSI MASUK: ambil foto + validasi GPS
exports.absenMasuk = async (req, res) => {
  try {
    const { lat, lng } = req.body;
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Lokasi (lat, lng) wajib dikirim' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'Foto absen wajib diupload' });
    }

    const { valid, jarak } = isDalamRadiusKantor(parseFloat(lat), parseFloat(lng));
    if (!valid) {
      return res.status(400).json({
        message: `Lokasi di luar radius kantor (jarak ${Math.round(jarak)}m). Absen ditolak.`,
      });
    }

    const tanggal = hariIni();
    const sudah = await Absensi.findOne({ where: { user_id: req.user.id, tanggal } });
    if (sudah && sudah.jam_masuk) {
      return res.status(400).json({ message: 'Anda sudah absen masuk hari ini' });
    }

    const jam = jamSekarang();
    const batasJamMasuk = await jamMasukTarget(req.user.id, tanggal);
    const isTelat = jam > batasJamMasuk;
    const status = isTelat ? 'telat' : 'hadir';

    const data = sudah || await Absensi.create({ user_id: req.user.id, tanggal });
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
    });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// ABSENSI PULANG: ambil foto + validasi GPS + validasi jam >= 17:00
exports.absenPulang = async (req, res) => {
  try {
    const { lat, lng } = req.body;
    if (!lat || !lng) {
      return res.status(400).json({ message: 'Lokasi (lat, lng) wajib dikirim' });
    }
    if (!req.file) {
      return res.status(400).json({ message: 'Foto absen wajib diupload' });
    }

    // Validasi jam: absen pulang hanya boleh mulai pukul 17:00 WIB
    const jam = jamSekarang(); // HH:MM:SS
    if (jam < '17:00:00') {
      const sisaMenit = Math.ceil(
        (new Date(`1970-01-01T17:00:00`) - new Date(`1970-01-01T${jam}`)) / 60000
      );
      return res.status(400).json({
        message: `Absen pulang hanya bisa dilakukan mulai pukul 17:00 WIB. Sisa waktu: ${sisaMenit} menit lagi.`,
      });
    }

    const { valid, jarak } = isDalamRadiusKantor(parseFloat(lat), parseFloat(lng));
    if (!valid) {
      return res.status(400).json({
        message: `Lokasi di luar radius kantor (jarak ${Math.round(jarak)}m). Absen ditolak.`,
      });
    }

    const tanggal = hariIni();
    const data = await Absensi.findOne({ where: { user_id: req.user.id, tanggal } });
    if (!data || !data.jam_masuk) {
      return res.status(400).json({ message: 'Anda belum absen masuk hari ini' });
    }
    if (data.jam_pulang) {
      return res.status(400).json({ message: 'Anda sudah absen pulang hari ini' });
    }

    data.jam_pulang = jam;
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
    const data = await Absensi.findOne({
      where: { user_id: req.user.id, tanggal: hariIni() },
    });
    const target = await jamMasukTarget(req.user.id, hariIni());
    res.json({
      sudah_absen_masuk: !!(data && data.jam_masuk),
      sudah_absen_pulang: !!(data && data.jam_pulang),
      data: data || null,
      jam_masuk_target: target,
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
      }],
      order: [['tanggal', 'DESC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};
