import 'package:flutter/material.dart';
import '../core/api_service.dart';
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
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  static const _kTableHeaderStyle = TextStyle(
    fontWeight: FontWeight.bold,
    color: Color(0xFF64748B),
    fontSize: 12,
  );

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _muat() {
    setState(() {
      _future = ApiService.rekapAbsensiAdmin(bulan: _bulan, tahun: _tahun);
    });
  }

  String _namaBulanTahun(int bulan, int tahun) {
    const namaBulan = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember'
    ];
    final b = (bulan >= 1 && bulan <= 12) ? namaBulan[bulan - 1] : '';
    return '$b $tahun';
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rekapitulasi Bulanan Absensi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Periode: ${_namaBulanTahun(_bulan, _tahun)}',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            SizedBox(
              width: 320,
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari nama karyawan...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF4F5BA8), width: 1.5),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                onChanged: (value) => setState(() => _query = value.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 20),
            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                final list = snap.data ?? [];
                final filtered = list.where((item) {
                  if (_query.isEmpty) return true;
                  final user = item['User'] is Map ? item['User'] as Map : const {};
                  final nama = (user['nama'] ?? item['nama'] ?? 'Karyawan').toString();
                  return nama.toLowerCase().contains(_query);
                }).toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(flex: 2, child: Text('TANGGAL', style: _kTableHeaderStyle)),
                          Expanded(flex: 3, child: Text('KARYAWAN', style: _kTableHeaderStyle)),
                          Expanded(flex: 2, child: Text('MASUK', textAlign: TextAlign.center, style: _kTableHeaderStyle)),
                          Expanded(flex: 2, child: Text('PULANG', textAlign: TextAlign.center, style: _kTableHeaderStyle)),
                          Expanded(flex: 2, child: Text('STATUS', textAlign: TextAlign.right, style: _kTableHeaderStyle)),
                        ],
                      ),
                      const Divider(height: 24),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(
                            child: Text(
                              'Tidak ada data rekapitulasi absensi untuk bulan ini.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = filtered[i];
                            final user = item['User'] is Map ? item['User'] as Map : const {};
                            final nama = (user['nama'] ?? 'Karyawan').toString();
                            final tgl = (item['tanggal'] ?? '-').toString();
                            final jamMasuk = (item['jam_masuk'] ?? '-').toString();
                            final jamPulang = (item['jam_pulang'] ?? '-').toString();
                            final status = (item['status'] ?? '').toString();
                            final isTerlambat = status.toLowerCase().contains('terlambat');

                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      tgl,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF475569),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      nama,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      jamMasuk,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      jamPulang,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: Color(0xFF64748B),
                                      ),
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
                                            fontSize: 11,
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
