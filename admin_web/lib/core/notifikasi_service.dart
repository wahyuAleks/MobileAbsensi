import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import 'api_service.dart';
import 'constants.dart';

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
    bool? isRead,
  }) {
    return NotifikasiItem(
      id: id,
      tipe: tipe,
      judul: judul,
      pesan: pesan,
      waktu: waktu,
      ctaText: ctaText,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }
}

class NotifikasiService {
  static final ValueNotifier<List<NotifikasiItem>> itemsNotifier =
      ValueNotifier<List<NotifikasiItem>>([]);
  static final ValueNotifier<int> unreadCountNotifier = ValueNotifier<int>(0);
  static final ValueNotifier<bool> realtimeConnectedNotifier =
      ValueNotifier<bool>(false);
  static final ValueNotifier<String?> errorNotifier =
      ValueNotifier<String?>(null);

  static io.Socket? _socket;
  static String? _activeToken;
  static bool _syncing = false;

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

  static Future<void> startRealtime() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(AppConstants.prefKeyToken);
    if (token == null || token.isEmpty) {
      errorNotifier.value = 'Sesi admin tidak tersedia. Silakan login kembali.';
      return;
    }

    await syncFromBackend();
    if (_socket != null && _activeToken == token) return;

    _socket?.dispose();
    _activeToken = token;
    realtimeConnectedNotifier.value = false;

    final socket = io.io(
      AppConstants.serverRoot,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setAuth({'token': token})
          .enableReconnection()
          .disableAutoConnect()
          .build(),
    );
    _socket = socket;

    socket.onConnect((_) {
      realtimeConnectedNotifier.value = true;
      errorNotifier.value = null;
      syncFromBackend();
    });
    socket.onDisconnect((_) {
      realtimeConnectedNotifier.value = false;
    });
    socket.onConnectError((error) {
      realtimeConnectedNotifier.value = false;
      errorNotifier.value = 'Koneksi notifikasi terputus: $error';
    });
    socket.on('notifikasi_baru', (dynamic payload) {
      if (payload is Map) {
        _tambahkanNotifikasi(Map<String, dynamic>.from(payload));
      }
    });
    socket.connect();
  }

  static void stopRealtime() {
    _socket?.dispose();
    _socket = null;
    _activeToken = null;
    realtimeConnectedNotifier.value = false;
  }

  static Future<void> syncFromBackend() async {
    if (_syncing) return;
    _syncing = true;
    try {
      final serverNotifs = await ApiService.getNotifikasi();
      itemsNotifier.value = serverNotifs
          .whereType<Map>()
          .map((item) => _fromServer(Map<String, dynamic>.from(item)))
          .toList();
      _updateUnreadCount();
      errorNotifier.value = null;
    } catch (e) {
      errorNotifier.value = 'Gagal memuat notifikasi: $e';
    } finally {
      _syncing = false;
    }
  }

  static NotifikasiItem _fromServer(Map<String, dynamic> item) {
    final data = item['data'];
    final parsedData = data is Map ? Map<String, dynamic>.from(data) : null;
    final isRead = item['is_read'] == true || item['is_read'] == 1;
    return NotifikasiItem(
      id: 'srv_${item['id']}',
      tipe: item['tipe']?.toString() ?? 'info',
      judul: item['judul']?.toString() ?? 'Pemberitahuan Sistem',
      pesan: item['pesan']?.toString() ?? '',
      waktu: formatWaktuRelatif(item['createdAt']),
      ctaText: item['cta_text']?.toString(),
      isRead: isRead,
      data: parsedData,
    );
  }

  static void _tambahkanNotifikasi(Map<String, dynamic> payload) {
    final notification = _fromServer(payload);
    final updated = [
      notification,
      ...itemsNotifier.value.where((item) => item.id != notification.id),
    ];
    itemsNotifier.value = updated.take(50).toList();
    _updateUnreadCount();
  }

  static void _updateUnreadCount() {
    unreadCountNotifier.value =
        itemsNotifier.value.where((item) => !item.isRead).length;
  }

  static Future<void> markAsRead(String id) async {
    final numericId = int.tryParse(id.replaceFirst('srv_', ''));
    if (numericId == null) return;

    final previousItems = itemsNotifier.value;
    itemsNotifier.value = previousItems
        .map((item) => item.id == id ? item.copyWith(isRead: true) : item)
        .toList();
    _updateUnreadCount();

    try {
      await ApiService.tandaiNotifikasiDibaca(numericId);
      errorNotifier.value = null;
    } catch (e) {
      itemsNotifier.value = previousItems;
      _updateUnreadCount();
      errorNotifier.value = 'Gagal menandai notifikasi sebagai dibaca: $e';
    }
  }

  static Future<void> markAllAsRead() async {
    final previousItems = itemsNotifier.value;
    itemsNotifier.value =
        previousItems.map((item) => item.copyWith(isRead: true)).toList();
    _updateUnreadCount();

    try {
      await ApiService.tandaiSemuaNotifikasiDibaca();
      errorNotifier.value = null;
    } catch (e) {
      itemsNotifier.value = previousItems;
      _updateUnreadCount();
      errorNotifier.value = 'Gagal menandai semua notifikasi sebagai dibaca: $e';
    }
  }
}
