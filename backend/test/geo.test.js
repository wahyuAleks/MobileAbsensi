const test = require('node:test');
const assert = require('node:assert/strict');
const {
  hitungJarakMeter,
  isDalamRadiusLokasi,
  validCoordinatePair,
} = require('../src/utils/geo');

test('distance uses meter units and accepts coordinates around the date line', () => {
  assert.equal(hitungJarakMeter(0, 0, 0, 0), 0);
  assert.ok(hitungJarakMeter(0, 0, 0, 0.001) > 111);
  assert.ok(hitungJarakMeter(0, 179.999, 0, -179.999) < 230);
});

test('location geofence respects each location coordinates and radius', () => {
  const firstSite = { latitude: '-6.9491610', longitude: '107.6450180', radius_meters: 100 };
  const secondSite = { latitude: '-7.2500000', longitude: '112.7500000', radius_meters: 50 };

  assert.deepEqual(
    isDalamRadiusLokasi(-6.949161, 107.645018, firstSite),
    { configured: true, valid: true, jarak: 0 },
  );
  assert.equal(isDalamRadiusLokasi(-6.949161, 107.645018, secondSite).valid, false);
  assert.equal(
    isDalamRadiusLokasi(-6.949161, 107.6465, firstSite).valid,
    false,
  );
});

test('invalid user coordinates and unconfigured locations cannot pass geofencing', () => {
  assert.equal(validCoordinatePair(0, 0), true);
  assert.equal(validCoordinatePair(90.1, 0), false);
  assert.equal(validCoordinatePair('1abc', 0), false);
  assert.equal(
    isDalamRadiusLokasi(0, 0, { latitude: null, longitude: null, radius_meters: 250 }).configured,
    false,
  );
});
