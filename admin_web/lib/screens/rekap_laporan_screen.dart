import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

class RekapLaporanScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaProfil;

  const RekapLaporanScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaProfil,
  });

  @override
  State<RekapLaporanScreen> createState() => _RekapLaporanScreenState();
}

class _RekapLaporanScreenState extends State<RekapLaporanScreen> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    setState(() {
      _future = ApiService.rekapLaporan();
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
                  'Rekapitulasi Laporan Harian Karyawan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
                          Expanded(flex: 2, child: Text('TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 3, child: Text('KARYAWAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 3, child: Text('JUDUL LAPORAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 4, child: Text('ISI LAPORAN / RINGKASAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                        ],
                      ),
                      const Divider(height: 24),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(child: Text('Belum ada laporan harian yang dikirimkan.', style: TextStyle(color: Colors.grey))),
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
                            final judul = (item['judul'] ?? '-').toString();
                            final isi = (item['isi_laporan'] ?? '-').toString();

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(tgl, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Expanded(flex: 3, child: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)))),
                                  Expanded(flex: 3, child: Text(judul, style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor))),
                                  Expanded(flex: 4, child: Text(isi, style: const TextStyle(color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis)),
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
