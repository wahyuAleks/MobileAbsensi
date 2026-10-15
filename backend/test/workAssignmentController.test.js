const test = require('node:test');
const assert = require('node:assert/strict');
const { Op } = require('sequelize');
const sequelize = require('../src/config/db');
const User = require('../src/models/User');
const Location = require('../src/models/Location');
const WorkAssignment = require('../src/models/WorkAssignment');
const Notifikasi = require('../src/models/Notifikasi');
const controller = require('../src/controllers/workAssignmentController');

function responseMock() {
  return {
    statusCode: 200,
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    json(value) {
      this.body = value;
      return this;
    },
  };
}

function mockTransaction() {
  return {
    finished: false,
    committed: false,
    rolledBack: false,
    async commit() {
      this.finished = 'commit';
      this.committed = true;
    },
    async rollback() {
      this.finished = 'rollback';
      this.rolledBack = true;
    },
  };
}

function freezeDate(t, isoDate) {
  const OriginalDate = global.Date;
  const timestamp = new OriginalDate(isoDate).valueOf();
  global.Date = class extends OriginalDate {
    constructor(...args) {
      super(...(args.length === 0 ? [isoDate] : args));
    }

    static now() {
      return timestamp;
    }
  };
  t.after(() => {
    global.Date = OriginalDate;
  });
}

test('bulk assignment creates one schedule and in-app notification per employee', async (t) => {
  const originals = {
    transaction: sequelize.transaction,
    userFindOne: User.findOne,
    locationFindByPk: Location.findByPk,
    assignmentFindOne: WorkAssignment.findOne,
    assignmentCreate: WorkAssignment.create,
    assignmentFindAll: WorkAssignment.findAll,
    notificationCreate: Notifikasi.create,
  };
  const transaction = mockTransaction();
  const created = [];
  const notifications = [];

  t.after(() => {
    sequelize.transaction = originals.transaction;
    User.findOne = originals.userFindOne;
    Location.findByPk = originals.locationFindByPk;
    WorkAssignment.findOne = originals.assignmentFindOne;
    WorkAssignment.create = originals.assignmentCreate;
    WorkAssignment.findAll = originals.assignmentFindAll;
    Notifikasi.create = originals.notificationCreate;
  });

  sequelize.transaction = async () => transaction;
  User.findOne = async ({ where }) => ({ id: where.id, nama: `Karyawan ${where.id}` });
  Location.findByPk = async (id) => ({
    id,
    nama: 'Lokasi Uji',
    latitude: -8.1,
    longitude: 114.2,
    radius_meters: 250,
  });
  WorkAssignment.findOne = async () => null;
  WorkAssignment.create = async (values) => {
    const assignment = { id: created.length + 1, ...values };
    created.push(assignment);
    return assignment;
  };
  WorkAssignment.findAll = async () => created;
  Notifikasi.create = async (values) => {
    notifications.push(values);
    return values;
  };

  const res = responseMock();
  await controller.tambahBanyak({
    body: {
      user_ids: [11, 12],
      location_id: 4,
      tanggal: '2026-10-10',
      jam_mulai: '08:00',
      jam_selesai: '17:00',
    },
  }, res);

  assert.equal(res.statusCode, 201);
  assert.equal(res.body.data.length, 2);
  assert.deepEqual(created.map((item) => item.user_id), [11, 12]);
  assert.deepEqual(notifications.map((item) => item.user_id), [11, 12]);
  assert.equal(notifications[0].tipe, 'absen');
  assert.equal(transaction.committed, true);
});

test('bulk assignment rejects empty or duplicate employee selections', async (t) => {
  const original = sequelize.transaction;
  t.after(() => {
    sequelize.transaction = original;
  });
  const transactions = [];
  sequelize.transaction = async () => {
    const transaction = mockTransaction();
    transactions.push(transaction);
    return transaction;
  };

  for (const userIds of [[], [11, 11]]) {
    const res = responseMock();
    await controller.tambahBanyak({
      body: {
        user_ids: userIds,
        location_id: 4,
        tanggal: '2026-10-10',
        jam_mulai: '08:00',
        jam_selesai: '17:00',
      },
    }, res);
    assert.equal(res.statusCode, 400);
  }

  assert.equal(transactions.every((transaction) => transaction.rolledBack), true);
});

