const test = require('node:test');
const assert = require('node:assert/strict');
const JenisKegiatan = require('../src/models/JenisKegiatan');
const controller = require('../src/controllers/jenisKegiatanController');

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

test('employee lists only active master activities while admin can list inactive entries', async (t) => {
  const original = JenisKegiatan.findAll;
  t.after(() => { JenisKegiatan.findAll = original; });
  let query;
  JenisKegiatan.findAll = async (options) => {
    query = options;
    return [];
  };

  const employeeResponse = responseMock();
  await controller.daftar({ user: { role: 'karyawan' } }, employeeResponse);
  assert.deepEqual(query.where, { is_active: true });
  assert.equal(employeeResponse.statusCode, 200);

  const adminResponse = responseMock();
  await controller.daftar({ user: { role: 'admin' } }, adminResponse);
  assert.deepEqual(query.where, {});
});

test('new master names are trimmed and blank names are rejected', async (t) => {
  const original = JenisKegiatan.create;
  t.after(() => { JenisKegiatan.create = original; });
  let created;
  JenisKegiatan.create = async (values) => {
    created = values;
    return values;
  };

  const success = responseMock();
  await controller.tambah({ body: { nama: '  Panen  ' } }, success);
  assert.equal(success.statusCode, 201);
  assert.deepEqual(created, { nama: 'Panen', is_active: true });

  const invalid = responseMock();
  await controller.tambah({ body: { nama: '   ' } }, invalid);
  assert.equal(invalid.statusCode, 400);
});

test('report selection rejects inactive types unless keeping the same existing type', async (t) => {
  const originalFindOne = JenisKegiatan.findOne;
  const originalFindByPk = JenisKegiatan.findByPk;
  t.after(() => {
    JenisKegiatan.findOne = originalFindOne;
    JenisKegiatan.findByPk = originalFindByPk;
  });
  JenisKegiatan.findOne = async ({ where }) => {
    if (where.id === 7 && where.is_active === true) {
      return { id: 7, nama: 'Aktif', is_active: true };
    }
    if (where.id === 9 && where.is_active === undefined) {
      return { id: 9, nama: 'Nonaktif', is_active: false };
    }
    if (where.nama === 'Aktif' && where.is_active === true) {
      return { id: 7, nama: 'Aktif', is_active: true };
    }
    return null;
  };
  JenisKegiatan.findByPk = async (id) =>
    id === 9 ? { id: 9, nama: 'Nonaktif', is_active: false } : null;

  assert.equal((await controller.resolveValue(7)).value.id, 7);
  assert.match((await controller.resolveValue(9)).error, /tidak ditemukan atau sudah tidak aktif/);
  assert.equal((await controller.resolveValue(9, null, 9)).value.id, 9);
  assert.equal((await controller.resolveValue(null, 'Aktif')).value.id, 7);
  assert.match((await controller.resolveValue(null, 'Bukan master')).error, /data master/);
});
