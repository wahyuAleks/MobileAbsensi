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
  final List<int> _pageKeys = List<int>.filled(9, 0);

  final List<String> _titles = const [
    'Dashboard',
    'Data Karyawan',
    'Monitoring Absensi',
    'Rekap Absensi',
    'Persetujuan Cuti',
    'Rekap Laporan',
    'Jadwal Karyawan',
    'Master Jenis Kegiatan',
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
      _refreshCurrentTab();
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
      setState(() {
        _index = i;
        _pageKeys[i]++; // Setiap pindah tab, refresh data screen tujuan secara real-time
      });
    }
  }

  void _refreshCurrentTab() {
    if (mounted) {
      setState(() {
        _pageKeys[_index]++;
      });
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Memperbarui data halaman...'),
          duration: Duration(milliseconds: 800),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _bukaNotifikasi() async {
    await NotifikasiSheet.show(
      context,
      jumlahCutiMenunggu: 3,
      jumlahBelumAbsen: 5,
      jumlahTerlambat: 2,
      onTapCuti: () => _pindahTab(4),
      onTapLaporan: () => _pindahTab(5),
      onTapAbsen: () => _pindahTab(2),
      onTapBelumAbsen: () => _pindahTab(2),
      onTapTerlambat: () => _pindahTab(2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeAdminScreen(
        key: ValueKey('home_${_pageKeys[0]}'),
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaRekapAbsensi: () => _pindahTab(2),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      DataKaryawanScreen(
        key: ValueKey('karyawan_${_pageKeys[1]}'),
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaRekapAbsensi: () => _pindahTab(2),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      MonitoringAbsensiScreen(
        key: ValueKey('monitoring_${_pageKeys[2]}'),
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      RekapAbsensiScreen(
        key: ValueKey('rekap_absensi_${_pageKeys[3]}'),
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaKaryawan: () => _pindahTab(1),
        onBukaPersetujuanCuti: () => _pindahTab(4),
        onBukaProfil: () => _pindahTab(8),
      ),
      PersetujuanCutiScreen(
        key: ValueKey('cuti_${_pageKeys[4]}'),
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaProfil: () => _pindahTab(8),
        onBukaRekapAbsensi: () => _pindahTab(2),
      ),
      RekapLaporanScreen(
        key: ValueKey('laporan_${_pageKeys[5]}'),
        showAppBar: false,
        onOpenDrawer: () => _scaffoldKey.currentState?.openDrawer(),
        onOpenNotifikasi: _bukaNotifikasi,
        onBukaProfil: () => _pindahTab(8),
      ),
      const JadwalKaryawanScreen(),
      const JenisKegiatanScreen(),
      ProfileAdminScreen(
        key: ValueKey('profile_${_pageKeys[8]}'),
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
                  onBukaProfil: () => _pindahTab(8),
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
