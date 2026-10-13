import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../core/notifikasi_service.dart';
import '../jadwal_absensi_screen.dart';
import '../pengajuan_cuti_screen.dart';
import '../laporan_screen.dart';

/// Modal Popup Notifikasi Karyawan
/// Menampilkan daftar notifikasi dengan:
/// - Kategori filter tab (Semua, Absensi, Cuti, Laporan)
/// - Pembeda visual notifikasi baru (unread) vs sudah dibaca (read)
/// - Tombol "Tandai Semua Dibaca"
/// - Navigasi langsung (deep-link): Absen -> daftar slot kerja, Cuti -> PengajuanCutiScreen, Laporan -> LaporanScreen
class NotifikasiKaryawanPopup extends StatefulWidget {
  final VoidCallback? onTapCuti;
  final VoidCallback? onTapLaporan;
  final VoidCallback? onTapAbsen;

  const NotifikasiKaryawanPopup({
    super.key,
    this.onTapCuti,
    this.onTapLaporan,
    this.onTapAbsen,
  });

  /// Helper untuk menampilkan popup Notifikasi (Dialog Modal Responsif)
  static Future<void> show(
    BuildContext context, {
    VoidCallback? onTapCuti,
    VoidCallback? onTapLaporan,
    VoidCallback? onTapAbsen,
  }) {
    // Pastikan service terinisialisasi
    NotifikasiService.init();

    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.45),
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        elevation: 0,
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: NotifikasiKaryawanPopup(
              onTapCuti: onTapCuti,
              onTapLaporan: onTapLaporan,
              onTapAbsen: onTapAbsen,
            ),
          ),
        ),
      ),
    );
  }

  /// Helper alternatif untuk menampilkan sebagai Bottom Sheet modern
  static Future<void> showBottomSheet(
    BuildContext context, {
    VoidCallback? onTapCuti,
    VoidCallback? onTapLaporan,
    VoidCallback? onTapAbsen,
  }) {
    NotifikasiService.init();

    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(26),
            topRight: Radius.circular(26),
          ),
        ),
        child: SafeArea(
          child: NotifikasiKaryawanPopup(
            onTapCuti: onTapCuti,
            onTapLaporan: onTapLaporan,
            onTapAbsen: onTapAbsen,
          ),
        ),
      ),
    );
  }

  @override
  State<NotifikasiKaryawanPopup> createState() =>
      _NotifikasiKaryawanPopupState();
}

class _NotifikasiKaryawanPopupState extends State<NotifikasiKaryawanPopup> {
  // Tab kategori terpilih: 'semua', 'absen', 'cuti', 'laporan'
  String _activeCategory = 'semua';

