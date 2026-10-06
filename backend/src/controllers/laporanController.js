const Laporan = require('../models/Laporan');
const User = require('../models/User');

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

    const reportStatus = String(status || 'Terkirim').toLowerCase();
    if (!['draft', 'terkirim'].includes(reportStatus)) {
      return res.status(400).json({ message: 'Status laporan tidak valid' });
    }

    if (!tanggal) {
      return res.status(400).json({ message: 'Tanggal laporan wajib diisi' });
    }

    const title = typeof judul === 'string' ? judul.trim() : '';
    const isiInput = typeof isi_laporan === 'string'
      ? isi_laporan.trim()
      : typeof uraian_pekerjaan === 'string'
        ? uraian_pekerjaan.trim()
        : '';
    if (reportStatus === 'terkirim' && (!title || !isiInput)) {
      return res.status(400).json({ message: 'Judul dan uraian pekerjaan wajib diisi' });
    }
    const isi = reportStatus === 'draft' ? isiInput : isiInput || 'Laporan kegiatan telah dicatat.';

    const laporan = await Laporan.create({
      user_id: req.user.id,
      tanggal,
      judul: title || 'Draft tanpa judul',
      isi_laporan: isi,
      jenis_kegiatan: jenis_kegiatan || title || 'Penyemprotan Pestisida',
      lokasi: lokasi || '',
      unit_drone: unit_drone || '',
      luas_area: luas_area || '',
      uraian_pekerjaan: uraian_pekerjaan || isi,
      hasil: hasil || '',
      rencana_esok: rencana_esok || '',
      status: reportStatus === 'draft' ? 'Draft' : 'Terkirim',
      lampiran: req.file ? `/uploads/laporan/${req.file.filename}` : null,
    });

    res.status(201).json({
      message: reportStatus === 'draft' ? 'Draft laporan berhasil disimpan' : 'Laporan berhasil dikirim',
      data: laporan,
    });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

exports.updateDraft = async (req, res) => {
  try {
    const laporan = await Laporan.findOne({
      where: { id: req.params.id, user_id: req.user.id },
    });
    if (!laporan) {
      return res.status(404).json({ message: 'Draft laporan tidak ditemukan' });
    }
    if (String(laporan.status).toLowerCase() !== 'draft') {
      return res.status(409).json({ message: 'Hanya draft yang dapat diubah' });
    }

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
    } = req.body;
    const title = typeof judul === 'string' ? judul.trim() : laporan.judul;
    const body = typeof isi_laporan === 'string'
      ? isi_laporan.trim()
      : typeof uraian_pekerjaan === 'string'
        ? uraian_pekerjaan.trim()
        : laporan.isi_laporan;

    await laporan.update({
      tanggal: tanggal || laporan.tanggal,
      judul: title || 'Draft tanpa judul',
      isi_laporan: body,
      jenis_kegiatan: jenis_kegiatan ?? laporan.jenis_kegiatan,
      lokasi: lokasi ?? laporan.lokasi,
      unit_drone: unit_drone ?? laporan.unit_drone,
      luas_area: luas_area ?? laporan.luas_area,
      uraian_pekerjaan: uraian_pekerjaan ?? body,
      hasil: hasil ?? laporan.hasil,
      rencana_esok: rencana_esok ?? laporan.rencana_esok,
    });

    res.json({ message: 'Draft laporan berhasil diperbarui', data: laporan });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

exports.kirimDraft = async (req, res) => {
  try {
    const laporan = await Laporan.findOne({
      where: { id: req.params.id, user_id: req.user.id },
    });
    if (!laporan) {
      return res.status(404).json({ message: 'Draft laporan tidak ditemukan' });
    }
    if (String(laporan.status).toLowerCase() !== 'draft') {
      return res.status(409).json({ message: 'Laporan ini bukan draft' });
    }

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
    } = req.body;
    const title = typeof judul === 'string' ? judul.trim() : laporan.judul;
    const body = typeof isi_laporan === 'string'
      ? isi_laporan.trim()
      : typeof uraian_pekerjaan === 'string'
        ? uraian_pekerjaan.trim()
        : laporan.isi_laporan;

    if (!title || title === 'Draft tanpa judul' || !body || !tanggal) {
      return res.status(400).json({ message: 'Tanggal, judul, dan uraian pekerjaan wajib diisi' });
    }

    await laporan.update({
      tanggal,
      judul: title,
      isi_laporan: body,
      jenis_kegiatan: jenis_kegiatan ?? laporan.jenis_kegiatan,
      lokasi: lokasi ?? laporan.lokasi,
      unit_drone: unit_drone ?? laporan.unit_drone,
      luas_area: luas_area ?? laporan.luas_area,
      uraian_pekerjaan: uraian_pekerjaan ?? body,
      hasil: hasil ?? laporan.hasil,
      rencana_esok: rencana_esok ?? laporan.rencana_esok,
      status: 'Terkirim',
    });

    res.json({ message: 'Laporan berhasil dikirim', data: laporan });
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
    const data = await Laporan.findAll({
      include: [{ model: User, attributes: ['id', 'nama', 'jabatan'] }],
      order: [['tanggal', 'DESC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};
