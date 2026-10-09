import 'dart:convert';
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
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${AppConstants.baseUrl}/auth/login'),
        headers: await _headers(),
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 5));
      return _handle(res);
    } on ApiException {
      rethrow;
    } catch (_) {
      final fallbackUrls = [
        AppConstants.urlLocalhost,
        AppConstants.urlIpLocal,
      ].where((u) => u != AppConstants.baseUrl).toList();

      for (final altUrl in fallbackUrls) {
        try {
          final res = await http.post(
            Uri.parse('$altUrl/auth/login'),
            headers: await _headers(),
            body: jsonEncode({'email': email, 'password': password}),
          ).timeout(const Duration(seconds: 4));
          
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
      final rootUrl = clean.endsWith('/api') ? clean.substring(0, clean.length - 4) : clean;
      final res = await http.get(Uri.parse('$rootUrl/')).timeout(const Duration(seconds: 4));
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
  }) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/auth/profile');
    final res = await http.put(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'nama': nama,
        'no_hp': noHp,
        'jabatan': jabatan,
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
      }),
    ).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> ubahPassword({
    required String passwordLama,
    required String passwordBaru,
  }) async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}/auth/ubah-password'),
      headers: await _headers(),
      body: jsonEncode({
        'password_lama': passwordLama,
        'password_baru': passwordBaru,
      }),
    ).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> getProfile() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/auth/profile'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  // ---------- CUTI (ADMIN) ----------
  static Future<List<dynamic>> daftarPengajuanCuti({String? status}) async {
    final uri = Uri.parse('${AppConstants.baseUrl}/cuti').replace(
      queryParameters: status != null ? {'status': status} : null,
    );
    final res = await http.get(uri, headers: await _headers()).timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> prosesCuti(int id, String status, {String? catatan}) async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}/cuti/$id/proses'),
      headers: await _headers(),
      body: jsonEncode({'status': status, 'catatan_admin': catatan}),
    ).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  // ---------- LAPORAN ----------
  static Future<List<dynamic>> rekapLaporan() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/laporan/rekap'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<List<dynamic>> rekapLaporanFiltered({
    String? tanggal,
    String? tanggalStart,
    String? tanggalEnd,
    String? minggu,
    String? bulan,
    String? userId,
  }) async {
    final query = <String, String>{};
    if (tanggal != null) query['tanggal'] = tanggal;
    if (tanggalStart != null) query['tanggal_start'] = tanggalStart;
    if (tanggalEnd != null) query['tanggal_end'] = tanggalEnd;
    if (minggu != null) query['minggu'] = minggu;
    if (bulan != null) query['bulan'] = bulan;
    if (userId != null) query['user_id'] = userId;

    final uri = Uri.parse('${AppConstants.baseUrl}/laporan/rekap')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<List<dynamic>> rekapChart({String? userId}) async {
    final query = <String, String>{};
    if (userId != null) query['user_id'] = userId;
    final uri = Uri.parse('${AppConstants.baseUrl}/laporan/chart')
        .replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(uri, headers: await _headers())
        .timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  // ---------- KARYAWAN (ADMIN) ----------
  static Future<List<dynamic>> daftarKaryawan() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/karyawan'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<List<dynamic>> daftarAkun() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/karyawan/akun'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<Map<String, dynamic>> tambahKaryawan(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('${AppConstants.baseUrl}/karyawan'),
      headers: await _headers(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<Map<String, dynamic>> updateKaryawan(int id, Map<String, dynamic> data) async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}/karyawan/$id'),
      headers: await _headers(),
      body: jsonEncode(data),
    ).timeout(const Duration(seconds: 15));
    return _handle(res);
  }

  static Future<void> hapusKaryawan(int id) async {
    final res = await http.delete(
      Uri.parse('${AppConstants.baseUrl}/karyawan/$id'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    _handle(res);
  }

  static Future<List<dynamic>> rekapAbsensiAdmin({int? bulan, int? tahun, String? tanggal}) async {
    final query = <String, String>{};
    if (bulan != null) query['bulan'] = bulan.toString();
    if (tahun != null) query['tahun'] = tahun.toString();
    if (tanggal != null) query['tanggal'] = tanggal;

    final uri = Uri.parse('${AppConstants.baseUrl}/absensi/rekap').replace(queryParameters: query.isEmpty ? null : query);
    final res = await http.get(
      uri,
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  // ---------- NOTIFIKASI ----------
  static Future<List<dynamic>> getNotifikasi() async {
    final res = await http.get(
      Uri.parse('${AppConstants.baseUrl}/notifikasi'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    return _handleList(res);
  }

  static Future<void> tandaiNotifikasiDibaca(int id) async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}/notifikasi/$id/read'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    _handle(res);
  }

  static Future<void> tandaiSemuaNotifikasiDibaca() async {
    final res = await http.put(
      Uri.parse('${AppConstants.baseUrl}/notifikasi/read-all'),
      headers: await _headers(),
    ).timeout(const Duration(seconds: 15));
    _handle(res);
  }

  static dynamic _handle(http.Response res) {
    dynamic body;
    try {
      body = res.body.isNotEmpty ? jsonDecode(res.body) : {};
    } catch (_) {
      body = {'message': res.body.isNotEmpty ? res.body : 'Response dari server tidak valid'};
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
