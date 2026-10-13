const { Op } = require('sequelize');
const sequelize = require('../config/db');
const User = require('../models/User');
const Location = require('../models/Location');
const WorkAssignment = require('../models/WorkAssignment');
const Absensi = require('../models/Absensi');
const Notifikasi = require('../models/Notifikasi');

function validDate(value) {
  return typeof value === 'string' &&
    /^\d{4}-\d{2}-\d{2}$/.test(value) &&
    !Number.isNaN(Date.parse(`${value}T00:00:00Z`)) &&
    new Date(`${value}T00:00:00Z`).toISOString().slice(0, 10) === value;
}

function validTime(value) {
  return typeof value === 'string' && /^([01]\d|2[0-3]):[0-5]\d$/.test(value);
}

function includes() {
  return [
    { model: User, attributes: ['id', 'nama', 'jabatan'] },
    { model: Location, attributes: ['id', 'nama'] },
    { model: Absensi, as: 'absensi' },
  ];
}

async function validateAssignment(body, excludeId = null, transaction = null) {
  const { user_id: userId, location_id: locationId, tanggal, jam_mulai: start, jam_selesai: end } = body;
  if (!Number.isInteger(Number(userId)) || Number(userId) <= 0) {
    return { error: 'Karyawan wajib dipilih' };
  }
  if (!Number.isInteger(Number(locationId)) || Number(locationId) <= 0) {
    return { error: 'Lokasi kerja wajib dipilih' };
  }
  if (!validDate(tanggal)) return { error: 'Tanggal harus berformat YYYY-MM-DD' };
  if (!validTime(start) || !validTime(end) || start >= end) {
    return { error: 'Jam mulai dan selesai tidak valid; jam selesai harus setelah jam mulai' };
  }

  const user = await User.findOne({
    where: { id: Number(userId), role: 'karyawan', is_active: true },
    ...(transaction ? { transaction } : {}),
  });
  if (!user) return { error: 'Karyawan tidak ditemukan atau tidak aktif' };
  const location = await Location.findByPk(Number(locationId), transaction ? { transaction } : {});
  if (!location) return { error: 'Lokasi tidak ditemukan' };
  if (
    location.latitude == null ||
    location.longitude == null ||
    !Number.isInteger(Number(location.radius_meters)) ||
    Number(location.radius_meters) <= 0
  ) {
    return { error: 'Atur koordinat GPS dan radius lokasi sebelum membuat jadwal kerja' };
  }

  const where = {
    user_id: Number(userId),
    tanggal,
    jam_mulai: { [Op.lt]: `${end}:00` },
    jam_selesai: { [Op.gt]: `${start}:00` },
  };
  if (excludeId != null) where.id = { [Op.ne]: excludeId };
  if (await WorkAssignment.findOne({
    where,
    ...(transaction ? { transaction } : {}),
  })) {
    return { error: 'Jadwal karyawan bertabrakan dengan slot lain pada tanggal tersebut' };
  }
  return {
    value: {
      user_id: Number(userId),
      location_id: Number(locationId),
      tanggal,
      jam_mulai: `${start}:00`,
      jam_selesai: `${end}:00`,
    },
    user,
    location,
  };
}

async function buatNotifikasiJadwal(
  assignment,
  user,
  location,
  transaction,
  judul = 'Jadwal kerja baru',
) {
  await Notifikasi.create({
    user_id: user.id,
    tipe: 'absen',
    judul,
    pesan: `Anda dijadwalkan bekerja di ${location.nama} pada ${assignment.tanggal}, pukul ${assignment.jam_mulai.slice(0, 5)}–${assignment.jam_selesai.slice(0, 5)}.`,
    cta_text: 'Lihat jadwal',
    data: JSON.stringify({
      work_assignment_id: assignment.id,
      tabIndex: 0,
    }),
    is_read: false,
  }, { transaction });
}

async function buatNotifikasiPembatalan(assignment, user, location, transaction) {
  await Notifikasi.create({
    user_id: user.id,
    tipe: 'absen',
    judul: 'Jadwal kerja dibatalkan',
    pesan: `Jadwal kerja Anda di ${location.nama} pada ${assignment.tanggal} pukul ${assignment.jam_mulai.slice(0, 5)}–${assignment.jam_selesai.slice(0, 5)} telah dibatalkan.`,
    cta_text: 'Lihat jadwal',
    data: JSON.stringify({
      work_assignment_id: assignment.id,
      tabIndex: 0,
      cancelled: true,
    }),
    is_read: false,
  }, { transaction });
}

