import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../core/notifikasi_service.dart';

class NotifikasiSheet extends StatelessWidget {
  final VoidCallback? onTapCuti;
  final VoidCallback? onTapBelumAbsen;
  final VoidCallback? onTapTerlambat;

  const NotifikasiSheet({
    super.key,
    this.onTapCuti,
    this.onTapBelumAbsen,
    this.onTapTerlambat,
  });

  static Future<void> show(
    BuildContext context, {
    int jumlahCutiMenunggu = 0,
    int jumlahBelumAbsen = 0,
    int jumlahTerlambat = 0,
    VoidCallback? onTapCuti,
    VoidCallback? onTapBelumAbsen,
    VoidCallback? onTapTerlambat,
  }) async {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 480,
          child: NotifikasiSheet(
            onTapCuti: onTapCuti,
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
              const Row(
                children: [
                  Icon(Icons.notifications_active_rounded,
                      color: AppConstants.primaryColor),
                  SizedBox(width: 8),
                  Text(
                    'Pemberitahuan Admin',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: const Text('Tidak ada pemberitahuan baru.',
                      style: TextStyle(color: Colors.grey)),
                );
              }
              return Container(
                constraints: const BoxConstraints(maxHeight: 360),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final item = items[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: item.tipe == 'cuti'
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFE0E7FF),
                        child: Icon(
                          item.tipe == 'cuti'
                              ? Icons.assignment
                              : Icons.info_outline,
                          color: item.tipe == 'cuti'
                              ? Colors.amber[800]
                              : AppConstants.primaryColor,
                          size: 20,
                        ),
                      ),
                      title: Text(item.judul,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(item.pesan,
                          style: const TextStyle(fontSize: 12)),
                      trailing: Text(item.waktu,
                          style: const TextStyle(
                              fontSize: 11, color: Colors.grey)),
                      onTap: () {
                        NotifikasiService.markAsRead(item.id);
                        Navigator.pop(context);
                        if (item.tipe == 'cuti') {
                          onTapCuti?.call();
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                NotifikasiService.markAllAsRead();
              },
              child: const Text('Tandai Semua Dibaca'),
            ),
          ),
        ],
      ),
    );
  }
}
