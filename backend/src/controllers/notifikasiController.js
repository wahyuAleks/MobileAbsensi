const Notifikasi = require('../models/Notifikasi');
const User = require('../models/User');
const { emitToUser } = require('../services/realtime');

// Helper untuk membuat notifikasi baru dari controller lain
exports.buatNotifikasi = async ({ user_id, tipe, judul, pesan, cta_text, data }) => {
  try {
    const dataStr = data ? (typeof data === 'string' ? data : JSON.stringify(data)) : null;
    const notifikasi = await Notifikasi.create({
      user_id,
      tipe: tipe || 'info',
      judul,
      pesan,
      cta_text: cta_text || null,
      data: dataStr,
      is_read: false,
    });
    emitToUser(user_id, 'notifikasi_baru', {
      id: notifikasi.id,
      user_id: notifikasi.user_id,
      tipe: notifikasi.tipe,
      judul: notifikasi.judul,
      pesan: notifikasi.pesan,
      cta_text: notifikasi.cta_text,
      data: dataStr,
      is_read: notifikasi.is_read,
      createdAt: notifikasi.createdAt,
    });
    return notifikasi;
  } catch (err) {
    console.error('Gagal membuat notifikasi:', err.message);
    return null;
  }
};

// AMBIL SEMUA NOTIFIKASI SAYA (Karyawan / Admin yang login)
exports.getNotifikasi = async (req, res) => {
  try {
    const notifikasiList = await Notifikasi.findAll({
      where: { user_id: req.user.id },
      order: [['createdAt', 'DESC']],
      limit: 50,
    });

    const formatted = notifikasiList.map((n) => {
      let parsedData = null;
      if (n.data) {
        try {
          parsedData = JSON.parse(n.data);
        } catch (_) {
          parsedData = n.data;
        }
      }
      return {
        id: n.id,
        user_id: n.user_id,
        tipe: n.tipe,
        judul: n.judul,
        pesan: n.pesan,
        cta_text: n.cta_text,
        data: parsedData,
        is_read: n.is_read,
        createdAt: n.createdAt,
        updatedAt: n.updatedAt,
      };
    });

    res.json(formatted);
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// TANDAI SATU NOTIFIKASI SEBAGAI DIBACA
exports.tandaiDibaca = async (req, res) => {
  try {
    const notif = await Notifikasi.findOne({
      where: {
        id: req.params.id,
        user_id: req.user.id,
      },
    });

    if (!notif) {
      return res.status(404).json({ message: 'Notifikasi tidak ditemukan' });
    }

    notif.is_read = true;
    await notif.save();

    res.json({ message: 'Notifikasi berhasil ditandai telah dibaca', data: notif });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};

// TANDAI SEMUA NOTIFIKASI SAYA SEBAGAI DIBACA
exports.tandaiSemuaDibaca = async (req, res) => {
  try {
    await Notifikasi.update(
      { is_read: true },
      { where: { user_id: req.user.id, is_read: false } }
    );

    res.json({ message: 'Semua notifikasi berhasil ditandai telah dibaca' });
  } catch (err) {
    res.status(500).json({ message: 'Terjadi kesalahan server', error: err.message });
  }
};
