import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class ApiService {
  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefKeyToken);
  }

  static Future<Map<String, String>> _headers({bool json = true}) async {
    final token = await _getToken();
    return {
      if (json) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // ---------- AUTH ----------
  static Future<Map<String, dynamic>> login(
      String email, String password) async {
    // 1. Coba dengan baseUrl saat ini
    try {
      final res = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}/auth/login'),
            headers: await _headers(),
            body: jsonEncode({'email': email, 'password': password}),
          )
          .timeout(const Duration(seconds: 4));
      return _handle(res);
    } on ApiException {
      rethrow; // Password salah / validasi dari server
    } catch (_) {
      // 2. Jika gagal koneksi (misal beda network/emulator), coba fallback URL kandidat secara otomatis
      final fallbackUrls = [
        AppConstants.urlUsb,
        AppConstants.urlEmulator,
        AppConstants.urlLocalhost,
      ].where((u) => u != AppConstants.baseUrl).toList();

      for (final altUrl in fallbackUrls) {
        try {
          final res = await http
              .post(
                Uri.parse('$altUrl/auth/login'),
                headers: await _headers(),
                body: jsonEncode({'email': email, 'password': password}),
              )
              .timeout(const Duration(seconds: 3));

          // Jika sukses terhubung, perbarui baseUrl otomatis agar request selanjutnya lancar!
          await AppConstants.setBaseUrl(altUrl);
          return _handle(res);
        } on ApiException {
          await AppConstants.setBaseUrl(altUrl);
          rethrow;
        } catch (_) {
          continue;
        }
      }

      throw ApiException(
        'Tidak dapat terhubung ke server backend (${AppConstants.baseUrl}).\n'
        'Pastikan backend (node server.js) aktif.',
      );
    }
  }

  static Future<bool> testConnection(String url) async {
    try {
      String clean = url.trim();
      if (clean.endsWith('/')) clean = clean.substring(0, clean.length - 1);
      final rootUrl =
          clean.endsWith('/api') ? clean.substring(0, clean.length - 4) : clean;
      final res = await http
          .get(Uri.parse('$rootUrl/'))
          .timeout(const Duration(seconds: 3));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String nama,
    required String noHp,
    required String jabatan,
    String? email,
    File? foto,
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/profile');
    final req = http.MultipartRequest('PUT', uri);
    req.headers.addAll(await _headers(json: false));
    req.fields['nama'] = nama;
    req.fields['no_hp'] = noHp;
    req.fields['jabatan'] = jabatan;
    if (email != null && email.trim().isNotEmpty) {
      req.fields['email'] = email.trim();
    }
    if (foto != null) {
      req.files.add(await http.MultipartFile.fromPath('foto', foto.path));
    }

    final streamed = await req.send().timeout(const Duration(seconds: 25));
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateProfileTextOnly({
    required String nama,
    required String noHp,
    required String jabatan,
    String? email,
  }) async {
    return updateProfile(
      nama: nama,
      noHp: noHp,
      jabatan: jabatan,
      email: email,
    );
  }

  static Future<Map<String, dynamic>> ubahPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}/auth/ubah-password'),
          headers: await _headers(),
          body: jsonEncode({
            'password_lama': passwordLama,
            'password_baru': passwordBaru,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/auth/profile'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  // ---------- ABSENSI ----------
  static Future<Map<String, dynamic>> statusHariIni() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/absensi/status-hari-ini'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> absenMasuk({
    required File foto,
    required double lat,
    required double lng,
    required int jadwalId,
  }) =>
      _uploadAbsen('masuk', foto, lat, lng, jadwalId);

  static Future<Map<String, dynamic>> absenPulang({
    required File foto,
    required double lat,
    required double lng,
    required int jadwalId,
  }) =>
      _uploadAbsen('pulang', foto, lat, lng, jadwalId);

  static Future<Map<String, dynamic>> _uploadAbsen(
    String jenis,
    File foto,
    double lat,
    double lng,
    int jadwalId,
  ) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/absensi/$jenis');
    final req = http.MultipartRequest('POST', uri);
    req.headers.addAll(await _headers(json: false));
    req.fields['lat'] = lat.toString();
    req.fields['lng'] = lng.toString();
    req.fields['jadwal_id'] = jadwalId.toString();
    req.files.add(await http.MultipartFile.fromPath('foto', foto.path));

    final streamed = await req.send();
    final res = await http.Response.fromStream(streamed);
    return _handle(res);
  }

  static Future<List<dynamic>> riwayatAbsen() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/absensi/riwayat'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  // ---------- CUTI ----------
  static Future<Map<String, dynamic>> ajukanCuti({
    required String jenisCuti,
    required String tanggalMulai,
    required String tanggalSelesai,
    required String alasan,
    File? lampiran,
  }) async {
    if (lampiran != null) {
      final uri = Uri.parse('${AppConstants.baseUrl}/cuti');
      final req = http.MultipartRequest('POST', uri);
      req.headers.addAll(await _headers(json: false));
      req.fields['jenis_cuti'] = jenisCuti;
      req.fields['tanggal_mulai'] = tanggalMulai;
      req.fields['tanggal_selesai'] = tanggalSelesai;
      req.fields['alasan'] = alasan;
      req.files
          .add(await http.MultipartFile.fromPath('lampiran', lampiran.path));

      final streamed = await req.send().timeout(const Duration(seconds: 20));
      final res = await http.Response.fromStream(streamed);
      return _handle(res);
    }

    final res = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/cuti'),
          headers: await _headers(),
          body: jsonEncode({
            'jenis_cuti': jenisCuti,
            'tanggal_mulai': tanggalMulai,
            'tanggal_selesai': tanggalSelesai,
            'alasan': alasan,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<List<dynamic>> informasiCutiSaya() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/cuti/saya'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<List<dynamic>> daftarPengajuanCuti({String? status}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/cuti').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> prosesCuti(int id, String status,
      {String? catatan}) async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}/cuti/$id/proses'),
          headers: await _headers(),
          body: jsonEncode({'status': status, 'catatan_admin': catatan}),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  // ---------- LAPORAN ----------
  static Future<List<dynamic>> jenisKegiatanAktif() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/jenis-kegiatan'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<List<dynamic>> jenisKegiatanAdmin() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/jenis-kegiatan'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> tambahJenisKegiatan(String nama) async {
    final res = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/jenis-kegiatan'),
          headers: await _headers(),
          body: jsonEncode({'nama': nama}),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> perbaruiJenisKegiatan(
    int id, {
    String? nama,
    required bool isActive,
  }) async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}/jenis-kegiatan/$id'),
          headers: await _headers(),
          body: jsonEncode({
            if (nama != null) 'nama': nama,
            'is_active': isActive,
          }),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> submitLaporan({
    required String tanggal,
    required String judul,
    required String isiLaporan,
    String? jenisKegiatan,
    int? jenisKegiatanId,
    String? lokasi,
    String? unitDrone,
    String? luasArea,
    String? uraianPekerjaan,
    String? hasil,
    String? rencanaEsok,
    File? lampiran,
    String status = 'Terkirim',
  }) async {
    return _requestLaporan(
      'POST',
      '/laporan',
      {
        'tanggal': tanggal,
        'judul': judul,
        'isi_laporan': isiLaporan,
        if (jenisKegiatan != null) 'jenis_kegiatan': jenisKegiatan,
        if (jenisKegiatanId != null)
          'jenis_kegiatan_id': jenisKegiatanId.toString(),
        if (lokasi != null) 'lokasi': lokasi,
        if (unitDrone != null) 'unit_drone': unitDrone,
        if (luasArea != null) 'luas_area': luasArea,
        if (uraianPekerjaan != null) 'uraian_pekerjaan': uraianPekerjaan,
        if (hasil != null) 'hasil': hasil,
        if (rencanaEsok != null) 'rencana_esok': rencanaEsok,
        'status': status,
      },
      lampiran: lampiran,
    );
  }

  static Future<Map<String, dynamic>> updateDraft(
    int id, {
    required String tanggal,
    required String judul,
    required String isiLaporan,
    String? jenisKegiatan,
    int? jenisKegiatanId,
    String? lokasi,
    String? unitDrone,
    String? luasArea,
    String? uraianPekerjaan,
    String? hasil,
    String? rencanaEsok,
    File? lampiran,
  }) async {
    return _requestLaporan(
      'PUT',
      '/laporan/$id',
      {
        'tanggal': tanggal,
        'judul': judul,
        'isi_laporan': isiLaporan,
        if (jenisKegiatan != null) 'jenis_kegiatan': jenisKegiatan,
        if (jenisKegiatanId != null)
          'jenis_kegiatan_id': jenisKegiatanId.toString(),
        if (lokasi != null) 'lokasi': lokasi,
        if (unitDrone != null) 'unit_drone': unitDrone,
        if (luasArea != null) 'luas_area': luasArea,
        if (uraianPekerjaan != null) 'uraian_pekerjaan': uraianPekerjaan,
        if (hasil != null) 'hasil': hasil,
        if (rencanaEsok != null) 'rencana_esok': rencanaEsok,
      },
      lampiran: lampiran,
    );
  }

  static Future<Map<String, dynamic>> kirimDraft(
    int id, {
    required String tanggal,
    required String judul,
    required String isiLaporan,
    String? jenisKegiatan,
    int? jenisKegiatanId,
    String? lokasi,
    String? unitDrone,
    String? luasArea,
    String? uraianPekerjaan,
    String? hasil,
    String? rencanaEsok,
    File? lampiran,
  }) async {
    return _requestLaporan(
      'PUT',
      '/laporan/$id/kirim',
      {
        'tanggal': tanggal,
        'judul': judul,
        'isi_laporan': isiLaporan,
        if (jenisKegiatan != null) 'jenis_kegiatan': jenisKegiatan,
        if (jenisKegiatanId != null)
          'jenis_kegiatan_id': jenisKegiatanId.toString(),
        if (lokasi != null) 'lokasi': lokasi,
        if (unitDrone != null) 'unit_drone': unitDrone,
        if (luasArea != null) 'luas_area': luasArea,
        if (uraianPekerjaan != null) 'uraian_pekerjaan': uraianPekerjaan,
        if (hasil != null) 'hasil': hasil,
        if (rencanaEsok != null) 'rencana_esok': rencanaEsok,
      },
      lampiran: lampiran,
    );
  }

  static Future<Map<String, dynamic>> editLaporanAdmin(
    int id, {
    required String tanggal,
    required String judul,
    required String isiLaporan,
    String? jenisKegiatan,
    String? lokasi,
    String? unitDrone,
    String? luasArea,
    String? uraianPekerjaan,
    String? hasil,
    String? rencanaEsok,
    File? lampiran,
  }) async {
    return _requestLaporan(
      'PUT',
      '/laporan/$id/admin-edit',
      {
        'tanggal': tanggal,
        'judul': judul,
        'isi_laporan': isiLaporan,
        if (jenisKegiatan != null) 'jenis_kegiatan': jenisKegiatan,
        if (lokasi != null) 'lokasi': lokasi,
        if (unitDrone != null) 'unit_drone': unitDrone,
        if (luasArea != null) 'luas_area': luasArea,
        if (uraianPekerjaan != null) 'uraian_pekerjaan': uraianPekerjaan,
        if (hasil != null) 'hasil': hasil,
        if (rencanaEsok != null) 'rencana_esok': rencanaEsok,
      },
      lampiran: lampiran,
    );
  }

  static Future<Map<String, dynamic>> _requestLaporan(
    String method,
    String path,
    Map<String, String> fields, {
    File? lampiran,
  }) async {
    final request = http.MultipartRequest(
      method,
      Uri.parse('${AppConstants.baseUrl}$path'),
    );
    request.headers.addAll(await _headers(json: false));
    request.fields.addAll(fields);
    if (lampiran != null) {
      request.files.add(
        await http.MultipartFile.fromPath('lampiran', lampiran.path),
      );
    }
    final streamed = await request.send().timeout(const Duration(seconds: 25));
    return _handle(await http.Response.fromStream(streamed));
  }

  static Future<List<dynamic>> laporanSaya() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/laporan/saya'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<List<dynamic>> rekapLaporan() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/laporan/rekap'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  // ---------- KARYAWAN (ADMIN) ----------
  static Future<List<dynamic>> daftarKaryawan() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/karyawan'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> tambahKaryawan(
      Map<String, dynamic> data) async {
    final res = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/karyawan'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateKaryawan(
      int id, Map<String, dynamic> data) async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}/karyawan/$id'),
          headers: await _headers(),
          body: jsonEncode(data),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<void> hapusKaryawan(int id) async {
    final res = await http
        .delete(
          Uri.parse('${AppConstants.baseUrl}/karyawan/$id'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    _handle(res);
  }

  // ---------- LOKASI & JAM MASUK (ADMIN) ----------
  static Future<List<dynamic>> daftarLokasi() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/lokasi'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> simpanLokasi(
    String nama, {
    int? id,
    double? latitude,
    double? longitude,
    int? radiusMeters,
  }) async {
    if ((latitude == null) != (longitude == null)) {
      throw ArgumentError('Latitude dan longitude harus diisi bersamaan.');
    }
    final body = <String, dynamic>{'nama': nama};
    if (latitude != null && longitude != null) {
      body['latitude'] = latitude;
      body['longitude'] = longitude;
      body['radius_meters'] = radiusMeters ?? 250;
    }
    final uri = Uri.parse(
      id == null
          ? '${AppConstants.baseUrl}/lokasi'
          : '${AppConstants.baseUrl}/lokasi/$id',
    );
    final res = id == null
        ? await http
            .post(uri, headers: await _headers(), body: jsonEncode(body))
            .timeout(const Duration(seconds: 15))
        : await http
            .put(uri, headers: await _headers(), body: jsonEncode(body))
            .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<void> hapusLokasi(int id) async {
    final res = await http
        .delete(
          Uri.parse('${AppConstants.baseUrl}/lokasi/$id'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    _handle(res);
  }

  static Future<Map<String, dynamic>> jadwalLokasi(
    int id,
    String tanggal,
  ) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/lokasi/$id/jadwal')
        .replace(queryParameters: {'tanggal': tanggal});
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> simpanJadwalLokasi({
    required int id,
    required String tanggal,
    required String jamMasuk,
  }) async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}/lokasi/$id/jadwal'),
          headers: await _headers(),
          body: jsonEncode({'tanggal': tanggal, 'jam_masuk': jamMasuk}),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<List<dynamic>> jadwalKerjaTanggal(String tanggal) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/jadwal-kerja')
        .replace(queryParameters: {'tanggal': tanggal});
    final res = await http
        .get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> simpanJadwalKerja({
    int? id,
    required int userId,
    required int locationId,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    final uri = Uri.parse(id == null
        ? '${AppConstants.baseUrl}/jadwal-kerja'
        : '${AppConstants.baseUrl}/jadwal-kerja/$id');
    final body = jsonEncode({
      'user_id': userId,
      'location_id': locationId,
      'tanggal': tanggal,
      'jam_mulai': jamMulai,
      'jam_selesai': jamSelesai,
    });
    final res = id == null
        ? await http
            .post(uri, headers: await _headers(), body: body)
            .timeout(const Duration(seconds: 15))
        : await http
            .put(uri, headers: await _headers(), body: body)
            .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> simpanJadwalKerjaUntukBanyakKaryawan({
    required List<int> userIds,
    required int locationId,
    required String tanggal,
    required String jamMulai,
    required String jamSelesai,
  }) async {
    final res = await http
        .post(
          Uri.parse('${AppConstants.baseUrl}/jadwal-kerja/bulk'),
          headers: await _headers(),
          body: jsonEncode({
            'user_ids': userIds,
            'location_id': locationId,
            'tanggal': tanggal,
            'jam_mulai': jamMulai,
            'jam_selesai': jamSelesai,
          }),
        )
        .timeout(const Duration(seconds: 15));
    final body = _handle(res);
    if (body is Map<String, dynamic>) return body;
    throw ApiException('Response penyimpanan jadwal tidak valid');
  }

  static Future<void> hapusJadwalKerja(int id) async {
    final res = await http
        .delete(
          Uri.parse('${AppConstants.baseUrl}/jadwal-kerja/$id'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    _handle(res);
  }

  static Future<Map<String, dynamic>> jadwalKerjaHariIni() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/jadwal-kerja/saya/hari-ini'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<List<dynamic>> rekapAbsensiAdmin(
      {int? bulan, int? tahun, String? tanggal}) async {
    final query = <String, String>{};
    if (bulan != null) query['bulan'] = bulan.toString();
    if (tahun != null) query['tahun'] = tahun.toString();
    if (tanggal != null) query['tanggal'] = tanggal;

    final uri = Uri.parse('${AppConstants.baseUrl}/absensi/rekap')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await http
        .get(
          uri,
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  // ---------- NOTIFIKASI ----------
  static Future<List<dynamic>> getNotifikasi() async {
    final res = await http
        .get(
          Uri.parse('${AppConstants.baseUrl}/notifikasi'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<void> tandaiNotifikasiDibaca(int id) async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}/notifikasi/$id/read'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    _handle(res);
  }

  static Future<void> tandaiSemuaNotifikasiDibaca() async {
    final res = await http
        .put(
          Uri.parse('${AppConstants.baseUrl}/notifikasi/read-all'),
          headers: await _headers(),
        )
        .timeout(const Duration(seconds: 15));
    _handle(res);
  }

  static dynamic _handle(http.Response res) {
    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    } catch (_) {
      body = {
        'message':
            res.body.isNotEmpty ? res.body : 'Response dari server tidak valid'
      };
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Terjadi kesalahan (Status ${res.statusCode})';
    throw ApiException(message);
  }

  static List<dynamic> _handleList(http.Response res) {
    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : [];
    } catch (_) {
      body = [];
    }
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body is List ? body : [];
    }
    final message = (body is Map && body['message'] != null)
        ? body['message'].toString()
        : 'Terjadi kesalahan (Status ${res.statusCode})';
    throw ApiException(message);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}
