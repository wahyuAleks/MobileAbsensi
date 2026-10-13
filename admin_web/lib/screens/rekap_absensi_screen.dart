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
  String _viewMode = 'ringkasan'; // 'ringkasan' (grouped per karyawan) or 'log' (daily records)

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Rekapitulasi Bulanan Absensi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pantau rekap total kehadiran, keterlambatan, dan log harian per karyawan.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
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
            ),
            const SizedBox(height: 20),

            // Mode Selector and Search Bar
            Row(
              children: [
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment(
                      value: 'ringkasan',
                      label: Text('Ringkasan per Karyawan'),
                      icon: Icon(Icons.people_outline, size: 16),
                    ),
                    ButtonSegment(
                      value: 'log',
                      label: Text('Log Harian Absensi'),
                      icon: Icon(Icons.table_chart_outlined, size: 16),
                    ),
                  ],
                  selected: {_viewMode},
                  onSelectionChanged: (val) {
                    setState(() => _viewMode = val.first);
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: 300,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nama karyawan...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      suffixIcon: _query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _query = '');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final rawList = snap.data ?? [];

                // Filter berdasarkan query
                final list = rawList.where((item) {
                  if (_query.isEmpty) return true;
                  final user = item['User'] is Map ? item['User'] as Map : const {};
                  final nama = (user['nama'] ?? item['nama'] ?? '').toString().toLowerCase();
                  return nama.contains(_query);
                }).toList();

                if (_viewMode == 'ringkasan') {
                  // Grouping per user (sama seperti di mobile app)
                  final Map<String, Map<String, dynamic>> grouped = {};
                  for (final item in list) {
                    final user = item['User'] is Map ? item['User'] as Map : const {};
                    final uid = (user['id'] ?? item['user_id'] ?? item['id'] ?? '').toString();
                    final nama = (user['nama'] ?? item['nama'] ?? 'Karyawan').toString();
                    final status = (item['status'] ?? '').toString().toLowerCase();

                    if (!grouped.containsKey(uid)) {
                      grouped[uid] = {
                        'id': uid,
                        'nama': nama,
                        'hadir': 0,
                        'terlambat': 0,
                        'tidak_hadir': 0,
                      };
                    }

                    if (status.contains('terlambat') || status.contains('telat')) {
                      grouped[uid]!['terlambat'] = (grouped[uid]!['terlambat'] as int) + 1;
                      grouped[uid]!['hadir'] = (grouped[uid]!['hadir'] as int) + 1;
                    } else if (status.contains('hadir') || status.contains('tepat') || status.isNotEmpty) {
                      grouped[uid]!['hadir'] = (grouped[uid]!['hadir'] as int) + 1;
                    } else {
                      grouped[uid]!['tidak_hadir'] = (grouped[uid]!['tidak_hadir'] as int) + 1;
                    }
                  }

                  final summaryList = grouped.values.toList();

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
                            Expanded(
                              flex: 4,
                              child: Text('NAMA KARYAWAN',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('TOTAL HADIR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('TERLAMBAT',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('TIDAK HADIR / CUTI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (summaryList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(36),
                            child: Center(
                              child: Text(
                                'Tidak ada data rekapitulasi absensi untuk filter ini.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: summaryList.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = summaryList[i];
                              final nama = item['nama'].toString();
                              final hadir = item['hadir'] ?? 0;
                              final terlambat = item['terlambat'] ?? 0;
                              final tidakHadir = item['tidak_hadir'] ?? 0;

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 4,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: const Color(0xFFE0E7FF),
                                            child: Text(
                                              nama.isNotEmpty ? nama[0].toUpperCase() : 'K',
                                              style: const TextStyle(
                                                color: Color(0xFF4338CA),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              nama,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$hadir Hari',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF16A34A)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$terlambat Kali',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: (terlambat as int) > 0 ? const Color(0xFFDC2626) : const Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$tidakHadir Hari',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Color(0xFF64748B)),
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
                } else {
                  // Log Harian
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
                            Expanded(
                              flex: 2,
                              child: Text('TANGGAL',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 3,
                              child: Text('KARYAWAN',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('MASUK',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('PULANG',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text('STATUS',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        if (list.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(36),
                            child: Center(
                              child: Text(
                                'Tidak ada data rekapitulasi absensi untuk filter ini.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: list.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = list[i];
                              final user = item['User'] is Map ? item['User'] as Map : const {};
                              final nama = (user['nama'] ?? item['nama'] ?? 'Karyawan').toString();
                              final tgl = (item['tanggal'] ?? '-').toString();
                              final jamMasuk = (item['jam_masuk'] ?? '-').toString();
                              final jamPulang = (item['jam_pulang'] ?? '-').toString();
                              final isTerlambat = (item['status'] ?? '').toString().toLowerCase().contains('terlambat');

                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(tgl, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(jamMasuk, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(jamPulang, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF64748B))),
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
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
