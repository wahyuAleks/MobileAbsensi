import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_service.dart';
import 'rekap_data_screen.dart';

class HomeAdminScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onOpenNotifikasi;
  final VoidCallback onBukaKaryawan;
  final VoidCallback onBukaRekapAbsensi;
  final VoidCallback onBukaPersetujuanCuti;
  final VoidCallback onBukaProfil;

  const HomeAdminScreen({
    super.key,
    required this.onOpenDrawer,
    required this.onOpenNotifikasi,
    required this.onBukaKaryawan,
    required this.onBukaRekapAbsensi,
    required this.onBukaPersetujuanCuti,
    required this.onBukaProfil,
  });

  @override
  State<HomeAdminScreen> createState() => _HomeAdminScreenState();
}

class _HomeAdminScreenState extends State<HomeAdminScreen> {
  int _totalKaryawan = 0;
  int _hadirHariIni = 0;
  int _belumAbsen = 0;
  int _terlambat = 0;
  int _pengajuanCuti = 0;
  String? _loadError;

  List<Map<String, dynamic>> _absensiList = [];
  List<Map<String, dynamic>> _cutiMenungguList = [];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  Future<void> _muatData() async {
    final failures = <String>[];
    try {
      final karyawan = await ApiService.daftarKaryawan();
      if (mounted) {
        setState(() => _totalKaryawan = karyawan.length);
      }
    } catch (e) {
      failures.add('Data karyawan: $e');
    }

    try {
      final cutiMenunggu =
          await ApiService.daftarPengajuanCuti(status: 'menunggu');
      if (mounted) {
        setState(() {
          _cutiMenungguList = List<Map<String, dynamic>>.from(cutiMenunggu);
          _pengajuanCuti = cutiMenunggu.length;
        });
      }
    } catch (e) {
      failures.add('Persetujuan cuti: $e');
    }

    try {
      final tglHariIni = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final rekap = await ApiService.rekapAbsensiAdmin(tanggal: tglHariIni);
      if (mounted) {
        int telat = 0;
        for (final item in rekap) {
          final status = (item['status'] ?? '').toString().toLowerCase();
          if (status.contains('terlambat') || status.contains('telat')) telat++;
        }
        setState(() {
          _absensiList = List<Map<String, dynamic>>.from(rekap);
          _hadirHariIni = rekap.length;
          _terlambat = telat;
          _belumAbsen = (_totalKaryawan - _hadirHariIni).clamp(0, _totalKaryawan);
        });
      }
    } catch (e) {
      failures.add('Absensi hari ini: $e');
    }

    if (mounted) {
      setState(() => _loadError = failures.isEmpty ? null : failures.join('\n'));
    }
  }

