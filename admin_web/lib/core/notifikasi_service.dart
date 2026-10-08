import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotifikasiItem {
  final String id;
  final String tipe;
  final String judul;
  final String pesan;
  final String waktu;
  final String? ctaText;
  final bool isRead;
  final Map<String, dynamic>? data;

  const NotifikasiItem({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.waktu,
    this.ctaText,
    this.isRead = false,
    this.data,
  });

  NotifikasiItem copyWith({
    String? id,
    String? tipe,
    String? judul,
    String? pesan,
    String? waktu,
    String? ctaText,
    bool? isRead,
    Map<String, dynamic>? data,
  }) {
    return NotifikasiItem(
      id: id ?? this.id,
      tipe: tipe ?? this.tipe,
      judul: judul ?? this.judul,
      pesan: pesan ?? this.pesan,
      waktu: waktu ?? this.waktu,
      ctaText: ctaText ?? this.ctaText,
      isRead: isRead ?? this.isRead,
      data: data ?? this.data,
    );
  }
}

class NotifikasiService {
  static const String _prefReadIdsKey = 'admin_web_notifikasi_read_ids';

  static final ValueNotifier<List<NotifikasiItem>> itemsNotifier = ValueNotifier<List<NotifikasiItem>>([]);
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);

  static bool _syncing = false;

  static Future<void> init() async {
    await syncFromBackend();
  }

  static String formatWaktuRelatif(dynamic dateVal) {
    if (dateVal == null) return 'Baru saja';
    DateTime? dt;
    if (dateVal is DateTime) {
      dt = dateVal;
    } else {
      dt = DateTime.tryParse(dateVal.toString());
    }
    if (dt == null) return dateVal.toString();

    dt = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin, ${DateFormat('HH:mm').format(dt)}';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  static Future<void> syncFromBackend() async {
    if (_syncing) return;
    _syncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localReadIds = (prefs.getStringList(_prefReadIdsKey) ?? []).toSet();

      final List<NotifikasiItem> hasil = [];

      try {
        final serverNotifs = await ApiService.getNotifikasi();
        for (final item in serverNotifs) {
          final idStr = 'srv_${item['id']}';
          final bool isReadDb = item['is_read'] == true;
          final bool isRead = isReadDb || localReadIds.contains(idStr);

          hasil.add(NotifikasiItem(
            id: idStr,
            tipe: item['tipe']?.toString() ?? 'info',
            judul: item['judul']?.toString() ?? 'Pemberitahuan System',
            pesan: item['pesan']?.toString() ?? '',
            waktu: formatWaktuRelatif(item['createdAt']),
            ctaText: item['cta_text']?.toString(),
            isRead: isRead,
          ));
        }
      } catch (_) {}

      itemsNotifier.value = hasil;
      _updateUnreadCount();
    } catch (_) {
      _updateUnreadCount();
    } finally {
      _syncing = false;
    }
  }

  static void _updateUnreadCount() {
    final unread = itemsNotifier.value.where((it) => !it.isRead).length;
    unreadCountNotifier.value = unread;
  }

  static Future<void> markAsRead(String id) async {
    final currentList = itemsNotifier.value;
    final updatedList = currentList.map((item) {
      if (item.id == id) return item.copyWith(isRead: true);
      return item;
    }).toList();

    itemsNotifier.value = updatedList;
    _updateUnreadCount();

    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = (prefs.getStringList(_prefReadIdsKey) ?? []).toSet();
      readIds.add(id);
      await prefs.setStringList(_prefReadIdsKey, readIds.toList());
    } catch (_) {}
  }

  static Future<void> markAllAsRead() async {
    final currentList = itemsNotifier.value;
    final updatedList = currentList.map((item) => item.copyWith(isRead: true)).toList();

    itemsNotifier.value = updatedList;
    _updateUnreadCount();

    try {
      final prefs = await SharedPreferences.getInstance();
      final allIds = updatedList.map((e) => e.id).toList();
      await prefs.setStringList(_prefReadIdsKey, allIds);
    } catch (_) {}
  }
}
