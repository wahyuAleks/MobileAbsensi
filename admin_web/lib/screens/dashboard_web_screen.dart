import 'package:flutter/material.dart';
import '../core/notifikasi_service.dart';
import 'components/admin_sidebar.dart';
import 'components/admin_header.dart';
import 'components/notifikasi_sheet.dart';

import 'home_admin_screen.dart';
import 'data_karyawan_screen.dart';
import 'monitoring_absensi_screen.dart';
import 'rekap_absensi_screen.dart';
import 'persetujuan_cuti_screen.dart';
import 'rekap_laporan_screen.dart';
import 'profile_admin_screen.dart';
import 'jadwal_karyawan_screen.dart';
import 'jenis_kegiatan_screen.dart';

class DashboardWebScreen extends StatefulWidget {
  final int initialIndex;

  const DashboardWebScreen({super.key, this.initialIndex = 0});

  @override
  State<DashboardWebScreen> createState() => _DashboardWebScreenState();
}

class _DashboardWebScreenState extends State<DashboardWebScreen>
    with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _index;
  final List<String> _titles = const [
    'Dashboard',
    'Data Karyawan',
    'Monitoring Absensi',
    'Rekap Absensi',
    'Persetujuan Cuti',
    'Rekap Laporan',
    'Profil Admin',
  ];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    WidgetsBinding.instance.addObserver(this);
    NotifikasiService.startRealtime();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      NotifikasiService.startRealtime();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotifikasiService.stopRealtime();
    super.dispose();
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
    final screens = [
      HomeAdminScreen(
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaRekapAbsensi: () => _pindahTab(2),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      DataKaryawanScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaRekapAbsensi: () => _pindahTab(2),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      MonitoringAbsensiScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      RekapAbsensiScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      PersetujuanCutiScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaProfil: () => _pindahTab(8),
        onBukaRekapAbsensi: () => _pindahTab(2),
      ),
      RekapLaporanScreen(
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaProfil: () => _pindahTab(8),
      ),
      const JadwalKaryawanScreen(),
      const JenisKegiatanScreen(),
      ProfileAdminScreen(
        showAppBar: false,
        onBukaRekapAbsensi: () => _pindahTab(2),
      ),
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F7FB),
      body: Row(
        children: [
          AdminSidebar(
            selectedIndex: _index,
            onItemSelected: _pindahTab,
            onOpenNotifikasi: _bukaNotifikasi,
            onBukaProfil: () => _pindahTab(8),
          ),
          Expanded(
            child: Column(
              children: [
                AdminHeader(
                  title: _titles[_index],
                  onOpenNotifikasi: _bukaNotifikasi,
                  onBukaProfil: () => _pindahTab(6),
                ),
                Expanded(
                  child: IndexedStack(
                    index: _index,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