test('bulk assignment rolls back all schedules when any employee is invalid', async (t) => {
  const originals = {
    transaction: sequelize.transaction,
    userFindOne: User.findOne,
    locationFindByPk: Location.findByPk,
    assignmentFindOne: WorkAssignment.findOne,
    assignmentCreate: WorkAssignment.create,
    notificationCreate: Notifikasi.create,
  };
  const transaction = mockTransaction();
  const created = [];
  const notifications = [];

  t.after(() => {
    sequelize.transaction = originals.transaction;
    User.findOne = originals.userFindOne;
    Location.findByPk = originals.locationFindByPk;
    WorkAssignment.findOne = originals.assignmentFindOne;
    WorkAssignment.create = originals.assignmentCreate;
    Notifikasi.create = originals.notificationCreate;
  });

  sequelize.transaction = async () => transaction;
  User.findOne = async ({ where }) =>
    where.id === 11 ? { id: 11, nama: 'Karyawan 11' } : null;
  Location.findByPk = async (id) => ({
    id,
    nama: 'Lokasi Uji',
    latitude: -8.1,
    longitude: 114.2,
    radius_meters: 250,
  });
  WorkAssignment.findOne = async () => null;
  WorkAssignment.create = async (values) => {
    const assignment = { id: created.length + 1, ...values };
    created.push(assignment);
    return assignment;
  };
  Notifikasi.create = async (values) => {
    notifications.push(values);
    return values;
  };

  const res = responseMock();
  await controller.tambahBanyak({
    body: {
      user_ids: [11, 12],
      location_id: 4,
      tanggal: '2026-10-10',
      jam_mulai: '08:00',
      jam_selesai: '17:00',
    },
  }, res);

  assert.equal(res.statusCode, 400);
  assert.equal(created.length, 1);
  assert.equal(notifications.length, 1);
  assert.equal(transaction.rolledBack, true);
  assert.equal(transaction.committed, false);
});

