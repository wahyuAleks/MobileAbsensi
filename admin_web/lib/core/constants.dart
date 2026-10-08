import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConstants {
  // Brand color UI asli: #4F5BA8
  static const Color primaryColor = Color(0xFF4F5BA8);
  static const Color sidebarBg = Color(0xFF4C58A5);
  static const Color secondaryColor = Color(0xFF488286);
  
  static const Color bodyBg = Color(0xFFF9FAFB);
  static const Color cardBg = Color(0xFFF3F4F6);

  // URL Presets untuk Web
  static const String urlLocalhost = 'http://localhost:3000/api';
  static const String urlIpLocal = 'http://127.0.0.1:3000/api';

  // Default URL Web Admin
  static const String defaultBaseUrl = urlLocalhost;
  static String baseUrl = defaultBaseUrl;

  static const String prefKeyBaseUrl = 'admin_web_server_url';
  static const String prefKeyToken = 'token';
  static const String prefKeyRole = 'role';
  static const String prefKeyNama = 'nama';

  static Future<void> initBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefKeyBaseUrl);
    if (saved != null && saved.trim().isNotEmpty) {
      baseUrl = saved.trim();
    }
  }

  static Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    if (!cleanUrl.endsWith('/api')) {
      cleanUrl = '$cleanUrl/api';
    }
    baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefKeyBaseUrl, baseUrl);
  }

  static String get serverRoot {
    if (baseUrl.endsWith('/api')) {
      return baseUrl.substring(0, baseUrl.length - 4);
    }
    return baseUrl;
  }

  static String? getImageUrl(String? relativePath) {
    if (relativePath == null || relativePath.trim().isEmpty) return null;
    final path = relativePath.trim();
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final root = serverRoot;
    final fullPath = path.startsWith('/') ? path : '/$path';
    return '$root$fullPath';
  }
}
