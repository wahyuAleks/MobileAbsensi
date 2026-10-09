import 'package:flutter/material.dart';
import '../../core/notifikasi_service.dart';

class AdminHeader extends StatelessWidget {
  final String title;
  final VoidCallback onOpenNotifikasi;
  final VoidCallback onBukaProfil;

  const AdminHeader({
    super.key,
    required this.title,
    required this.onOpenNotifikasi,
    required this.onBukaProfil,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumb text: AbsensiKu  >  Dashboard
          Row(
            children: [
              const Text(
                'AbsensiKu',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF6B7280),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Icon(Icons.chevron_right_rounded, size: 18, color: Color(0xFF9CA3AF)),
              ),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
            ],
          ),
          const Spacer(),

          ValueListenableBuilder<bool>(
            valueListenable: NotifikasiService.realtimeConnectedNotifier,
            builder: (context, isConnected, _) {
              return ValueListenableBuilder<int>(
                valueListenable: NotifikasiService.unreadCountNotifier,
                builder: (context, unreadCount, _) {
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_rounded,
                            size: 24, color: Color(0xFF6B7280)),
                        onPressed: onOpenNotifikasi,
                        tooltip: isConnected
                            ? 'Notifikasi (real-time aktif)'
                            : 'Notifikasi (menghubungkan...)',
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: 3,
                          right: 1,
                          child: Container(
                            constraints: const BoxConstraints(minWidth: 16),
                            height: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEF4444),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unreadCount > 99 ? '99+' : '$unreadCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      else if (!isConnected)
                        Positioned(
                          top: 7,
                          right: 5,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFFF59E0B),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 8),

          // Circle SA Profile Avatar
          GestureDetector(
            onTap: onBukaProfil,
            child: Container(
              width: 30,
              height: 30,
              decoration: const BoxDecoration(
                color: Color(0xFF385C83),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Text(
                'SA',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
