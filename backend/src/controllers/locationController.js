const Location = require('../models/Location');
const WorkSchedule = require('../models/WorkSchedule');
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
    const nama = typeof req.body.nama === 'string' ? req.body.nama.trim() : '';
    if (!nama) return res.status(400).json({ message: 'Nama lokasi wajib diisi' });

    const data = await Location.create({ nama });
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

    const nama = typeof req.body.nama === 'string' ? req.body.nama.trim() : '';
    if (!nama) return res.status(400).json({ message: 'Nama lokasi wajib diisi' });
    lokasi.nama = nama;
    await lokasi.save();
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
