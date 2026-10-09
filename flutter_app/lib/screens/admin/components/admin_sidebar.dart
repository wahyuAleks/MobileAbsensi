import 'package:flutter/material.dart';
import '../../../core/session.dart';
import '../../login_screen.dart';

/// Sidebar Drawer Navigasi Admin
/// Dibuat persis 100% sesuai screenshot mockup:
/// - Background ungu-indigo solid (#4C58A5) dengan sudut kanan melengkung
/// - Header: Icon Gear settings + 'Absensiku' & 'Admin Panel'
/// - Menu navigasi admin:
///   1. Dashboard
///   2. Data Karyawan
///   3. Monitoring Absensi
///   4. Rekap Absensi
///   5. Persetujuan cuti
///   6. Rekap laporan
/// - State aktif: Background highlight ungu muda edge-to-edge
/// - Profil Admin: Avatar 'SA' + 'Super Admin' & 'Administrator'
/// - Tombol Keluar: Bentuk kapsul pill dengan icon open-in-new
class AdminDrawer extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onOpenNotifikasi;
  final VoidCallback? onBukaProfil;

  const AdminDrawer({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onOpenNotifikasi,
    this.onBukaProfil,
  });

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  String _namaAdmin = 'Super Admin';
  String _roleAdmin = 'Administrator';

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    final nama = await Session.getNama();
    final role = await Session.getRole();
    if (mounted) {
      setState(() {
        if (nama != null && nama.isNotEmpty) _namaAdmin = nama;
        if (role != null && role.isNotEmpty) {
          _roleAdmin = role == 'admin' ? 'Administrator' : role;
        }
      });
    }
  }

  Future<void> _logout(BuildContext context) async {
    final nav = Navigator.of(context);
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin keluar dari akun Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Batal', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout',
                style: TextStyle(color: Color(0xFFDC2626))),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;
    await Session.logout();
    if (!mounted) return;
    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = [
      {'title': 'Dashboard', 'icon': Icons.home_rounded},
      {'title': 'Data Karyawan', 'icon': Icons.groups_rounded},
      {'title': 'Monitoring Absensi', 'icon': Icons.bar_chart_rounded},
      {'title': 'Rekap Absensi', 'icon': Icons.calendar_month_rounded},
      {'title': 'Persetujuan cuti', 'icon': Icons.assignment_rounded},
      {'title': 'Rekap laporan', 'icon': Icons.description_rounded},
      {'title': 'Jadwal Karyawan', 'icon': Icons.calendar_month_rounded},
      {'title': 'Master Jenis Kegiatan', 'icon': Icons.category_rounded},
    ];

    return Drawer(
      width: 270,
      backgroundColor: const Color(0xFF4C58A5),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header: Icon Settings Lingkaran + Absensiku & Admin Panel
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: const Icon(
                      Icons.settings_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Absensiku',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Admin Panel',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Garis Pembatas Header
            Divider(
              height: 1,
              thickness: 1,
              color: Colors.white.withValues(alpha: 0.2),
            ),

            // 2. Daftar Menu Vertikal (6 Menu Sesuai Mockup)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: menuItems.length,
                itemBuilder: (context, i) {
                  final item = menuItems[i];
                  final isSelected = widget.selectedIndex == i;

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).pop(); // Tutup drawer
                      widget.onItemSelected(i);
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.22)
                            : Colors.transparent,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item['icon'] as IconData,
                            size: 22,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // 3. User Profil Admin (Super Admin / Administrator)
            InkWell(
              onTap: () {
                Navigator.of(context).pop();
                widget.onBukaProfil?.call();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: const BoxDecoration(
                        color: Color(0xFF386B7B), // Teal / Cyan sesuai mockup
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'SA',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _namaAdmin,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _roleAdmin,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Tombol 'Keluar' Sesuai Mockup
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: InkWell(
                onTap: () => _logout(context),
                borderRadius: BorderRadius.circular(22),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Keluar',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.open_in_new_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 19,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