  @override
  void initState() {
    super.initState();
    NotifikasiService.syncFromBackend();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return ValueListenableBuilder<List<NotifikasiItem>>(
      valueListenable: NotifikasiService.itemsNotifier,
      builder: (context, allItems, _) {
        final unreadCount = allItems.where((it) => !it.isRead).length;

        // Filter item berdasarkan kategori
        final filteredItems = allItems.where((it) {
          if (_activeCategory == 'semua') return true;
          return it.tipe == _activeCategory;
        }).toList();

        return Container(
          height: screenHeight * 0.82,
          constraints: BoxConstraints(
            maxHeight: screenHeight * 0.82,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            children: [
              // 1. HEADER MODAL
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
                child: Row(
                  children: [
                    // Ikon Lonceng + Judul
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppConstants.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.notifications_active_rounded,
                        color: AppConstants.primaryColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Notifikasi',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Badge angka belum dibaca jika ada
                    if (unreadCount > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$unreadCount baru',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                    const Spacer(),

                    // Tombol 'Tandai Dibaca' cepat
                    if (unreadCount > 0)
                      InkWell(
                        onTap: () {
                          NotifikasiService.markAllAsRead();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Semua notifikasi ditandai dibaca'),
                              duration: Duration(seconds: 2),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: const Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            'Tandai dibaca',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppConstants.primaryColor,
                            ),
                          ),
                        ),
                      ),

                    // Tombol Close (X)
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. KATEGORI FILTER CHIPS (Semua, Absensi, Cuti, Laporan)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip(
                        id: 'semua',
                        label: 'Semua',
                        total: allItems.length,
                        unread: unreadCount,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        id: 'absen',
                        label: 'Absensi',
                        total: allItems.where((e) => e.tipe == 'absen').length,
                        unread: allItems
                            .where((e) => e.tipe == 'absen' && !e.isRead)
                            .length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        id: 'cuti',
                        label: 'Cuti',
                        total: allItems.where((e) => e.tipe == 'cuti').length,
                        unread: allItems
                            .where((e) => e.tipe == 'cuti' && !e.isRead)
                            .length,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterChip(
                        id: 'laporan',
                        label: 'Laporan',
                        total:
                            allItems.where((e) => e.tipe == 'laporan').length,
                        unread: allItems
                            .where((e) => e.tipe == 'laporan' && !e.isRead)
                            .length,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF3F4F6)),

              // 3. DAFTAR KARTU NOTIFIKASI
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(child: _buildEmptyState())
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        itemCount: filteredItems.length,
                        separatorBuilder: (ctx, i) =>
                            const SizedBox(height: 10),
                        itemBuilder: (ctx, index) {
                          final item = filteredItems[index];
                          return _buildNotificationCard(item);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Chip filter kategori
  Widget _buildFilterChip({
    required String id,
    required String label,
    required int total,
    required int unread,
  }) {
    final bool isSelected = _activeCategory == id;
    const primaryColor = AppConstants.primaryColor;

    return InkWell(
      onTap: () => setState(() => _activeCategory = id),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$unread',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? primaryColor : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Desain kartu notifikasi yang bersih, jelas, ramah & interaktif
  Widget _buildNotificationCard(NotifikasiItem item) {
    // Styling warna & ikon berdasarkan tipe notifikasi
    Color iconBgColor;
    Color iconCircleColor;
    IconData iconData;
    String defaultCta;

    switch (item.tipe) {
      case 'absen':
        iconBgColor = const Color(0xFFE8F5E9);
        iconCircleColor = const Color(0xFF2E7D32);
        iconData = Icons.access_time_filled_rounded;
        defaultCta = 'Buka Halaman Absensi →';
        break;
      case 'cuti':
        iconBgColor = const Color(0xFFE0F2FE);
        iconCircleColor = const Color(0xFF0284C7);
        iconData = Icons.beach_access_rounded;
        defaultCta = 'Lihat Status Cuti →';
        break;
      case 'laporan':
        iconBgColor = const Color(0xFFFFF3E0);
        iconCircleColor = const Color(0xFFF57C00);
        iconData = Icons.assignment_rounded;
        defaultCta = 'Tulis Laporan Sekarang →';
        break;
      case 'info':
      default:
        iconBgColor = const Color(0xFFEDE9FE);
        iconCircleColor = const Color(0xFF7C3AED);
        iconData = Icons.campaign_rounded;
        defaultCta = 'Lihat Informasi Lengkap →';
        break;
    }

    final isUnread = !item.isRead;
    final ctaText = item.ctaText ?? defaultCta;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _handleItemTap(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            // Notif belum dibaca memiliki latar putih bersih + border halus
            // Notif sudah dibaca memiliki latar netral lembut
            color: isUnread ? Colors.white : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread
                  ? AppConstants.primaryColor.withValues(alpha: 0.35)
                  : const Color(0xFFE2E8F0),
              width: isUnread ? 1.2 : 1.0,
            ),
            boxShadow: isUnread
                ? [
                    BoxShadow(
                      color: AppConstants.primaryColor.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kotak Ikon Kiri (44 x 44)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBgColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: iconCircleColor,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        iconData,
                        color: Colors.white,
                        size: 15,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Teks Notifikasi (Judul, Badge 'Baru', Pesan, Waktu)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.judul,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  color: isUnread
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF334155),
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (isUnread) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444)
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'BARU',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFEF4444),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.pesan,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isUnread
                                ? const Color(0xFF374151)
                                : const Color(0xFF64748B),
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 12,
                              color: Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              item.waktu,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF94A3B8),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Call-To-Action (CTA) Hint yang ramah & jelas di bawah kartu
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isUnread
                      ? AppConstants.primaryColor.withValues(alpha: 0.05)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_outlined,
                      size: 13,
                      color: isUnread
                          ? AppConstants.primaryColor
                          : const Color(0xFF64748B),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        ctaText,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isUnread
                              ? AppConstants.primaryColor
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 11,
                      color: isUnread
                          ? AppConstants.primaryColor
                          : const Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Empty state yang hangat & informatif saat tidak ada notifikasi
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.notifications_off_outlined,
              size: 28,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Belum Ada Notifikasi',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Semua pemberitahuan pada kategori ini sudah kamu baca atau belum tersedia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  /// Tangani klik notifikasi: tandai dibaca & buka rute layar yang tepat
  void _handleItemTap(NotifikasiItem item) {
    // 1. Tandai item sebagai sudah dibaca
    NotifikasiService.markAsRead(item.id);

    // 2. Tutup popup modal
    Navigator.of(context).pop();

    // 3. Jika ada callback khusus, jalankan
    if (item.onTap != null) {
      item.onTap!();
      return;
    }

    // 4. Navigasi cerdas berdasarkan jenis notifikasi
    switch (item.tipe) {
      case 'absen':
        if (widget.onTapAbsen != null) {
          widget.onTapAbsen!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const JadwalAbsensiScreen(),
            ),
          );
        }
        break;

      case 'cuti':
        if (widget.onTapCuti != null) {
          widget.onTapCuti!();
        } else {
          // Buka langsung ke Tab 1: Status & Riwayat Cuti
          final int tabIndex = item.data?['tabIndex'] ?? 1;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PengajuanCutiScreen(initialTabIndex: tabIndex),
            ),
          );
        }
        break;

      case 'laporan':
        if (widget.onTapLaporan != null) {
          widget.onTapLaporan!();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const LaporanScreen()),
          );
        }
        break;

      case 'info':
      default:
        // Tampilkan dialog informasi operasional
        _showInfoDetailDialog(item);
        break;
    }
  }

  /// Dialog detail untuk pengumuman atau info kantor
  void _showInfoDetailDialog(NotifikasiItem item) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.campaign_rounded,
                color: Color(0xFF7C3AED),
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                item.judul,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.pesan,
              style: const TextStyle(fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 12),
            Text(
              'Waktu: ${item.waktu}',
              style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Tutup',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
