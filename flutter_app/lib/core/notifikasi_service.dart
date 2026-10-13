import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Model item notifikasi karyawan
class NotifikasiItem {
  final String id;
  final String tipe; // 'absen' | 'cuti' | 'laporan' | 'info'
  final String judul;
  final String pesan;
  final String waktu;
  final String? ctaText;
  final bool isRead;
  final Map<String, dynamic>? data;
  final VoidCallback? onTap;

  const NotifikasiItem({
    required this.id,
    required this.tipe,
    required this.judul,
    required this.pesan,
    required this.waktu,
    this.ctaText,
    this.isRead = false,
    this.data,
    this.onTap,
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
    VoidCallback? onTap,
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
      onTap: onTap ?? this.onTap,
    );
  }
}

/// Service pengelola notifikasi & status unread badge (Sinkron dengan Backend MySQL)
class NotifikasiService {
  static const String _prefReadIdsKey = 'notifikasi_read_ids_v2';

  // Notifier untuk daftar item notifikasi
  static final ValueNotifier<List<NotifikasiItem>> itemsNotifier =
      ValueNotifier<List<NotifikasiItem>>([]);

  // Notifier untuk jumlah notifikasi belum dibaca (badge counter)
  static final ValueNotifier<int> unreadCountNotifier =
      ValueNotifier<int>(0);

  static bool _syncing = false;

  /// Inisialisasi awal
  static Future<void> init() async {
    await syncFromBackend();
  }

