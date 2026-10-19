import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/notifikasi_service.dart';

class NotifikasiSheet extends StatelessWidget {
  final VoidCallback? onTapCuti;
  final VoidCallback? onTapLaporan;
  final VoidCallback? onTapAbsen;
  final VoidCallback? onTapBelumAbsen;
  final VoidCallback? onTapTerlambat;

  const NotifikasiSheet({
    super.key,
    this.onTapCuti,
    this.onTapLaporan,
    this.onTapAbsen,
    this.onTapBelumAbsen,
    this.onTapTerlambat,
  });

  static Future<void> show(
    BuildContext context, {
    int jumlahCutiMenunggu = 0,
    int jumlahBelumAbsen = 0,
    int jumlahTerlambat = 0,
    VoidCallback? onTapCuti,
    VoidCallback? onTapLaporan,
    VoidCallback? onTapAbsen,
    VoidCallback? onTapBelumAbsen,
    VoidCallback? onTapTerlambat,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 520,
          child: NotifikasiSheet(
            onTapCuti: onTapCuti,
            onTapLaporan: onTapLaporan,
            onTapAbsen: onTapAbsen,
            onTapBelumAbsen: onTapBelumAbsen,
            onTapTerlambat: onTapTerlambat,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.notifications_active_rounded,
                        color: AppConstants.primaryColor, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pemberitahuan & Aktivitas',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A)),
                      ),
                      Text(
                        'Aktivitas karyawan terkini (Real-time)',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Color(0xFF94A3B8)),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<String?>(
            valueListenable: NotifikasiService.errorNotifier,
            builder: (context, error, _) {
              if (error == null) return const SizedBox.shrink();
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Text(
                  error,
                  style: const TextStyle(
                    color: Color(0xFF9A3412),
                    fontSize: 12,
                  ),
                ),
              );
            },
          ),
          ValueListenableBuilder<List<NotifikasiItem>>(
            valueListenable: NotifikasiService.itemsNotifier,
            builder: (context, items, _) {
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 44, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 10),
                      Text(
                        'Tidak ada pemberitahuan baru.',
                        style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Semua aktivitas karyawan akan muncul di sini secara langsung.',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
                      ),
                    ],
                  ),
                );
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 400),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1, color: Color(0xFFF1F5F9)),
                  itemBuilder: (context, i) {
                    final item = items[i];

                    Color iconBg;
                    Color iconColor;
                    IconData iconData;
                    String badgeLabel;
                    Color badgeBg;
                    Color badgeText;

                    switch (item.tipe) {
                      case 'laporan':
                        iconBg = const Color(0xFFFFF7ED);
                        iconColor = const Color(0xFFEA580C);
                        iconData = Icons.assignment_rounded;
                        badgeLabel = 'Laporan';
                        badgeBg = const Color(0xFFFFEDD5);
                        badgeText = const Color(0xFFC2410C);
                        break;
                      case 'cuti':
                        iconBg = const Color(0xFFEFF6FF);
                        iconColor = const Color(0xFF2563EB);
                        iconData = Icons.beach_access_rounded;
                        badgeLabel = 'Cuti';
                        badgeBg = const Color(0xFFDBEAFE);
                        badgeText = const Color(0xFF1D4ED8);
                        break;
                      case 'absen':
                        iconBg = const Color(0xFFF0FDF4);
                        iconColor = const Color(0xFF16A34A);
                        iconData = Icons.access_time_filled_rounded;
                        badgeLabel = 'Absensi';
                        badgeBg = const Color(0xFFDCFCE7);
                        badgeText = const Color(0xFF15803D);
                        break;
                      case 'info':
                      default:
                        iconBg = const Color(0xFFF5F3FF);
                        iconColor = const Color(0xFF7C3AED);
                        iconData = Icons.campaign_rounded;
                        badgeLabel = 'Info';
                        badgeBg = const Color(0xFFEDE9FE);
                        badgeText = const Color(0xFF6D28D9);
                        break;
                    }

                    final bool isUnread = !item.isRead;

                    return Container(
                      decoration: BoxDecoration(
                        color: isUnread
                            ? AppConstants.primaryColor.withValues(alpha: 0.04)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        leading: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            CircleAvatar(
                              backgroundColor: iconBg,
                              radius: 20,
                              child: Icon(iconData, color: iconColor, size: 20),
                            ),
                            if (isUnread)
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeBg,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                badgeLabel,
                                style: TextStyle(
                                    color: badgeText,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                item.judul,
                                style: TextStyle(
                                  fontWeight: isUnread
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                  fontSize: 13,
                                  color: isUnread
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFF334155),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.pesan,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isUnread
                                      ? const Color(0xFF1E293B)
                                      : const Color(0xFF64748B),
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.access_time_rounded,
                                      size: 11, color: Color(0xFF94A3B8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.waktu,
                                    style: const TextStyle(
                                        fontSize: 11, color: Color(0xFF94A3B8)),
                                  ),
                                  if (item.ctaText != null) ...[
                                    const Spacer(),
                                    Text(
                                      item.ctaText!,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: AppConstants.primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () {
                          NotifikasiService.markAsRead(item.id);
                          Navigator.pop(context);
                          if (item.tipe == 'cuti') {
                            onTapCuti?.call();
                          } else if (item.tipe == 'laporan') {
                            onTapLaporan?.call();
                          } else if (item.tipe == 'absen') {
                            onTapAbsen?.call();
                          }
                        },
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: NotifikasiService.realtimeConnectedNotifier,
                builder: (context, connected, _) {
                  return Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: connected
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFF59E0B),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        connected ? 'Real-time aktif' : 'Menghubungkan...',
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ],
                  );
                },
              ),
              TextButton.icon(
                onPressed: () {
                  NotifikasiService.markAllAsRead();
                },
                icon: const Icon(Icons.done_all_rounded, size: 16),
                label: const Text('Tandai Semua Dibaca'),
                style: TextButton.styleFrom(
                  foregroundColor: AppConstants.primaryColor,
                  textStyle: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