  String _formatTanggalHariIni() {
    final now = DateTime.now();
    const hariList = [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ];
    const bulanList = [
      '',
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
    return '${hariList[now.weekday % 7]}, ${now.day} ${bulanList[now.month]} ${now.year}';
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'AF';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final hadirPercent = _totalKaryawan > 0
        ? ((_hadirHariIni / _totalKaryawan) * 100).round()
        : 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muatData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Page title and date
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    _formatTanggalHariIni(),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (_loadError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline_rounded, size: 16, color: Color(0xFFDC2626)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _loadError!,
                            style: const TextStyle(fontSize: 10, color: Color(0xFF991B1B)),
                          ),
                        ),
                        TextButton(
                          onPressed: _muatData,
                          child: const Text('Coba lagi', style: TextStyle(fontSize: 10)),
                        ),
                      ],
                    ),
                  ),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final gap = 10.0;
                    final columns = constraints.maxWidth >= 520 ? 4 : 2;
                    final cardWidth =
                        (constraints.maxWidth - gap * (columns - 1)) / columns;
                    return Wrap(
                      spacing: gap,
                      runSpacing: gap,
                      children: [
                        SizedBox(
                          width: cardWidth,
                          child: _buildMetricCard(
                            title: 'Total Karyawan',
                            value: '$_totalKaryawan',
                            icon: Icons.groups_rounded,
                            iconColor: const Color(0xFF4F5BA8),
                            iconBg: const Color(0xFFD8DDF8),
                            onTap: widget.onBukaKaryawan,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildMetricCard(
                            title: 'Hadir Hari Ini',
                            value: '$_hadirHariIni',
                            subtext: '$hadirPercent%',
                            icon: Icons.check_circle_rounded,
                            iconColor: const Color(0xFF16A34A),
                            iconBg: const Color(0xFFDCFCE7),
                            onTap: widget.onBukaRekapAbsensi,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildMetricCard(
                            title: 'Belum Absen',
                            value: '$_belumAbsen',
                            icon: Icons.access_time_filled_rounded,
                            iconColor: const Color(0xFFEA8C28),
                            iconBg: const Color(0xFFFDE8D4),
                            onTap: widget.onBukaRekapAbsensi,
                          ),
                        ),
                        SizedBox(
                          width: cardWidth,
                          child: _buildMetricCard(
                            title: 'Terlambat',
                            value: '$_terlambat',
                            icon: Icons.error_rounded,
                            iconColor: const Color(0xFFDC2626),
                            iconBg: const Color(0xFFFCD5DC),
                            onTap: widget.onBukaRekapAbsensi,
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                const RekapDataScreen(embedded: true),
                const SizedBox(height: 8),

                LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 520) {
                      return Column(
                        children: [
                          _buildAttendancePanel(),
                          const SizedBox(height: 12),
                          _buildPendingPanel(),
                        ],
                      );
                    }
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 6, child: _buildAttendancePanel()),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: _buildPendingPanel()),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                _buildDepartmentPanel(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPanel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE1E4E8)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildAttendancePanel() {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Absensi Hari Ini',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
              ),
              Text(
                '${_absensiList.length} karyawan',
                style: const TextStyle(fontSize: 9, color: Color(0xFF9CA3AF)),
              ),
            ],
          ),
          const Divider(height: 16),
          if (_absensiList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Belum ada data absensi hari ini.',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            ..._absensiList.take(6).map((item) {
              final user = item['User'] ?? {};
              final nama = (user['nama'] ?? 'Karyawan').toString();
              final jabatan = (user['jabatan'] ?? 'Karyawan').toString();
              final jamMasuk = (item['jam_masuk'] ?? '-').toString();
              final isTerlambat = (item['status'] ?? '').toString().toLowerCase().contains('terlambat') ||
                  (item['status'] ?? '').toString().toLowerCase().contains('telat');
              return Column(
                children: [
                  _buildTableRow(
                    initials: _getInitials(nama),
                    nama: nama,
                    jabatan: jabatan,
                    jamMasuk: jamMasuk,
                    isTerlambat: isTerlambat,
                  ),
                  if (item != _absensiList.take(6).last)
                    const Divider(height: 8),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPendingPanel() {
    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Persetujuan Pending ($_pengajuanCuti)',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const Divider(height: 16),
          if (_cutiMenungguList.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text(
                  'Tidak ada pengajuan menunggu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            ..._cutiMenungguList.take(4).map((item) {
              final user = item['User'] ?? {};
              final nama = (user['nama'] ?? 'Karyawan').toString();
              final tanggalMulai = (item['tanggal_mulai'] ?? '').toString();
              final tanggalSelesai = (item['tanggal_selesai'] ?? '').toString();
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFFE6E9FA),
                  child: Text(
                    _getInitials(nama),
                    style: const TextStyle(fontSize: 8, color: Color(0xFF4F5BA8), fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
                ),
                subtitle: Text(
                  '$tanggalMulai - $tanggalSelesai',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF)),
                ),
              );
            }),
          if (_cutiMenungguList.isNotEmpty)
            TextButton(
              onPressed: widget.onBukaPersetujuanCuti,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 26),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Lihat semua pengajuan',
                style: const TextStyle(fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDepartmentPanel() {
    final departmentCounts = <String, int>{};
    for (final item in _absensiList) {
      final user = item['User'] ?? {};
      final division = (user['jabatan'] ?? 'Lainnya').toString();
      departmentCounts[division] = (departmentCounts[division] ?? 0) + 1;
    }
    final departments = departmentCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return _buildPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kehadiran per Divisi',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF111827)),
          ),
          const Divider(height: 16),
          if (departments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Center(
                child: Text(
                  'Data kehadiran per divisi akan tampil setelah absensi tercatat.',
                  style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                ),
              ),
            )
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth > 500 ? 4 : 2;
                final itemWidth = (constraints.maxWidth - (columns - 1) * 12) / columns;
                final maxCount = departments.first.value;
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: departments.take(8).map((entry) {
                    final ratio = entry.value / maxCount;
                    return SizedBox(
                      width: itemWidth,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  entry.key,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(
                                '${(ratio * 100).round()}%',
                                style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: ratio,
                              minHeight: 6,
                              backgroundColor: const Color(0xFFE5E7EB),
                              valueColor: const AlwaysStoppedAnimation(Color(0xFF4F5BA8)),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${entry.value} hadir',
                            style: const TextStyle(fontSize: 8, color: Color(0xFF9CA3AF)),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    String? subtext,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE1E4E8)),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.025), blurRadius: 4, offset: const Offset(0, 1)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtext == null ? title : '$title · $subtext',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String initials,
    required String nama,
    required String jabatan,
    required String jamMasuk,
    required bool isTerlambat,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF388E87),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        jabatan,
                        style: const TextStyle(
                          fontSize: 8,
                          color: Color(0xFF9CA3AF),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              jamMasuk,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: BoxDecoration(
                  color: isTerlambat
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  isTerlambat ? 'Telat' : 'Hadir',
                  style: TextStyle(
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                    color: isTerlambat
                        ? const Color(0xFFDC2626)
                        : const Color(0xFF16A34A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
