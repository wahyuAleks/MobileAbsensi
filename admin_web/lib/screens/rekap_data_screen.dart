import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/api_service.dart';

/// Mode filter untuk tabel rekap
enum FilterMode { harian, mingguan, bulanan }

class RekapDataScreen extends StatefulWidget {
  final bool showAppBar;
  final bool embedded;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaProfil;

  const RekapDataScreen({
    super.key,
    this.showAppBar = false,
    this.embedded = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaProfil,
  });

  @override
  State<RekapDataScreen> createState() => _RekapDataScreenState();
}

class _RekapDataScreenState extends State<RekapDataScreen> {
  // ───── Chart state ─────
  List<Map<String, dynamic>> _chartRaw = [];
  bool _chartLoading = true;
  String? _chartError;

  // ───── Tabel filter state ─────
  FilterMode _filterMode = FilterMode.harian;
  DateTime _selectedDate = DateTime.now();
  int _selectedWeekYear = DateTime.now().year;
  late int _selectedWeek;
  int _selectedMonth = DateTime.now().month;
  int _selectedMonthYear = DateTime.now().year;

  List<Map<String, dynamic>> _tabelData = [];
  bool _tabelLoading = false;
  String? _tabelError;

  // ───── Tooltip chart ─────
  int _touchedIndex = -1;

  static int _isoWeek(DateTime d) {
    final jan4 = DateTime(d.year, 1, 4);
    final startWeek1 = jan4.subtract(Duration(days: (jan4.weekday - 1) % 7));
    return ((d.difference(startWeek1).inDays) / 7).floor() + 1;
  }

  @override
  void initState() {
    super.initState();
    _selectedWeek = _isoWeek(DateTime.now());
    _muatChart();
    _muatTabel();
  }

  // ───── MUAT DATA CHART ─────
  Future<void> _muatChart() async {
    setState(() {
      _chartLoading = true;
      _chartError = null;
    });
    try {
      final raw = await ApiService.rekapChart();
      if (mounted) {
        setState(() {
          _chartRaw = List<Map<String, dynamic>>.from(raw);
          _chartLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _chartError = e.toString();
          _chartLoading = false;
          _chartRaw = _demoChartData();
        });
      }
    }
  }

  List<Map<String, dynamic>> _demoChartData() {
    final now = DateTime.now();
    final rng = Random(42);
    return List.generate(30, (i) {
      final d = now.subtract(Duration(days: 29 - i));
      return {
        'tanggal': DateFormat('yyyy-MM-dd').format(d),
        'total_hektar': (rng.nextDouble() * 20 + 3).toStringAsFixed(2),
        'nama_karyawan': 'Demo Karyawan',
      };
    });
  }

  // ───── MUAT DATA TABEL ─────
  Future<void> _muatTabel() async {
    setState(() {
      _tabelLoading = true;
      _tabelError = null;
    });
    try {
      List<dynamic> raw;
      if (_filterMode == FilterMode.harian) {
        raw = await ApiService.rekapLaporanFiltered(
          tanggal: DateFormat('yyyy-MM-dd').format(_selectedDate),
        );
      } else if (_filterMode == FilterMode.mingguan) {
        final week =
            '$_selectedWeekYear-W${_selectedWeek.toString().padLeft(2, '0')}';
        raw = await ApiService.rekapLaporanFiltered(minggu: week);
      } else {
        final bulan =
            '$_selectedMonthYear-${_selectedMonth.toString().padLeft(2, '0')}';
        raw = await ApiService.rekapLaporanFiltered(bulan: bulan);
      }
      if (mounted) {
        setState(() {
          _tabelData = List<Map<String, dynamic>>.from(raw);
          _tabelLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _tabelError = e.toString();
          _tabelLoading = false;
        });
      }
    }
  }

