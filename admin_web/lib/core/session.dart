import 'package:shared_preferences/shared_preferences.dart';
import 'constants.dart';

class Session {
  static Future<void> simpanLogin({
    required String token,
    required String role,
    required String nama,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyToken, token);
    await prefs.setString(AppConstants.prefKeyRole, role);
    await prefs.setString(AppConstants.prefKeyNama, nama);
  }

  static Future<bool> sudahLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefKeyToken) != null;
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefKeyRole);
  }

  static Future<String?> getNama() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefKeyNama);
  }

  static Future<void> setNama(String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyNama, nama);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefKeyToken);
    await prefs.remove(AppConstants.prefKeyRole);
    await prefs.remove(AppConstants.prefKeyNama);
  }
}
