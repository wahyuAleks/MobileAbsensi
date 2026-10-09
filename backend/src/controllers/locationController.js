const Location = require('../models/Location');
const WorkSchedule = require('../models/WorkSchedule');
const WorkAssignment = require('../models/WorkAssignment');
const User = require('../models/User');

function validDate(value) {
  return /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    !Number.isNaN(Date.parse(`${value}T00:00:00Z`)) &&
    new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) === value;
}

function validTime(value) {
  return typeof value === 'string' &&
    /^([01]\d|2[0-3]):[0-5]\d$/.test(value);
}

function locationValues(body, current = null) {
  const nama = typeof body.nama === 'string' ? body.nama.trim() : '';
  if (!nama) return { error: 'Nama lokasi wajib diisi' };

  const hasLatitude = Object.hasOwn(body, 'latitude');
  const hasLongitude = Object.hasOwn(body, 'longitude');
  if (hasLatitude !== hasLongitude) {
    return { error: 'Latitude dan longitude harus diisi bersamaan' };
  }

  let latitude = current?.latitude ?? null;
  let longitude = current?.longitude ?? null;
  if (hasLatitude) {
    const emptyPair = (body.latitude == null || String(body.latitude).trim() === '') &&
      (body.longitude == null || String(body.longitude).trim() === '');
    if (emptyPair) {
      latitude = null;
      longitude = null;
    } else if (
      !validCoordinate(body.latitude, -90, 90) ||
      !validCoordinate(body.longitude, -180, 180)
    ) {
      return { error: 'Koordinat GPS tidak valid' };
    } else {
      latitude = Number(body.latitude);
      longitude = Number(body.longitude);
    }
  }

  const radius = body.radius_meters === undefined
    ? Number(current?.radius_meters ?? 250)
    : Number(body.radius_meters);
  if (!Number.isInteger(radius) || radius <= 0 || radius > 10000) {
    return { error: 'Radius harus berupa bilangan bulat antara 1 dan 10000 meter' };
  }
  return { value: { nama, latitude, longitude, radius_meters: radius } };
}

function validCoordinate(value, min, max) {
  if (value == null || String(value).trim() === '') return false;
  const number = Number(value);
  return Number.isFinite(number) && number >= min && number <= max;
}

exports.daftarLokasi = async (req, res) => {
  try {
    const data = await Location.findAll({ order: [['nama', 'ASC']] });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat lokasi', error: err.message });
  }
};

exports.tambahLokasi = async (req, res) => {
  try {
    const validated = locationValues(req.body);
    if (validated.error) return res.status(400).json({ message: validated.error });

    const data = await Location.create(validated.value);
    res.status(201).json({ message: 'Lokasi berhasil ditambahkan', data });
  } catch (err) {
    if (err.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ message: 'Nama lokasi sudah digunakan' });
    }
    res.status(500).json({ message: 'Gagal menambahkan lokasi', error: err.message });
  }
};

exports.updateLokasi = async (req, res) => {
  try {
    const lokasi = await Location.findByPk(req.params.id);
    if (!lokasi) return res.status(404).json({ message: 'Lokasi tidak ditemukan' });

    const validated = locationValues(req.body, lokasi);
    if (validated.error) return res.status(400).json({ message: validated.error });
    await lokasi.update(validated.value);
    res.json({ message: 'Lokasi berhasil diperbarui', data: lokasi });
  } catch (err) {
    if (err.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ message: 'Nama lokasi sudah digunakan' });
    }
    res.status(500).json({ message: 'Gagal memperbarui lokasi', error: err.message });
  }
};

exports.hapusLokasi = async (req, res) => {
  try {
    const lokasi = await Location.findByPk(req.params.id);
    if (!lokasi) return res.status(404).json({ message: 'Lokasi tidak ditemukan' });

    const jumlahKaryawan = await User.count({ where: { location_id: lokasi.id } });
    if (jumlahKaryawan > 0) {
      return res.status(409).json({
        message: 'Pindahkan karyawan dari lokasi ini sebelum menghapusnya',
      });
    }

    const jumlahPenugasan = await WorkAssignment.count({ where: { location_id: lokasi.id } });
    if (jumlahPenugasan > 0) {
      return res.status(409).json({
        message: 'Hapus penugasan jadwal kerja di lokasi ini sebelum menghapusnya',
      });
    }

    await WorkSchedule.destroy({ where: { location_id: lokasi.id } });
    await lokasi.destroy();
    res.json({ message: 'Lokasi berhasil dihapus' });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menghapus lokasi', error: err.message });
  }
};

exports.jadwalLokasi = async (req, res) => {
  try {
    const { tanggal } = req.query;
    if (!validDate(tanggal)) {
      return res.status(400).json({ message: 'Tanggal harus berformat YYYY-MM-DD' });
    }
    const lokasi = await Location.findByPk(req.params.id);
    if (!lokasi) return res.status(404).json({ message: 'Lokasi tidak ditemukan' });

    const jadwal = await WorkSchedule.findOne({
      where: { location_id: lokasi.id, tanggal },
    });
    res.json(jadwal || {
      location_id: lokasi.id,
      tanggal,
      jam_masuk: null,
    });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat jam masuk lokasi', error: err.message });
  }
};

exports.simpanJadwalLokasi = async (req, res) => {
  try {
    const { tanggal, jam_masuk: jamMasuk } = req.body;
    if (!validDate(tanggal)) {
      return res.status(400).json({ message: 'Tanggal harus berformat YYYY-MM-DD' });
    }
    if (!validTime(jamMasuk)) {
      return res.status(400).json({ message: 'Jam masuk harus berformat HH:mm' });
    }
    const lokasi = await Location.findByPk(req.params.id);
    if (!lokasi) return res.status(404).json({ message: 'Lokasi tidak ditemukan' });

    const [jadwal] = await WorkSchedule.findOrCreate({
      where: { location_id: lokasi.id, tanggal },
      defaults: { jam_masuk: `${jamMasuk}:00` },
    });
    if (jadwal.jam_masuk !== `${jamMasuk}:00`) {
      jadwal.jam_masuk = `${jamMasuk}:00`;
      await jadwal.save();
    }
    res.json({ message: 'Jam masuk berhasil disimpan', data: jadwal });
  } catch (err) {
    res.status(500).json({ message: 'Gagal menyimpan jam masuk', error: err.message });
  }
};
