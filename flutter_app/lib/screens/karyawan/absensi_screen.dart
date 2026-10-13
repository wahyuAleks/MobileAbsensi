import 'package:flutter/material.dart';
import 'jadwal_absensi_screen.dart';

class AbsensiScreen extends StatelessWidget {
  final bool initialIsMasuk;
  final bool isStandalone;

  const AbsensiScreen({
    super.key,
    this.initialIsMasuk = true,
    this.isStandalone = false,
  });

  @override
  Widget build(BuildContext context) => const JadwalAbsensiScreen();
}
