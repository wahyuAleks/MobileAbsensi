function shiftMinutes(time, delta) {
  const [hours, minutes] = time.split(':').map(Number);
  const total = Math.max(0, hours * 60 + minutes + delta);
  return `${String(Math.floor(total / 60)).padStart(2, '0')}:${String(total % 60).padStart(2, '0')}`;
}

function checkInWindow(start, end) {
  return { opens: shiftMinutes(start, -30), closes: end.slice(0, 5) };
}

function canCheckIn(now, start, end) {
  const window = checkInWindow(start, end);
  const minute = now.slice(0, 5);
  return minute >= window.opens && minute <= window.closes;
}

function canCheckOut(now, end) {
  return now >= end;
}

function isLate(now, start) {
  return now > start;
}

module.exports = { canCheckIn, canCheckOut, checkInWindow, isLate, shiftMinutes };
