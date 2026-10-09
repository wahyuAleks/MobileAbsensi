const bcrypt = require('bcryptjs');
const User = require('../models/User');

// LIHAT DAFTAR KARYAWAN
exports.daftarKaryawan = async (req, res) => {
  try {
    const data = await User.findAll({
      where: { role: 'karyawan' },
      attributes: { exclude: ['password'] },
      order: [['nama', 'ASC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

exports.daftarAkun = async (req, res) => {
  try {
    const data = await User.findAll({
      attributes: { exclude: ['password'] },
      order: [['nama', 'ASC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

exports.detailKaryawan = async (req, res) => {
  try {
    const data = await User.findByPk(req.params.id, { attributes: { exclude: ['password'] } });
    if (!data) return res.status(404).json({ message: 'Karyawan tidak ditemukan' });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// CRUD DATA KARYAWAN - create
exports.tambahKaryawan = async (req, res) => {
  try {
    const { nama, email, password, jabatan, no_hp } = req.body;
    const role = req.body.role ?? 'karyawan';
    if (!nama || !email || !password) {
      return res.status(400).json({ message: 'Nama, email, dan password wajib diisi' });
    }
    if (!['admin', 'karyawan'].includes(role)) {
      return res.status(400).json({ message: 'Role harus admin atau karyawan' });
    }

    const existing = await User.findOne({ where: { email } });
    if (existing) return res.status(400).json({ message: 'Email sudah terdaftar' });

    const hash = await bcrypt.hash(password, 10);
    const user = await User.create({
      nama, email, password: hash, jabatan, no_hp, role,
    });

    const { password: _pw, ...userTanpaPassword } = user.toJSON();
    res.status(201).json({
      message: role === 'admin' ? 'Admin berhasil ditambahkan' : 'Karyawan berhasil ditambahkan',
      data: userTanpaPassword,
    });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// CRUD DATA KARYAWAN - update
exports.updateKaryawan = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ message: 'Karyawan tidak ditemukan' });

    const { nama, email, password, jabatan, no_hp, is_active } = req.body;
    if (nama) user.nama = nama;
    if (email && email !== user.email) {
      const existing = await User.findOne({ where: { email } });
      if (existing && existing.id !== user.id) {
        return res.status(400).json({ message: 'Email sudah digunakan akun lain' });
      }
      user.email = email;
    }
    if (password && password.trim().length > 0) {
      user.password = await bcrypt.hash(password.trim(), 10);
    }
    if (jabatan) user.jabatan = jabatan;
    if (no_hp !== undefined) user.no_hp = no_hp;
    if (typeof is_active === 'boolean') user.is_active = is_active;

    await user.save();
    const { password: _pw, ...userTanpaPassword } = user.toJSON();
    res.json({ message: 'Data karyawan berhasil diperbarui', data: userTanpaPassword });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// CRUD DATA KARYAWAN - delete
exports.hapusKaryawan = async (req, res) => {
  try {
    const user = await User.findByPk(req.params.id);
    if (!user) return res.status(404).json({ message: 'Karyawan tidak ditemukan' });

    const Absensi = require('../models/Absensi');
    const Cuti = require('../models/Cuti');
    const Laporan = require('../models/Laporan');
    await Absensi.destroy({ where: { user_id: user.id } });
    await Cuti.destroy({ where: { user_id: user.id } });
    await Laporan.destroy({ where: { user_id: user.id } });

    await user.destroy();
    res.json({ message: 'Karyawan berhasil dihapus' });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};