test('today schedule keeps a checked-in assignment eligible for check-out after its end time', async (t) => {
  freezeDate(t, '2026-10-10T10:00:00.000Z');
  const originalFindAll = WorkAssignment.findAll;
  t.after(() => {
    WorkAssignment.findAll = originalFindAll;
  });

  WorkAssignment.findAll = async () => [{
    toJSON: () => ({
      id: 21,
      jam_mulai: '08:00:00',
      jam_selesai: '09:00:00',
      absensi: [{ jam_masuk: '08:05:00', jam_pulang: null }],
    }),
  }];

  const res = responseMock();
  await controller.jadwalSayaHariIni({ user: { id: 11 } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.slots[0].status, 'menunggu_pulang');
  assert.equal(res.body.slots[0].action, 'pulang');
});

test('today schedule marks an assignment complete when its attendance record is in an array', async (t) => {
  freezeDate(t, '2026-10-10T10:00:00.000Z');
  const originalFindAll = WorkAssignment.findAll;
  t.after(() => {
    WorkAssignment.findAll = originalFindAll;
  });

  WorkAssignment.findAll = async () => [{
    toJSON: () => ({
      id: 22,
      jam_mulai: '08:00:00',
      jam_selesai: '09:00:00',
      absensi: [{ jam_masuk: '08:05:00', jam_pulang: '09:10:00' }],
    }),
  }];

  const res = responseMock();
  await controller.jadwalSayaHariIni({ user: { id: 11 } }, res);

  assert.equal(res.statusCode, 200);
  assert.equal(res.body.slots[0].status, 'selesai');
  assert.equal(res.body.slots[0].action, null);
});

test('non-overlapping slots for the same employee on the same date are allowed', async (t) => {
  const originals = {
    transaction: sequelize.transaction,
    userFindOne: User.findOne,
    locationFindByPk: Location.findByPk,
    assignmentFindOne: WorkAssignment.findOne,
    assignmentCreate: WorkAssignment.create,
    assignmentFindByPk: WorkAssignment.findByPk,
    notificationCreate: Notifikasi.create,
  };
  const transaction = mockTransaction();
  const existingSlots = [{
    id: 99,
    user_id: 11,
    tanggal: '2026-10-15',
    jam_mulai: '08:00:00',
    jam_selesai: '12:00:00',
    Location: { id: 1, nama: 'Bandung' },
  }];

  t.after(() => {
    sequelize.transaction = originals.transaction;
    User.findOne = originals.userFindOne;
    Location.findByPk = originals.locationFindByPk;
    WorkAssignment.findOne = originals.assignmentFindOne;
    WorkAssignment.create = originals.assignmentCreate;
    WorkAssignment.findByPk = originals.assignmentFindByPk;
    Notifikasi.create = originals.notificationCreate;
  });

  sequelize.transaction = async () => transaction;
  User.findOne = async ({ where }) => ({ id: where.id, nama: `Karyawan ${where.id}` });
  Location.findByPk = async (id) => ({
    id,
    nama: id === 2 ? 'Banyuwangi' : 'Bandung',
    latitude: -8.1,
    longitude: 114.2,
    radius_meters: 250,
  });
  // Simulate overlap check: new slot 14:00-17:00 should NOT overlap with 08:00-12:00
  WorkAssignment.findOne = async ({ where }) => {
    const queryEnd = where.jam_mulai[Op.lt];   // new end time
    const queryStart = where.jam_selesai[Op.gt]; // new start time
    // Find any existing slot that overlaps
    return existingSlots.find((slot) =>
      slot.user_id === where.user_id &&
      slot.tanggal === where.tanggal &&
      slot.jam_mulai < queryEnd &&
      slot.jam_selesai > queryStart
    ) || null;
  };
  WorkAssignment.create = async (values) => {
    const assignment = { id: 100, ...values };
    return assignment;
  };
  WorkAssignment.findByPk = async () => ({
    id: 100,
    user_id: 11,
    location_id: 2,
    tanggal: '2026-10-15',
    jam_mulai: '14:00:00',
    jam_selesai: '17:00:00',
    User: { id: 11, nama: 'Karyawan 11', jabatan: 'Staff' },
    Location: { id: 2, nama: 'Banyuwangi' },
    absensi: [],
  });
  Notifikasi.create = async () => ({});

  const res = responseMock();
  await controller.tambah({
    body: {
      user_id: 11,
      location_id: 2,
      tanggal: '2026-10-15',
      jam_mulai: '14:00',
      jam_selesai: '17:00',
    },
  }, res);

  assert.equal(res.statusCode, 201, `Expected 201 but got ${res.statusCode}: ${JSON.stringify(res.body)}`);
  assert.ok(res.body.message.includes('berhasil'));
});

test('overlapping slots for the same employee on the same date are rejected with details', async (t) => {
  const originals = {
    transaction: sequelize.transaction,
    userFindOne: User.findOne,
    locationFindByPk: Location.findByPk,
    assignmentFindOne: WorkAssignment.findOne,
    notificationCreate: Notifikasi.create,
  };
  const transaction = mockTransaction();

  t.after(() => {
    sequelize.transaction = originals.transaction;
    User.findOne = originals.userFindOne;
    Location.findByPk = originals.locationFindByPk;
    WorkAssignment.findOne = originals.assignmentFindOne;
    Notifikasi.create = originals.notificationCreate;
  });

  sequelize.transaction = async () => transaction;
  User.findOne = async ({ where }) => ({ id: where.id, nama: `Karyawan ${where.id}` });
  Location.findByPk = async (id) => ({
    id,
    nama: 'Bandung',
    latitude: -8.1,
    longitude: 114.2,
    radius_meters: 250,
  });
  // Simulate overlap: new slot 10:00-15:00 overlaps with existing 08:00-12:00
  WorkAssignment.findOne = async ({ where }) => {
    const queryEnd = where.jam_mulai[Op.lt];
    const queryStart = where.jam_selesai[Op.gt];
    const existing = {
      id: 99,
      user_id: 11,
      tanggal: '2026-10-15',
      jam_mulai: '08:00:00',
      jam_selesai: '12:00:00',
      Location: { id: 1, nama: 'Bandung' },
    };
    if (existing.jam_mulai < queryEnd && existing.jam_selesai > queryStart) {
      return existing;
    }
    return null;
  };

  const res = responseMock();
  await controller.tambah({
    body: {
      user_id: 11,
      location_id: 1,
      tanggal: '2026-10-15',
      jam_mulai: '10:00',
      jam_selesai: '15:00',
    },
  }, res);

  assert.equal(res.statusCode, 400);
  assert.ok(res.body.message.includes('bertabrakan'));
  assert.ok(res.body.message.includes('08:00'));
  assert.ok(res.body.message.includes('12:00'));
  assert.ok(res.body.message.includes('Bandung'));
});
