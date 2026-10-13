const Laporan = require('../models/Laporan');
const User = require('../models/User');
const { Op } = require('sequelize');

// FORM LAPORAN -> SUBMIT
exports.submitLaporan = async (req, res) => {
  try {
    const {
      tanggal,
      judul,
      isi_laporan,
      jenis_kegiatan,
      lokasi,
      unit_drone,
      luas_area,
      uraian_pekerjaan,
      hasil,
      rencana_esok,
      status,
    } = req.body;

    if (!tanggal || !judul) {
      return res.status(400).json({ message: 'Tanggal dan judul laporan wajib diisi' });
    }

    const isi = (isi_laporan || uraian_pekerjaan || '').trim() || 'Laporan kegiatan telah dicatat.';

    const laporan = await Laporan.create({
      user_id: req.user.id,
      tanggal,
      judul,
      isi_laporan: isi,
      jenis_kegiatan: jenis_kegiatan || judul,
      lokasi: lokasi || 'Sawah Blok A — Karawang',
      unit_drone: unit_drone || 'DA-001 (DJI Agras T40)',
      luas_area: luas_area || '8 Ha',
      uraian_pekerjaan: uraian_pekerjaan || isi,
      hasil: hasil || 'Penyemprotan 100% selesai. Tidak ada kendala signifikan.',
      rencana_esok: rencana_esok || 'Melanjutkan operasional sesuai jadwal.',
      status: status || 'Terkirim',
      lampiran: req.file ? `/uploads/laporan/${req.file.filename}` : null,
    });

    res.status(201).json({ message: 'Laporan berhasil dikirim', data: laporan });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

exports.laporanSaya = async (req, res) => {
  try {
    const data = await Laporan.findAll({
      where: { user_id: req.user.id },
      order: [['tanggal', 'DESC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// REKAP LAPORAN untuk admin
exports.rekapLaporan = async (req, res) => {
  try {
    const {
      tanggal,
      tanggal_start: tanggalStart,
      tanggal_end: tanggalEnd,
      user_id: userId,
      lokasi,
    } = req.query;
    const where = {};

    if (userId !== undefined && userId !== '' && userId !== '-1') {
      const parsedUserId = Number(userId);
      if (!Number.isSafeInteger(parsedUserId) || parsedUserId < 1) {
        return res.status(400).json({ message: 'Filter karyawan tidak valid' });
      }
      where.user_id = parsedUserId;
    }

    if (
      lokasi &&
      typeof lokasi === 'string' &&
      lokasi.trim() !== '' &&
      !['semua', 'all', 'semua proyek', 'semua lokasi'].includes(lokasi.trim().toLowerCase())
    ) {
      where.lokasi = { [Op.like]: `%${lokasi.trim()}%` };
    }

    if (tanggalStart || tanggalEnd) {
      if (!tanggalStart || !tanggalEnd) {
        return res.status(400).json({
          message: 'Tanggal mulai dan tanggal akhir harus diisi bersama',
        });
      }
      if (!isValidDate(tanggalStart) || !isValidDate(tanggalEnd)) {
        return res.status(400).json({
          message: 'Format tanggal harus YYYY-MM-DD',
        });
      }
      if (tanggalStart > tanggalEnd) {
        return res.status(400).json({
          message: 'Tanggal mulai tidak boleh melewati tanggal akhir',
        });
      }
      where.tanggal = { [Op.between]: [tanggalStart, tanggalEnd] };
    } else if (tanggal) {
      if (!isValidDate(tanggal)) {
        return res.status(400).json({ message: 'Format tanggal harus YYYY-MM-DD' });
      }
      where.tanggal = tanggal;
    }

    const data = await Laporan.findAll({
      where,
      include: [{ model: User, attributes: ['id', 'nama', 'jabatan'] }],
      order: [['tanggal', 'DESC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// REKAP CHART untuk tren grafik luas area di Dashboard admin
exports.rekapChart = async (req, res) => {
  try {
    const {
      user_id: userId,
      lokasi,
      tanggal_start: tanggalStart,
      tanggal_end: tanggalEnd,
    } = req.query;
    const where = {};

    if (userId !== undefined && userId !== '' && userId !== '-1') {
      const parsedUserId = Number(userId);
      if (Number.isSafeInteger(parsedUserId) && parsedUserId > 0) {
        where.user_id = parsedUserId;
      }
    }

    if (
      lokasi &&
      typeof lokasi === 'string' &&
      lokasi.trim() !== '' &&
      !['semua', 'all', 'semua proyek', 'semua lokasi'].includes(lokasi.trim().toLowerCase())
    ) {
      where.lokasi = { [Op.like]: `%${lokasi.trim()}%` };
    }

    if (tanggalStart || tanggalEnd) {
      if (tanggalStart && tanggalEnd && isValidDate(tanggalStart) && isValidDate(tanggalEnd)) {
        where.tanggal = { [Op.between]: [tanggalStart, tanggalEnd] };
      }
    }

    where.status = { [Op.ne]: 'Draft' };

    const data = await Laporan.findAll({
      where,
      include: [{ model: User, attributes: ['id', 'nama', 'jabatan'] }],
      order: [['tanggal', 'ASC']],
    });

    const parseHa = (val) => {
      if (!val) return 0;
      const s = String(val).replace(/[^0-9.,]/g, '').replace(',', '.');
      return parseFloat(s) || 0;
    };

    const grouped = {};
    for (const item of data) {
      const tgl = item.tanggal;
      const ha = parseHa(item.luas_area);
      if (!grouped[tgl]) {
        grouped[tgl] = {
          tanggal: tgl,
          total_hektar: 0,
          lokasi: item.lokasi || (lokasi || 'Semua Proyek'),
          nama_karyawan: item.User ? item.User.nama : '',
          jumlah_laporan: 0,
        };
      }
      grouped[tgl].total_hektar += ha;
      grouped[tgl].jumlah_laporan += 1;
    }

    const result = Object.values(grouped).map((g) => ({
      tanggal: g.tanggal,
      total_hektar: Number(g.total_hektar.toFixed(2)),
      lokasi: g.lokasi,
      nama_karyawan: g.nama_karyawan,
      jumlah_laporan: g.jumlah_laporan,
    }));

    res.json(result);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

function isValidDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }
  const parsed = new Date(`${value}T00:00:00Z`);
  return !Number.isNaN(parsed.getTime()) && parsed.toISOString().slice(0, 10) === value;
}