  /// Format waktu relatif yang ramah
  static String formatWaktuRelatif(dynamic dateVal) {
    if (dateVal == null) return 'Baru saja';
    DateTime? dt;
    if (dateVal is DateTime) {
      dt = dateVal;
    } else {
      dt = DateTime.tryParse(dateVal.toString());
    }
    if (dt == null) return dateVal.toString();

    // Konversi ke local time
    dt = dt.toLocal();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) {
      return 'Kemarin, ${DateFormat('HH:mm').format(dt)}';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays} hari lalu';
    }
    return DateFormat('dd MMM yyyy, HH:mm').format(dt);
  }

  /// Sinkronkan notifikasi secara real-time dari backend MySQL
  static Future<void> syncFromBackend() async {
    if (_syncing) return;
    _syncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final localReadIds = (prefs.getStringList(_prefReadIdsKey) ?? []).toSet();

      final List<NotifikasiItem> hasil = [];
      final Set<String> processedKeys = {};

      // 1. Ambil data notifikasi resmi dari tabel `notifikasi` backend
      try {
        final serverNotifs = await ApiService.getNotifikasi();
        for (final item in serverNotifs) {
          final idStr = 'srv_${item['id']}';
          final bool isReadDb = item['is_read'] == true;
          final bool isRead = isReadDb || localReadIds.contains(idStr);

          Map<String, dynamic>? dataMap;
          if (item['data'] != null && item['data'] is Map) {
            dataMap = Map<String, dynamic>.from(item['data']);
          }

          hasil.add(NotifikasiItem(
            id: idStr,
            tipe: item['tipe']?.toString() ?? 'info',
            judul: item['judul']?.toString() ?? 'Pemberitahuan',
            pesan: item['pesan']?.toString() ?? '',
            waktu: formatWaktuRelatif(item['createdAt']),
            ctaText: item['cta_text']?.toString(),
            data: dataMap,
            isRead: isRead,
          ));

          processedKeys.add('${item['tipe']}_${item['judul']}');
        }
      } catch (_) {}

      // 2. Tambahan fallback sinkronisasi langsung dari data Cuti Saya
      // Agar jika ada pengajuan cuti yang baru di-approve/reject admin, langsung muncul seketika!
      try {
        final cutiList = await ApiService.informasiCutiSaya();
        for (final c in cutiList) {
          final status = (c['status'] ?? '').toString().toLowerCase();
          final jenis = c['jenis_cuti'] ?? 'Cuti';
          final tglMulai = c['tanggal_mulai'] ?? '';
          final tglSelesai = c['tanggal_selesai'] ?? '';
          final catatanAdmin = c['catatan_admin'];
          final idStr = 'cuti_status_${c['id']}_$status';

          if (status == 'diterima' || status == 'ditolak') {
            final isAcc = status == 'diterima';
            final judul = isAcc ? 'Pengajuan Cuti Disetujui' : 'Pengajuan Cuti Ditolak';
            final key = 'cuti_$judul';

            // Jangan dobel jika sudah diambil dari tabel notifikasi backend
            if (!processedKeys.contains(key)) {
              final pesan = isAcc
                  ? 'Pengajuan $jenis ($tglMulai s/d $tglSelesai) telah disetujui admin.'
                  : 'Pengajuan $jenis ($tglMulai s/d $tglSelesai) ditolak. Alasan: ${catatanAdmin ?? "Tidak ada catatan."}';

              final bool isRead = localReadIds.contains(idStr);

              hasil.add(NotifikasiItem(
                id: idStr,
                tipe: 'cuti',
                judul: judul,
                pesan: pesan,
                waktu: formatWaktuRelatif(c['updatedAt'] ?? c['createdAt']),
                ctaText: 'Lihat Status & Riwayat Cuti →',
                data: {'cuti_id': c['id'], 'tabIndex': 1},
                isRead: isRead,
              ));
              processedKeys.add(key);
            }
          }
        }
      } catch (_) {}

      // 3. Tambahkan pengingat absensi jika belum ada
      if (!processedKeys.contains('absen_Waktunya Absensi Pagi!')) {
        const idStr = 'reminder_absen_masuk';
        hasil.add(NotifikasiItem(
          id: idStr,
          tipe: 'absen',
          judul: 'Waktunya Absensi Pagi!',
          pesan: 'Batas jam masuk mengikuti jadwal lokasi kerja hari ini. Segera lakukan presensi kehadiran dengan verifikasi wajah & lokasi.',
          waktu: 'Hari ini',
          ctaText: 'Buka Halaman Absensi →',
          data: {'isMasuk': true},
          isRead: localReadIds.contains(idStr),
        ));
      }

      // 4. Tambahkan pengingat laporan kerja jika belum ada
      if (!processedKeys.contains('laporan_Jangan Lupa Laporan Harian')) {
        const idStr = 'reminder_laporan_harian';
        hasil.add(NotifikasiItem(
          id: idStr,
          tipe: 'laporan',
          judul: 'Jangan Lupa Laporan Harian',
          pesan: 'Laporan progres kerja hari ini belum dikirimkan. Buat & kirimkan laporan aktivitas sebelum jam 18:00 WIB.',
          waktu: 'Hari ini',
          ctaText: 'Tulis Laporan Kerja →',
          data: {},
          isRead: localReadIds.contains(idStr),
        ));
      }

      itemsNotifier.value = hasil;
      _updateUnreadCount();
    } catch (_) {
      // Fallback aman
      _updateUnreadCount();
    } finally {
      _syncing = false;
    }
  }

  /// Perbarui jumlah unread badge
  static void _updateUnreadCount() {
    final unread = itemsNotifier.value.where((it) => !it.isRead).length;
    unreadCountNotifier.value = unread;
  }

  /// Tandai satu notifikasi sebagai sudah dibaca
  static Future<void> markAsRead(String id) async {
    final currentList = itemsNotifier.value;
    final updatedList = currentList.map((item) {
      if (item.id == id) {
        return item.copyWith(isRead: true);
      }
      return item;
    }).toList();

    itemsNotifier.value = updatedList;
    _updateUnreadCount();

    // Simpan ke SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final readIds = (prefs.getStringList(_prefReadIdsKey) ?? []).toSet();
      readIds.add(id);
      await prefs.setStringList(_prefReadIdsKey, readIds.toList());
    } catch (_) {}

    // Jika notifikasi dari server backend, panggil API tandai dibaca
    if (id.startsWith('srv_')) {
      final numId = int.tryParse(id.substring(4));
      if (numId != null) {
        try {
          await ApiService.tandaiNotifikasiDibaca(numId);
        } catch (_) {}
      }
    }
  }

  /// Tandai SEMUA notifikasi sebagai sudah dibaca
  static Future<void> markAllAsRead() async {
    final currentList = itemsNotifier.value;
    final updatedList = currentList.map((item) {
      return item.copyWith(isRead: true);
    }).toList();

    itemsNotifier.value = updatedList;
    _updateUnreadCount();

    // Simpan ke SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final allIds = updatedList.map((e) => e.id).toList();
      await prefs.setStringList(_prefReadIdsKey, allIds);
    } catch (_) {}

    // Panggil API tandai semua dibaca di server backend
    try {
      await ApiService.tandaiSemuaNotifikasiDibaca();
    } catch (_) {}
  }
}