  // ───── HELPERS CHART ─────
  List<({DateTime date, double ha})> _buildChartPoints() {
    final Map<String, double> grouped = {};
    for (final row in _chartRaw) {
      final tgl = (row['tanggal'] ?? '').toString();
      final ha =
          double.tryParse((row['total_hektar'] ?? '0').toString()) ?? 0.0;
      grouped[tgl] = (grouped[tgl] ?? 0) + ha;
    }
    final entries = grouped.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((e) {
      final parts = e.key.split('-');
      return (
        date: DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
        ha: e.value,
      );
    }).toList();
  }

  // ───── HELPERS TABEL ─────
  double _parseHa(dynamic val) {
    if (val == null) return 0;
    final s =
        val.toString().replaceAll(RegExp(r'[^0-9.,]'), '').replaceAll(',', '.');
    return double.tryParse(s) ?? 0;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isEmpty) return '?';
    return parts[0][0].toUpperCase();
  }

  Color _avatarColor(String name) {
    const colors = [
      Color(0xFF4F5BA8),
      Color(0xFF16A34A),
      Color(0xFF9333EA),
      Color(0xFFEA8C28),
      Color(0xFF0891B2),
      Color(0xFF488286),
    ];
    return colors[name.hashCode.abs() % colors.length];
  }

  // ───── FILTER PERIOD NAVIGATOR ─────
  Widget _buildPeriodNavigator() {
    String label = '';
    VoidCallback onPrev;
    VoidCallback onNext;

    if (_filterMode == FilterMode.harian) {
      label = DateFormat('EEEE, d MMMM yyyy').format(_selectedDate);
      onPrev = () {
        setState(() =>
            _selectedDate = _selectedDate.subtract(const Duration(days: 1)));
        _muatTabel();
      };
      onNext = () {
        setState(
            () => _selectedDate = _selectedDate.add(const Duration(days: 1)));
        _muatTabel();
      };
    } else if (_filterMode == FilterMode.mingguan) {
      final jan4 = DateTime(_selectedWeekYear, 1, 4);
      final startW1 = jan4.subtract(Duration(days: (jan4.weekday - 1) % 7));
      final wStart = startW1.add(Duration(days: (_selectedWeek - 1) * 7));
      final wEnd = wStart.add(const Duration(days: 6));
      label =
          'Minggu ke-$_selectedWeek  (${DateFormat('d MMM').format(wStart)} – ${DateFormat('d MMM yyyy').format(wEnd)})';
      onPrev = () {
        setState(() {
          if (_selectedWeek > 1) {
            _selectedWeek--;
          } else {
            _selectedWeekYear--;
            _selectedWeek = 52;
          }
        });
        _muatTabel();
      };
      onNext = () {
        setState(() {
          if (_selectedWeek < 52) {
            _selectedWeek++;
          } else {
            _selectedWeekYear++;
            _selectedWeek = 1;
          }
        });
        _muatTabel();
      };
    } else {
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
        'Desember',
      ];
      label = '${bulanList[_selectedMonth]} $_selectedMonthYear';
      onPrev = () {
        setState(() {
          if (_selectedMonth > 1) {
            _selectedMonth--;
          } else {
            _selectedMonth = 12;
            _selectedMonthYear--;
          }
        });
        _muatTabel();
      };
      onNext = () {
        setState(() {
          if (_selectedMonth < 12) {
            _selectedMonth++;
          } else {
            _selectedMonth = 1;
            _selectedMonthYear++;
          }
        });
        _muatTabel();
      };
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, size: 22),
            onPressed: onPrev,
            visualDensity: VisualDensity.compact,
            color: const Color(0xFF374151),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, size: 22),
            onPressed: onNext,
            visualDensity: VisualDensity.compact,
            color: const Color(0xFF374151),
          ),
        ],
      ),
    );
  }

  // ───── CHART WIDGET ─────
  Widget _buildChart() {
    final points = _buildChartPoints();

    if (_chartLoading) {
      return const SizedBox(
        height: 240,
        child:
            Center(child: CircularProgressIndicator(color: Color(0xFF488286))),
      );
    }

    if (points.isEmpty) {
      return Container(
        height: 240,
        alignment: Alignment.center,
        child: const Text(
          'Belum ada data laporan luas area.\nData akan muncul setelah karyawan mengirim laporan.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        ),
      );
    }

    final maxY = points.map((p) => p.ha).reduce(max);
    final topY = (maxY * 1.3).ceilToDouble();

    final spots = points
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.ha))
        .toList();

    return SizedBox(
      height: 260,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          minY: 0,
          maxY: topY,
          clipData: const FlClipData.all(),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: topY > 0 ? topY / 4 : 1,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: Color(0xFFE5E7EB),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                interval: topY > 0 ? topY / 4 : 1,
                getTitlesWidget: (v, _) => Text(
                  '${v.toStringAsFixed(1)} Ha',
                  style:
                      const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                ),
              ),
            ),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                interval: max(1, (points.length / 6).ceilToDouble()),
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= points.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('d/M').format(points[idx].date),
                      style: const TextStyle(
                          fontSize: 10, color: Color(0xFF9CA3AF)),
                    ),
                  );
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchCallback: (event, resp) {
              if (!event.isInterestedForInteractions ||
                  resp == null ||
                  resp.lineBarSpots == null) {
                setState(() => _touchedIndex = -1);
                return;
              }
              setState(
                  () => _touchedIndex = resp.lineBarSpots!.first.spotIndex);
            },
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF1E293B),
              getTooltipItems: (spots) => spots.map((s) {
                final idx = s.spotIndex;
                if (idx < 0 || idx >= points.length) return null;
                final p = points[idx];
                return LineTooltipItem(
                  '${DateFormat('d MMM yyyy').format(p.date)}\n${p.ha.toStringAsFixed(2)} Ha',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: const Color(0xFF488286),
              barWidth: 2.5,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) => FlDotCirclePainter(
                  radius: idx == _touchedIndex ? 6 : 3,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: const Color(0xFF488286),
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF488286).withValues(alpha: 0.25),
                    const Color(0xFF488286).withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───── TABEL REKAP ─────
  Widget _buildTabel() {
    if (_tabelLoading) {
      return const SizedBox(
        height: 120,
        child:
            Center(child: CircularProgressIndicator(color: Color(0xFF488286))),
      );
    }

    if (_tabelError != null) {
      return Container(
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Text(
          'Gagal memuat data: $_tabelError',
          style: const TextStyle(color: Color(0xFFDC2626)),
        ),
      );
    }

    if (_tabelData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(36),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text(
              'Tidak ada data laporan pada periode ini.',
              style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
            ),
          ],
        ),
      );
    }

    final totalHa = _tabelData.fold<double>(
      0.0,
      (sum, item) => sum + _parseHa(item['luas_area']),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Ringkasan periode
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF488286).withValues(alpha: 0.12),
                const Color(0xFF488286).withValues(alpha: 0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: const Color(0xFF488286).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.summarize_rounded,
                  color: Color(0xFF488286), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Total ${_tabelData.length} laporan  ·  ${totalHa.toStringAsFixed(2)} Ha',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF164E63),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Header tabel
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6),
            borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: const Row(
            children: [
              Expanded(flex: 2, child: Text('TANGGAL', style: _kHeaderStyle)),
              Expanded(flex: 3, child: Text('KARYAWAN', style: _kHeaderStyle)),
              Expanded(
                  flex: 3,
                  child: Text('JUDUL / KEGIATAN', style: _kHeaderStyle)),
              Expanded(flex: 2, child: Text('LOKASI', style: _kHeaderStyle)),
              Expanded(
                flex: 2,
                child: Text(
                  'LUAS AREA',
                  style: _kHeaderStyle,
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Baris tabel
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _tabelData.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF3F4F6)),
            itemBuilder: (context, i) {
              final item = _tabelData[i];
              final user = item['User'] ?? {};
              final nama = (user['nama'] ?? 'Karyawan').toString();
              final jabatan = (user['jabatan'] ?? '-').toString();
              final tgl = (item['tanggal'] ?? '-').toString();
              final judul = (item['judul'] ?? '-').toString();
              final lokasi = (item['lokasi'] ?? '-').toString();
              final ha = _parseHa(item['luas_area']);

              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        tgl,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: _avatarColor(nama),
                            child: Text(
                              _getInitials(nama),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  nama,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  jabatan,
                                  style: const TextStyle(
                                      fontSize: 10, color: Color(0xFF9CA3AF)),
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
                      flex: 3,
                      child: Text(
                        judul,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF334155)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        lokasi,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: ha > 0
                                ? const Color(0xFF488286)
                                    .withValues(alpha: 0.12)
                                : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            ha > 0 ? '${ha.toStringAsFixed(2)} Ha' : '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: ha > 0
                                  ? const Color(0xFF164E63)
                                  : const Color(0xFF9CA3AF),
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
        ),
      ],
    );
  }

  // ───── MAIN BUILD ─────
  @override
  Widget build(BuildContext context) {
    final chartPoints = _buildChartPoints();
    final totalHaProyek = chartPoints.fold<double>(0, (s, p) => s + p.ha);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.bar_chart_rounded,
                    size: 26, color: Color(0xFF111827)),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Rekap Data & Tren Luas Area',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh_rounded,
                      color: Color(0xFF488286)),
                  onPressed: () async {
                    await Future.wait([_muatChart(), _muatTabel()]);
                  },
                  tooltip: 'Refresh Data',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── AREA LINE CHART ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: const BoxDecoration(
                        color: Color(0xFF488286),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Tren Luas Area yang Diolah (Selama Proyek)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sumbu X: Tanggal  ·  Sumbu Y: Total Luas Area (Hektar)',
                  style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 20),
                _buildChart(),
                if (_chartError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '⚠ Mode offline – data demo ditampilkan.',
                      style: const TextStyle(
                          fontSize: 11, color: Color(0xFFEA8C28)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // ── KARTU STATISTIK ──
          Row(
            children: [
              _statCard(
                label: 'Total Luas\nDiproses',
                value: '${totalHaProyek.toStringAsFixed(2)} Ha',
                icon: Icons.landscape_rounded,
                color: const Color(0xFF488286),
                bg: const Color(0xFFD1FAE5),
              ),
              const SizedBox(width: 16),
              _statCard(
                label: 'Hari\nBeroperasi',
                value: '${chartPoints.length}',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFF4F5BA8),
                bg: const Color(0xFFD8DDF8),
              ),
              const SizedBox(width: 16),
              _statCard(
                label: 'Rata-Rata\nPer Hari',
                value: chartPoints.isNotEmpty
                    ? '${(totalHaProyek / chartPoints.length).toStringAsFixed(2)} Ha'
                    : '-',
                icon: Icons.show_chart_rounded,
                color: const Color(0xFF9333EA),
                bg: const Color(0xFFF3E8FF),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── REKAP TABEL ──
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Rekap Data Karyawan',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Data laporan karyawan dari pertama bekerja di proyek ini',
                  style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                ),
                const SizedBox(height: 16),

                // Filter mode chips
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip('Harian', FilterMode.harian),
                    _filterChip('Mingguan', FilterMode.mingguan),
                    _filterChip('Bulanan', FilterMode.bulanan),
                  ],
                ),
                const SizedBox(height: 12),

                _buildPeriodNavigator(),
                const SizedBox(height: 16),

                _buildTabel(),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );

    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([_muatChart(), _muatTabel()]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: content,
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, FilterMode mode) {
    final isActive = _filterMode == mode;
    return GestureDetector(
      onTap: () {
        setState(() => _filterMode = mode);
        _muatTabel();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF488286) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF6B7280),
          ),
        ),
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color bg,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                      height: 1.3,
                    ),
                  ),
                ),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Icon(icon, color: color, size: 20)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _kHeaderStyle = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.bold,
    color: Color(0xFF6B7280),
    letterSpacing: 0.4,
  );
}
