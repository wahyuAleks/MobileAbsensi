import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import 'components/month_picker_widget.dart';

class RekapAbsensiScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaKaryawan;
  final VoidCallback? onBukaPersetujuanCuti;
  final VoidCallback? onBukaProfil;

  const RekapAbsensiScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaKaryawan,
    this.onBukaPersetujuanCuti,
    this.onBukaProfil,
  });

  @override
  State<RekapAbsensiScreen> createState() => _RekapAbsensiScreenState();
}

class _RekapAbsensiScreenState extends State<RekapAbsensiScreen> {
  int _bulan = DateTime.now().month;
  int _tahun = DateTime.now().year;
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    setState(() {
      _future = ApiService.rekapAbsensiAdmin(bulan: _bulan, tahun: _tahun);
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
                const Text(
                  'Rekapitulasi Bulanan Absensi',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                MonthPickerWidget(
                  bulan: _bulan,
                  tahun: _tahun,
                  onChanged: (b, y) {
                    setState(() {
                      _bulan = b;
                      _tahun = y;
                    });
                    _muat();
                  },
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
                          Expanded(flex: 2, child: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 3, child: Text('KARYAWAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('MASUK', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('PULANG', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                        ],
                      ),
                      const Divider(height: 24),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(child: Text('Tidak ada data rekapitulasi absensi untuk bulan ini.', style: TextStyle(color: Colors.grey))),
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
                            final tgl = (item['tanggal'] ?? '-').toString();
                            final jamMasuk = (item['jam_masuk'] ?? '-').toString();
                            final jamPulang = (item['jam_pulang'] ?? '-').toString();
                            final isTerlambat = (item['status'] ?? '').toString().toLowerCase().contains('terlambat');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(tgl, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Expanded(flex: 3, child: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                  Expanded(flex: 2, child: Text(jamMasuk, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                  Expanded(flex: 2, child: Text(jamPulang, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B)))),
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
