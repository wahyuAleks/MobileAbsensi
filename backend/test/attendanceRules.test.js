const test = require('node:test');
const assert = require('node:assert/strict');
const {
  canCheckIn,
  canCheckOut,
  checkInWindow,
  isLate,
} = require('../src/utils/attendanceRules');

test('check-in opens 30 minutes before start and stays open through the end minute', () => {
  assert.deepEqual(checkInWindow('08:00:00', '12:00:00'), {
    opens: '07:30',
    closes: '12:00',
  });
  assert.equal(canCheckIn('07:29:59', '08:00:00', '12:00:00'), false);
  assert.equal(canCheckIn('07:30:00', '08:00:00', '12:00:00'), true);
  assert.equal(canCheckIn('08:00:00', '08:00:00', '12:00:00'), true);
  assert.equal(canCheckIn('08:00:01', '08:00:00', '12:00:00'), true);
  assert.equal(canCheckIn('12:00:59', '08:00:00', '12:00:00'), true);
  assert.equal(canCheckIn('12:01:00', '08:00:00', '12:00:00'), false);
});

test('check-out opens at the end time, and lateness starts after the scheduled start', () => {
  assert.equal(canCheckOut('16:59:59', '17:00:00'), false);
  assert.equal(canCheckOut('17:00:00', '17:00:00'), true);
  assert.equal(canCheckOut('17:01:00', '17:00:00'), true);
  assert.equal(isLate('08:00:00', '08:00:00'), false);
  assert.equal(isLate('08:00:01', '08:00:00'), true);
});