exports.daftarTanggal = async (req, res) => {
  try {
    const { tanggal } = req.query;
    if (!validDate(tanggal)) {
      return res.status(400).json({ message: 'Tanggal harus berformat YYYY-MM-DD' });
    }
    const data = await WorkAssignment.findAll({
      where: { tanggal },
      include: includes(),
      order: [['jam_mulai', 'ASC'], ['id', 'ASC']],
    });
    res.json(data);
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat jadwal kerja', error: err.message });
  }
};

exports.tambah = async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const validated = await validateAssignment(req.body, null, transaction);
    if (validated.error) {
      await transaction.rollback();
      return res.status(400).json({ message: validated.error });
    }
    const data = await WorkAssignment.create(validated.value, { transaction });
    await buatNotifikasiJadwal(
      data,
      validated.user,
      validated.location,
      transaction,
    );
    await transaction.commit();
    const created = await WorkAssignment.findByPk(data.id, { include: includes() });
    res.status(201).json({ message: 'Jadwal kerja berhasil ditambahkan', data: created });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    res.status(500).json({ message: 'Gagal menambahkan jadwal kerja', error: err.message });
  }
};

exports.tambahBanyak = async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const { user_ids: userIds } = req.body;
    if (
      !Array.isArray(userIds) ||
      userIds.length === 0 ||
      userIds.length > 100 ||
      userIds.some((id) => !Number.isInteger(id) || id <= 0) ||
      new Set(userIds).size !== userIds.length
    ) {
      await transaction.rollback();
      return res.status(400).json({
        message: 'Pilih satu atau lebih karyawan yang valid tanpa duplikasi',
      });
    }

    const createdIds = [];
    for (const userId of userIds) {
      const validated = await validateAssignment({
        ...req.body,
        user_id: userId,
      }, null, transaction);
      if (validated.error) {
        await transaction.rollback();
        return res.status(400).json({
          message: `${validated.user?.nama || `Karyawan ${userId}`}: ${validated.error}`,
        });
      }
      const assignment = await WorkAssignment.create(validated.value, { transaction });
      await buatNotifikasiJadwal(
        assignment,
        validated.user,
        validated.location,
        transaction,
      );
      createdIds.push(assignment.id);
    }

    await transaction.commit();
    const data = await WorkAssignment.findAll({
      where: { id: createdIds },
      include: includes(),
      order: [['jam_mulai', 'ASC'], ['id', 'ASC']],
    });
    res.status(201).json({
      message: `Jadwal kerja berhasil ditambahkan untuk ${data.length} karyawan`,
      data,
    });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    res.status(500).json({ message: 'Gagal menambahkan jadwal kerja', error: err.message });
  }
};

exports.perbarui = async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const schedule = await WorkAssignment.findByPk(req.params.id, {
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!schedule) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Jadwal kerja tidak ditemukan' });
    }
    if (await Absensi.findOne({ where: { work_assignment_id: schedule.id }, transaction })) {
      await transaction.rollback();
      return res.status(409).json({
        message: 'Jadwal tidak dapat diubah karena absensi pada slot ini sudah tercatat',
      });
    }
    const validated = await validateAssignment(req.body, schedule.id, transaction);
    if (validated.error) {
      await transaction.rollback();
      return res.status(400).json({ message: validated.error });
    }
    const employeeChanged = Number(schedule.user_id) !== validated.value.user_id;
    if (employeeChanged) {
      const previousUser = await User.findByPk(schedule.user_id, { transaction });
      const previousLocation = await Location.findByPk(schedule.location_id, { transaction });
      await buatNotifikasiPembatalan(
        schedule,
        previousUser,
        previousLocation,
        transaction,
      );
    }
    await schedule.update(validated.value, { transaction });
    await buatNotifikasiJadwal(
      schedule,
      validated.user,
      validated.location,
      transaction,
      employeeChanged ? 'Jadwal kerja baru' : 'Jadwal kerja diperbarui',
    );
    await transaction.commit();
    const data = await WorkAssignment.findByPk(schedule.id, { include: includes() });
    res.json({ message: 'Jadwal kerja berhasil diperbarui', data });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    res.status(500).json({ message: 'Gagal memperbarui jadwal kerja', error: err.message });
  }
};

