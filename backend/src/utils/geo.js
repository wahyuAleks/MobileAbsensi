// Menghitung jarak antara 2 koordinat (meter) pakai formula haversine
function hitungJarakMeter(lat1, lng1, lat2, lng2) {
  const R = 6371000; // radius bumi dalam meter
  const toRad = (deg) => (deg * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);
  const dLng = toRad(lng2 - lng1);

  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);

  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

function validCoordinate(value, min, max) {
  if (value == null || String(value).trim() === '') return false;
  const number = Number(value);
  return Number.isFinite(number) && number >= min && number <= max;
}

function validCoordinatePair(lat, lng) {
  return validCoordinate(lat, -90, 90) && validCoordinate(lng, -180, 180);
}

function isDalamRadiusLokasi(lat, lng, location) {
  if (
    !validCoordinatePair(lat, lng) ||
    !validCoordinatePair(location?.latitude, location?.longitude)
  ) {
    return { configured: false, valid: false, jarak: null };
  }

  const radius = Number(location.radius_meters);
  if (!Number.isInteger(radius) || radius <= 0) {
    return { configured: false, valid: false, jarak: null };
  }

  const jarak = hitungJarakMeter(
    Number(lat),
    Number(lng),
    Number(location.latitude),
    Number(location.longitude),
  );
  return { configured: true, valid: jarak <= radius, jarak };
}

module.exports = {
  hitungJarakMeter,
  isDalamRadiusLokasi,
  validCoordinatePair,
};
