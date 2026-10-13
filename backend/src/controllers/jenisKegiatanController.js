const JenisKegiatan = require('../models/JenisKegiatan');
const Laporan = require('../models/Laporan');

function namaDariRequest(value) {
  return typeof value === 'string' ? value.trim() : '';
}

exports.daftar = async (req, res) => {
  try {
    const where = req.user.role === 'admin'
      ? {}
      : { is_active: true };
    const data = await JenisKegiatan.findAll({
      where,
      order: [['nama', 'ASC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat jenis kegiatan', error: err.message });
  }
};

exports.tambah = async (req, res) => {
  try {
    const nama = namaDariRequest(req.body.nama);
    if (!nama || nama.length > 255) {
      return res.status(400).json({ message: 'Nama jenis kegiatan wajib diisi dan maksimal 255 karakter' });
    }

    const data = await JenisKegiatan.create({ nama, is_active: true });
    res.status(201).json({ message: 'Jenis kegiatan berhasil ditambahkan', data });
  } catch (err) {
    if (err.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ message: 'Jenis kegiatan tersebut sudah terdaftar' });
    }
    res.status(500).json({ message: 'Gagal menambahkan jenis kegiatan', error: err.message });
  }
};

exports.perbarui = async (req, res) => {
  try {
    const jenis = await JenisKegiatan.findByPk(req.params.id);
    if (!jenis) return res.status(404).json({ message: 'Jenis kegiatan tidak ditemukan' });

    const nama = req.body.nama === undefined ? jenis.nama : namaDariRequest(req.body.nama);
    if (!nama || nama.length > 255) {
      return res.status(400).json({ message: 'Nama jenis kegiatan wajib diisi dan maksimal 255 karakter' });
    }
    if (req.body.is_active !== undefined && typeof req.body.is_active !== 'boolean') {
      return res.status(400).json({ message: 'Status aktif tidak valid' });
    }

    await jenis.update({
      nama,
      ...(req.body.is_active === undefined ? {} : { is_active: req.body.is_active }),
    });
    res.json({ message: 'Jenis kegiatan berhasil diperbarui', data: jenis });
  } catch (err) {
    if (err.name === 'SequelizeUniqueConstraintError') {
      return res.status(409).json({ message: 'Jenis kegiatan tersebut sudah terdaftar' });
    }
    res.status(500).json({ message: 'Gagal memperbarui jenis kegiatan', error: err.message });
  }
};

exports.resolveValue = async (jenisId, legacyName = null, currentId = null) => {
  if ((jenisId == null || jenisId === '') && typeof legacyName === 'string') {
    const nama = legacyName.trim();
    if (nama) {
      const activeMatch = await JenisKegiatan.findOne({ where: { nama, is_active: true } });
      if (activeMatch) return { value: activeMatch };
      if (currentId != null) {
        const current = await JenisKegiatan.findByPk(currentId);
        if (current && current.nama === nama) return { value: current };
      }
    }
    return { error: 'Pilih jenis kegiatan dari data master' };
  }
  if (jenisId == null || jenisId === '') {
    return { error: 'Jenis kegiatan wajib dipilih' };
  }
  const id = Number(jenisId);
  if (!Number.isInteger(id) || id <= 0) return { error: 'Jenis kegiatan tidak valid' };
  const jenis = await JenisKegiatan.findOne({
    where: {
      id,
      ...(currentId != null && Number(currentId) === id ? {} : { is_active: true }),
    },
  });
  if (!jenis) return { error: 'Jenis kegiatan tidak ditemukan atau sudah tidak aktif' };
  return { value: jenis };
};
