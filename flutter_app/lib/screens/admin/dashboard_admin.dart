import 'package:flutter/material.dart';
import '../../core/constants.dart';
import 'home_admin_screen.dart';
import 'data_karyawan_screen.dart';
import 'monitoring_absensi_screen.dart';
import 'rekap_absensi_screen.dart';
import 'persetujuan_cuti_screen.dart';
import 'rekap_laporan_screen.dart';
import 'profile_admin_screen.dart';
import 'lokasi_jam_masuk_screen.dart';
import 'components/admin_sidebar.dart';
import 'components/notifikasi_sheet.dart';

class DashboardAdmin extends StatefulWidget {
  final int initialIndex;

  const DashboardAdmin({super.key, this.initialIndex = 0});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _index;

  final _titles = const [
    'Dashboard',
    'Data Karyawan',
    'Monitoring Absensi',
    'Rekap Absensi',
    'Persetujuan cuti',
    'Rekap laporan',
    'Lokasi & Jam Masuk',
    'Profil Admin',
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _pindahTab(int i) {
    if (mounted) {
      setState(() => _index = i);
    }
  }

  Future<void> _bukaNotifikasi() async {
    await NotifikasiSheet.show(
      context,
      jumlahCutiMenunggu: 3,
      jumlahBelumAbsen: 5,
      jumlahTerlambat: 2,
      onTapCuti: () => _pindahTab(4),
      onTapBelumAbsen: () => _pindahTab(2),
      onTapTerlambat: () => _pindahTab(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    const primary = AppConstants.primaryColor;

    final screens = [
      // 0. Dashboard Home Screen persis sesuai desain mockup
      HomeAdminScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaRekapAbsensi: () => _pindahTab(2),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(7),
      ),
      // 1. Data Karyawan
      DataKaryawanScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaRekapAbsensi: () => _pindahTab(2),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(7),
      ),
      // 2. Monitoring Absensi
      MonitoringAbsensiScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(7),
      ),
      // 3. Rekap Absensi
      RekapAbsensiScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(7),
      ),
      // 4. Persetujuan Cuti
      PersetujuanCutiScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaProfil: () => _pindahTab(7),
        onBukaRekapAbsensi: () => _pindahTab(2),
      ),
      // 5. Rekap Laporan
      RekapLaporanScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaProfil: () => _pindahTab(7),
      ),
      // 6. Pengelolaan Lokasi & Jam Masuk
      LokasiJamMasukScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onBack: () => _pindahTab(0),
      ),
      // 7. Profil Admin
      ProfileAdminScreen(
        showAppBar: false,
        onBukaRekapAbsensi: () => _pindahTab(2),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF9FAFB),

      // Appbar hanya ditampilkan untuk tab yang belum punya floating top bar tersendiri
      appBar: (_index == 0 ||
              _index == 1 ||
              _index == 2 ||
              _index == 3 ||
              _index == 4 ||
              _index == 5 ||
              _index == 6)
          ? null
          : AppBar(
              title: Text(
                _titles[_index],
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              backgroundColor: primary,
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu_rounded, size: 26),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
              actions: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, size: 24),
                      onPressed: _bukaNotifikasi,
                    ),
                    Positioned(
                      top: 10,
                      right: 12,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
              ],
            ),

      // Sidebar Navigasi samping (Drawer)
      drawer: AdminDrawer(
        selectedIndex: _index,
        onItemSelected: _pindahTab,
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaProfil: () => _pindahTab(7),
      ),

      // Konten Layar
      body: IndexedStack(
        index: _index,
        children: screens,
      ),
    );
  }
}
