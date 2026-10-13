import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'jadwal_absensi_screen.dart';
import 'riwayat_absen_screen.dart';
import 'laporan_screen.dart';
import 'profile_screen.dart';
import '../../core/constants.dart';
import '../../core/app_events.dart';

class DashboardKaryawan extends StatefulWidget {
  final int initialIndex;
  const DashboardKaryawan({super.key, this.initialIndex = 0});

  @override
  State<DashboardKaryawan> createState() => _DashboardKaryawanState();
}

class _DashboardKaryawanState extends State<DashboardKaryawan> {
  late int _index;
  final List<int> _tabHistory = [];

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
  }

  void _pindahTab(int index) {
    if (index == _index) return;
    if (index == 0) {
      _tabHistory.clear();
    } else {
      _tabHistory.add(_index);
    }
    setState(() => _index = index);
  }

  void _kembali() {
    if (_tabHistory.isEmpty && Navigator.of(context).canPop()) {
      Navigator.of(context).maybePop();
      return;
    }
    final previousIndex = _tabHistory.isNotEmpty ? _tabHistory.removeLast() : 0;
    if (previousIndex == 0) _tabHistory.clear();
    setState(() => _index = previousIndex);
  }

  @override
  Widget build(BuildContext context) {
    final screens = [
      HomeScreen(onOpenAbsensi: () => _pindahTab(1)),
      JadwalAbsensiScreen(onBack: _kembali),
      RiwayatAbsenScreen(onBack: _kembali),
      LaporanScreen(onBack: _kembali),
      ProfileScreen(onBack: _kembali),
    ];
    return PopScope<Object?>(
      canPop: _index == 0 ||
          (_tabHistory.isEmpty && Navigator.of(context).canPop()),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index != 0) _kembali();
      },
      child: Scaffold(
        body: IndexedStack(index: _index, children: screens),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) {
            _pindahTab(i);
            if (i == 0) {
              // Kembali ke Home -> Segarkan profil & status absensi
              AppEvents.notifyProfileUpdated();
              AppEvents.notifyAttendanceUpdated();
            } else if (i == 2) {
              // Pindah ke Riwayat -> Segarkan riwayat absensi terbaru
              AppEvents.notifyAttendanceUpdated();
            }
          },
          indicatorColor: AppConstants.primaryColor.withValues(alpha: 0.15),
          backgroundColor: Colors.white,
          elevation: 4,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppConstants.primaryColor),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon:
                  Icon(Icons.calendar_month, color: AppConstants.primaryColor),
              label: 'Absensi',
            ),
            NavigationDestination(
              icon: Icon(Icons.access_time),
              selectedIcon: Icon(Icons.access_time_filled,
                  color: AppConstants.primaryColor),
              label: 'Riwayat',
            ),
            NavigationDestination(
              icon: Icon(Icons.description_outlined),
              selectedIcon:
                  Icon(Icons.description, color: AppConstants.primaryColor),
              label: 'Laporan',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon:
                  Icon(Icons.person, color: AppConstants.primaryColor),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