exports.hapus = async (req, res) => {
  const transaction = await sequelize.transaction();
  try {
    const schedule = await WorkAssignment.findByPk(req.params.id, {
      include: [
        { model: User, attributes: ['id', 'nama'] },
        { model: Location, attributes: ['id', 'nama'] },
      ],
      transaction,
      lock: transaction.LOCK.UPDATE,
    });
    if (!schedule) {
      await transaction.rollback();
      return res.status(404).json({ message: 'Jadwal kerja tidak ditemukan' });
    }
    if (await Absensi.findOne({
      where: { work_assignment_id: schedule.id },
      transaction,
    })) {
      await transaction.rollback();
      return res.status(409).json({
        message: 'Jadwal tidak dapat dihapus karena absensi pada slot ini sudah tercatat',
      });
    }
    await buatNotifikasiPembatalan(
      schedule,
      schedule.User,
      schedule.Location,
      transaction,
    );
    await schedule.destroy({ transaction });
    await transaction.commit();
    res.json({ message: 'Jadwal kerja berhasil dihapus' });
  } catch (err) {
    if (!transaction.finished) await transaction.rollback();
    res.status(500).json({ message: 'Gagal menghapus jadwal kerja', error: err.message });
  }
};

exports.jadwalSayaHariIni = async (req, res) => {
  try {
    const now = new Date();
    const parts = new Intl.DateTimeFormat('en-GB', {
      timeZone: 'Asia/Jakarta',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hourCycle: 'h23',
    }).formatToParts(now);
    const value = Object.fromEntries(parts.map(({ type, value: part }) => [type, part]));
    const tanggal = `${value.year}-${value.month}-${value.day}`;
    const jam = `${value.hour}:${value.minute}:${value.second}`;
    const currentMinute = jam.slice(0, 5);
    const assignments = await WorkAssignment.findAll({
      where: { user_id: req.user.id, tanggal },
      include: [
        { model: Location, attributes: ['id', 'nama'] },
        { model: Absensi, as: 'absensi' },
      ],
      order: [['jam_mulai', 'ASC'], ['id', 'ASC']],
    });
    const slots = assignments.map((assignment) => {
      const data = assignment.toJSON();
      const start = data.jam_mulai.slice(0, 5);
      const end = data.jam_selesai.slice(0, 5);
      const clockInOpen = currentMinute >= shiftMinutes(start, -30);
      const attendanceRecords = Array.isArray(data.absensi)
        ? data.absensi
        : data.absensi
          ? [data.absensi]
          : [];
      const attendance = attendanceRecords.find((record) => record.jam_pulang)
        || attendanceRecords.find((record) => record.jam_masuk)
        || attendanceRecords[0];
      let status;
      let action = null;
      let message;
      if (attendance && attendance.jam_pulang) {
        status = 'selesai';
        message = 'Absensi slot ini sudah selesai.';
      } else if (attendance && attendance.jam_masuk) {
        status = 'menunggu_pulang';
        action = currentMinute >= end ? 'pulang' : null;
        message = action
          ? 'Waktu slot selesai. Silakan absen pulang.'
          : `Absen pulang tersedia setelah pukul ${end}.`;
      } else if (currentMinute > end) {
        status = 'terlewat';
        message = 'Slot terlewat tanpa absen masuk. Hubungi admin.';
      } else if (clockInOpen) {
        status = currentMinute > start ? 'terlambat' : 'bisa_masuk';
        action = 'masuk';
        message = status === 'terlambat'
          ? 'Absen masuk sekarang; keterlambatan akan tercatat.'
          : 'Anda dapat melakukan absen masuk.';
      } else {
        status = 'belum_waktunya';
        message = `Absen masuk tersedia pukul ${shiftMinutes(start, -30)}.`;
      }
      return { ...data, status, action, message };
    });
    res.json({ tanggal, sekarang: jam, slots });
  } catch (err) {
    res.status(500).json({ message: 'Gagal memuat jadwal kerja hari ini', error: err.message });
  }
};

function shiftMinutes(time, delta) {
  const [hours, minutes] = time.split(':').map(Number);
  const total = Math.max(0, hours * 60 + minutes + delta);
  return `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
}
