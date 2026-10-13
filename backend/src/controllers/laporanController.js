const Laporan = require('../models/Laporan');
const User = require('../models/User');
const { Op } = require('sequelize');
const jenisKegiatanController = require('./jenisKegiatanController');

function getLampiranPaths(req, existingLampiran = null) {
  const files = req.files || (req.file ? [req.file] : []);
  if (files && files.length > 0) {
    const paths = files.map(f => `/uploads/laporan/${f.filename}`);
    return paths.length === 1 ? paths[0] : JSON.stringify(paths);
  }
  return existingLampiran;
}

// FORM LAPORAN -> SUBMIT
exports.submitLaporan = async (req, res) => {
  try {
    const {
      tanggal,
      judul,
      isi_laporan,
      jenis_kegiatan,
      jenis_kegiatan_id,
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
    const resolvedType = await jenisKegiatanController.resolveValue(
      jenis_kegiatan_id,
      jenis_kegiatan,
    );
    if (resolvedType.error) {
      return res.status(400).json({ message: resolvedType.error });
    }
    const isi = reportStatus === 'draft' ? isiInput : isiInput || 'Laporan kegiatan telah dicatat.';

    const laporan = await Laporan.create({
      user_id: req.user.id,
      tanggal,
      judul: title || 'Draft tanpa judul',
      isi_laporan: isi,
      jenis_kegiatan_id: resolvedType.value.id,
      jenis_kegiatan: resolvedType.value.nama,
      lokasi: lokasi || '',
      unit_drone: unit_drone || '',
      luas_area: luas_area || '',
      uraian_pekerjaan: uraian_pekerjaan || isi,
      hasil: hasil || '',
      rencana_esok: rencana_esok || '',
      status: reportStatus === 'draft' ? 'Draft' : 'Terkirim',
      lampiran: getLampiranPaths(req, null),
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
      jenis_kegiatan_id,
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

    const resolvedType = (jenis_kegiatan_id != null || jenis_kegiatan != null)
      ? await jenisKegiatanController.resolveValue(
        jenis_kegiatan_id,
        jenis_kegiatan,
        laporan.jenis_kegiatan_id,
      )
      : { value: null };
    if (resolvedType.error) {
      return res.status(400).json({ message: resolvedType.error });
    }

    await laporan.update({
      tanggal: tanggal || laporan.tanggal,
      judul: title || 'Draft tanpa judul',
      isi_laporan: body,
      ...(resolvedType.value
        ? {
          jenis_kegiatan_id: resolvedType.value.id,
          jenis_kegiatan: resolvedType.value.nama,
        }
        : {}),
      lokasi: lokasi ?? laporan.lokasi,
      unit_drone: unit_drone ?? laporan.unit_drone,
      luas_area: luas_area ?? laporan.luas_area,
      uraian_pekerjaan: uraian_pekerjaan ?? body,
      hasil: hasil ?? laporan.hasil,
      rencana_esok: rencana_esok ?? laporan.rencana_esok,
      lampiran: getLampiranPaths(req, laporan.lampiran),
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
      jenis_kegiatan_id,
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

    const resolvedType = (jenis_kegiatan_id != null || jenis_kegiatan != null)
      ? await jenisKegiatanController.resolveValue(
        jenis_kegiatan_id,
        jenis_kegiatan,
        laporan.jenis_kegiatan_id,
      )
      : { value: null };
    if (resolvedType.error) {
      return res.status(400).json({ message: resolvedType.error });
    }

    await laporan.update({
      tanggal,
      judul: title,
      isi_laporan: body,
      ...(resolvedType.value
        ? {
          jenis_kegiatan_id: resolvedType.value.id,
          jenis_kegiatan: resolvedType.value.nama,
        }
        : {}),
      lokasi: lokasi ?? laporan.lokasi,
      unit_drone: unit_drone ?? laporan.unit_drone,
      luas_area: luas_area ?? laporan.luas_area,
      uraian_pekerjaan: uraian_pekerjaan ?? body,
      hasil: hasil ?? laporan.hasil,
      rencana_esok: rencana_esok ?? laporan.rencana_esok,
      lampiran: getLampiranPaths(req, laporan.lampiran),
      status: 'Terkirim',
    });

    res.json({ message: 'Laporan berhasil dikirim', data: laporan });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

exports.editLaporanAdmin = async (req, res) => {
  try {
    const laporan = await Laporan.findByPk(req.params.id);
    if (!laporan) {
      return res.status(404).json({ message: 'Laporan tidak ditemukan' });
    }

    const fields = [
      'tanggal',
      'judul',
      'isi_laporan',
      'lokasi',
      'unit_drone',
      'luas_area',
      'uraian_pekerjaan',
      'hasil',
      'rencana_esok',
    ];
    const updates = {};
    for (const field of fields) {
      if (typeof req.body[field] === 'string') {
        updates[field] = req.body[field].trim();
      }
    }

    if (
      req.body.jenis_kegiatan_id != null ||
      (typeof req.body.jenis_kegiatan === 'string' &&
        req.body.jenis_kegiatan.trim() !== (laporan.jenis_kegiatan ?? ''))
    ) {
      const resolvedType = await jenisKegiatanController.resolveValue(
        req.body.jenis_kegiatan_id,
        req.body.jenis_kegiatan,
        laporan.jenis_kegiatan_id,
      );
      if (resolvedType.error) {
        return res.status(400).json({ message: resolvedType.error });
      }
      updates.jenis_kegiatan_id = resolvedType.value.id;
      updates.jenis_kegiatan = resolvedType.value.nama;
    }

    const judul = updates.judul ?? laporan.judul;
    const uraian = updates.uraian_pekerjaan ??
      updates.isi_laporan ??
      laporan.uraian_pekerjaan ??
      laporan.isi_laporan;
    if (!judul || !uraian) {
      return res.status(400).json({
        message: 'Judul dan uraian pekerjaan wajib diisi',
      });
    }

    updates.judul = judul;
    updates.isi_laporan = updates.isi_laporan ?? uraian;
    updates.uraian_pekerjaan = uraian;
    if ((req.files && req.files.length) || req.file) {
      updates.lampiran = getLampiranPaths(req, laporan.lampiran);
    }

    await laporan.update(updates);
    res.json({ message: 'Laporan berhasil diperbarui admin', data: laporan });
  } catch (err) {
    res.status(500).json({
      message: 'Gagal memperbarui laporan',
      error: err.message,
    });
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
