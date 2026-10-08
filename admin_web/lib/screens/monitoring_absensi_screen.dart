import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

class MonitoringAbsensiScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaKaryawan;
  final VoidCallback? onBukaPersetujuanCuti;
  final VoidCallback? onBukaProfil;

  const MonitoringAbsensiScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaKaryawan,
    this.onBukaPersetujuanCuti,
    this.onBukaProfil,
  });

  @override
  State<MonitoringAbsensiScreen> createState() => _MonitoringAbsensiScreenState();
}

class _MonitoringAbsensiScreenState extends State<MonitoringAbsensiScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    final tglHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
    setState(() {
      _future = ApiService.rekapAbsensiAdmin(tanggal: tglHariIni);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Monitoring Absensi Real-Time Hari Ini',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now()),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _muat,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                final list = snap.data ?? [];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(flex: 3, child: Text('KARYAWAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('JAM MASUK', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('JAM PULANG', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('LOKASI / GPS', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                        ],
                      ),
                      const Divider(height: 24),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(child: Text('Belum ada data absensi tercatat hari ini.', style: TextStyle(color: Colors.grey))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = list[i];
                            final user = item['User'] ?? {};
                            final nama = (user['nama'] ?? 'Karyawan').toString();
                            final jamMasuk = (item['jam_masuk'] ?? '-').toString();
                            final jamPulang = (item['jam_pulang'] ?? '-').toString();
                            final isTerlambat = (item['status'] ?? '').toString().toLowerCase().contains('terlambat');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: AppConstants.primaryColor,
                                          child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : 'K', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 2, child: Text(jamMasuk, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                  Expanded(flex: 2, child: Text(jamPulang, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B)))),
                                  const Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.location_on, color: Colors.green, size: 16),
                                        SizedBox(width: 4),
                                        Text('Valid Office', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isTerlambat ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isTerlambat ? 'Terlambat' : 'Tepat Waktu',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isTerlambat ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
