import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import 'detail_absensi_screen.dart';
import 'pengajuan_cuti_screen.dart';
import '../../core/app_events.dart';

/// Halaman Pusat Riwayat Karyawan (Riwayat Absensi & Riwayat Pengajuan Cuti)
/// Menggunakan Segmented Tab Bar di bagian atas:
/// - Tab 0: Absensi Harian (Cari tanggal, filter hadir/terlambat/cuti, kartu presensi, detail absensi)
/// - Tab 1: Pengajuan Cuti (Ringkasan kuota, tombol ajukan cuti baru, filter status persetujuan, daftar pengajuan cuti)
class RiwayatAbsenScreen extends StatefulWidget {
  final int initialTab;
  const RiwayatAbsenScreen({super.key, this.initialTab = 0});

  @override
  State<RiwayatAbsenScreen> createState() => _RiwayatAbsenScreenState();
}

class _RiwayatAbsenScreenState extends State<RiwayatAbsenScreen> {
  late int _selectedMainTab; // 0 = Absensi Harian, 1 = Pengajuan Cuti

  // State untuk Tab Absensi
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedFilter =
      'Semua'; // 'Semua', 'Hadir', 'Terlambat', 'Izin Cuti'
  bool _loading = true;
  List<Map<String, dynamic>> _listRiwayat = [];
  Map<String, dynamic>? _riwayatTerpilih;

  // State untuk Tab Cuti
  bool _loadingCuti = false;
  String _selectedCutiFilter =
      'Semua'; // 'Semua', 'Menunggu', 'Disetujui', 'Ditolak'
  List<Map<String, dynamic>> _listCuti = [];

  // Data demo fallback untuk absensi jika belum ada data server
  final List<Map<String, dynamic>> _demoFallback = [
    {
      'id': 1,
      'tanggal': '2026-08-18',
      'tanggal_lengkap': 'Jumat, 18 Agustus 2026',
      'hari': 'Jumat',
      'tgl': '18',
      'bulan': 'AGU',
      'status': 'Hadir',
      'jam_masuk': '07:30',
      'jam_pulang': '17:05',
      'total_jam': '9 jam 35 menit',
      'lokasi': 'Kantor Pusat — Jl. Sudirman No. 45',
    },
    {
      'id': 2,
      'tanggal': '2026-08-17',
      'tanggal_lengkap': 'Kamis, 17 Agustus 2026',
      'hari': 'Kamis',
      'tgl': '17',
      'bulan': 'AGU',
      'status': 'Hadir',
      'jam_masuk': '08:00',
      'jam_pulang': '17:00',
      'total_jam': '9 jam',
      'lokasi': 'Kantor Pusat — Jl. Sudirman No. 45',
    },
    {
      'id': 3,
      'tanggal': '2026-08-16',
      'tanggal_lengkap': 'Rabu, 16 Agustus 2026',
      'hari': 'Rabu',
      'tgl': '16',
      'bulan': 'AGU',
      'status': 'Terlambat',
      'jam_masuk': '09:15',
      'jam_pulang': '17:00',
      'total_jam': '7 jam 45 menit',
      'lokasi': 'Kantor Pusat — Jl. Sudirman No. 45',
    },
    {
      'id': 4,
      'tanggal': '2026-08-15',
      'tanggal_lengkap': 'Selasa, 15 Agustus 2026',
      'hari': 'Selasa',
      'tgl': '15',
      'bulan': 'AGU',
      'status': 'Izin Cuti',
      'jam_masuk': '—',
      'jam_pulang': '—',
      'total_jam': '—',
      'lokasi': 'Izin Dinas / Cuti Tahunan',
    },
    {
      'id': 5,
      'tanggal': '2026-08-14',
      'tanggal_lengkap': 'Senin, 14 Agustus 2026',
      'hari': 'Senin',
      'tgl': '14',
      'bulan': 'AGU',
      'status': 'Hadir',
      'jam_masuk': '07:55',
      'jam_pulang': '17:20',
      'total_jam': '9 jam 42 menit',
      'lokasi': 'Kantor Pusat — Jl. Sudirman No. 45',
    },
  ];

  // Data demo fallback untuk cuti jika server kosong
  final List<Map<String, dynamic>> _demoCutiFallback = [
    {
      'id': 1,
      'jenis_cuti': 'Cuti Tahunan',
      'periode': '15 – 16 Agt 2026',
      'durasi': '2 hari',
      'status': 'Disetujui',
      'alasan': 'Acara keluarga di luar kota',
    },
    {
      'id': 2,
      'jenis_cuti': 'Cuti Sakit',
      'periode': '3 Jul 2026',
      'durasi': '1 hari',
      'status': 'Disetujui',
      'alasan': 'Flu berat dan demam tinggi',
    },
    {
      'id': 3,
      'jenis_cuti': 'Cuti Tahunan',
      'periode': '20 – 22 Jun 2026',
      'durasi': '3 hari',
      'status': 'Ditolak',
      'alasan': 'Liburan akhir semester',
      'alasan_tolak': 'Staf lapangan terlalu sedikit saat jadwal tersebut.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedMainTab = widget.initialTab;
    _muatData();
    _muatDataCuti();
    _searchCtrl.addListener(() => setState(() {}));
    AppEvents.attendanceUpdated.addListener(_onAttendanceUpdated);
  }

  void _onAttendanceUpdated() {
    if (mounted) {
      _muatData();
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    AppEvents.attendanceUpdated.removeListener(_onAttendanceUpdated);
    super.dispose();
  }

  /// Memuat riwayat absensi harian dari server
  Future<void> _muatData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.riwayatAbsen();
      final parsed = <Map<String, dynamic>>[];

      for (final item in res) {
        final tglStr = item['tanggal']?.toString() ?? '';
        DateTime? dt;
        try {
          dt = DateTime.parse(tglStr);
        } catch (_) {}

        String hari = 'Hari';
        String tgl = '01';
        String bulan = 'BLN';

        if (dt != null) {
          const hariList = [
            'Senin',
            'Selasa',
            'Rabu',
            'Kamis',
            'Jumat',
            'Sabtu',
            'Minggu'
          ];
          const bulanList = [
            'JAN',
            'FEB',
            'MAR',
            'APR',
            'MEI',
            'JUN',
            'JUL',
            'AGU',
            'SEP',
            'OKT',
            'NOV',
            'DES'
          ];
          hari = hariList[dt.weekday - 1];
          tgl = dt.day.toString().padLeft(2, '0');
          bulan = bulanList[dt.month - 1];
        }

        String jamMsk = item['jam_masuk']?.toString() ?? '—';
        if (jamMsk.length >= 5) jamMsk = jamMsk.substring(0, 5);

        String jamPlg = item['jam_pulang']?.toString() ?? '—';
        if (jamPlg.length >= 5) jamPlg = jamPlg.substring(0, 5);

        String status = 'Hadir';
        final rawSt = (item['status'] ?? '').toString().toLowerCase();
        if (rawSt.contains('cuti') || rawSt.contains('izin')) {
          status = 'Izin Cuti';
        } else if (rawSt == 'telat' || rawSt.contains('terlambat')) {
          status = 'Terlambat';
        } else if (jamMsk != '—') {
          final jamTargetRaw =
              (item['jam_masuk_target'] ?? '08:00:00').toString();
          final target = jamTargetRaw.split(':');
          final parts = jamMsk.split(':');
          final actualMinutes = (int.tryParse(parts.first) ?? 0) * 60 +
              (int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0);
          final targetMinutes = (int.tryParse(target.first) ?? 8) * 60 +
              (int.tryParse(target.length > 1 ? target[1] : '0') ?? 0);
          if (actualMinutes > targetMinutes) {
            status = 'Terlambat';
          } else if (actualMinutes < targetMinutes) {
            status = 'Datang Lebih Awal';
          } else {
            status = 'Tepat Waktu';
          }
        }

        parsed.add({
          ...item,
          'id': item['id'],
          'tanggal': tglStr,
          'hari': hari,
          'tgl': tgl,
          'bulan': bulan,
          'status': status,
          'jam_masuk': jamMsk,
          'jam_pulang': jamPlg,
          'jam_masuk_target': item['jam_masuk_target'],
          'foto_masuk': item['foto_masuk'],
          'foto_pulang': item['foto_pulang'],
          'lat_masuk': item['lat_masuk'],
          'lng_masuk': item['lng_masuk'],
          'lat_pulang': item['lat_pulang'],
          'lng_pulang': item['lng_pulang'],
          'User': item['User'],
        });
      }

      setState(() {
        _listRiwayat = parsed.isNotEmpty ? parsed : _demoFallback;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _listRiwayat = _demoFallback;
          _loading = false;
        });
      }
    }
  }

  /// Memuat riwayat pengajuan cuti dari server
  Future<void> _muatDataCuti() async {
    setState(() => _loadingCuti = true);
    try {
      final res = await ApiService.informasiCutiSaya();
      final parsed = <Map<String, dynamic>>[];

      for (final it in res) {
        final statusRaw = (it['status'] ?? 'menunggu').toString().toLowerCase();
        String statusDisplay = 'Menunggu';
        if (statusRaw == 'disetujui' || statusRaw == 'diterima') {
          statusDisplay = 'Disetujui';
        } else if (statusRaw == 'ditolak') {
          statusDisplay = 'Ditolak';
        }

        parsed.add({
          'id': it['id'],
          'jenis_cuti': it['jenis_cuti'] ?? 'Cuti Tahunan',
          'periode': '${it['tanggal_mulai']} – ${it['tanggal_selesai']}',
          'durasi': '${it['durasi'] ?? 1} hari',
          'status': statusDisplay,
          'alasan': it['alasan'],
          'alasan_tolak': it['catatan_admin'] != null &&
                  it['catatan_admin'].toString().isNotEmpty
              ? 'Alasan penolakan: ${it['catatan_admin']}'
              : null,
        });
      }

      setState(() {
        _listCuti = parsed.isNotEmpty ? parsed : _demoCutiFallback;
        _loadingCuti = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _listCuti = _demoCutiFallback;
          _loadingCuti = false;
        });
      }
    }
  }

  void _bukaDetail(Map<String, dynamic> item) {
    setState(() {
      _riwayatTerpilih = item;
    });
  }

  Future<void> _bukaFormPengajuanCuti() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PengajuanCutiScreen(initialTabIndex: 0),
      ),
    );
    _muatDataCuti();
  }

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFDCFCE7);
    Color textColor = const Color(0xFF16A34A);

    if (status.toLowerCase().contains('terlambat')) {
      bg = const Color(0xFFFFEDD5);
      textColor = const Color(0xFFEA580C);
    } else if (status.toLowerCase().contains('cuti') ||
        status.toLowerCase().contains('izin')) {
      bg = const Color(0xFFE0E7FF);
      textColor = const Color(0xFF4338CA);
    } else if (status.toLowerCase().contains('awal') ||
        status.toLowerCase().contains('tepat') ||
        status.toLowerCase().contains('hadir')) {
      bg = const Color(0xFFDCFCE7);
      textColor = const Color(0xFF16A34A);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPulangPill(bool sudahPulang) {
    final bg = sudahPulang ? const Color(0xFFE0F2FE) : const Color(0xFFF3F4F6);
    final textColor =
        sudahPulang ? const Color(0xFF0284C7) : const Color(0xFF9CA3AF);
    final text = sudahPulang ? 'Sudah Pulang' : 'Belum Pulang';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sudahPulang
                ? Icons.check_circle_rounded
                : Icons.access_time_rounded,
            size: 11,
            color: textColor,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Jika sedang membuka layar detail absensi
    if (_riwayatTerpilih != null) {
      return DetailAbsensiScreen(
        item: _riwayatTerpilih!,
        onBack: () => setState(() => _riwayatTerpilih = null),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER UTAMA: "Riwayat" + Subtitle
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Riwayat',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF111827),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Catatan presensi harian & permohonan cuti',
                        style:
                            TextStyle(fontSize: 12.5, color: Color(0xFF6B7280)),
                      ),
                    ],
                  ),
                  // Tombol Refresh Cepat
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFF4F5BA8)),
                    tooltip: 'Segarkan Data',
                    onPressed: () {
                      _muatData();
                      _muatDataCuti();
                    },
                  ),
                ],
              ),
            ),

            // 2. SEGMENTED SWITCHER TAB ATAS: [ Absensi Harian | Pengajuan Cuti ]
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  // Tab 0: Absensi Harian
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMainTab = 0),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMainTab == 0
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedMainTab == 0
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.access_time_filled_rounded,
                              size: 16,
                              color: _selectedMainTab == 0
                                  ? const Color(0xFF4F5BA8)
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Absensi Harian',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: _selectedMainTab == 0
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _selectedMainTab == 0
                                    ? const Color(0xFF4F5BA8)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Tab 1: Pengajuan Cuti
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedMainTab = 1),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _selectedMainTab == 1
                              ? Colors.white
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _selectedMainTab == 1
                              ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_note_rounded,
                              size: 16,
                              color: _selectedMainTab == 1
                                  ? const Color(0xFF4F5BA8)
                                  : const Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Pengajuan Cuti',
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: _selectedMainTab == 1
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                color: _selectedMainTab == 1
                                    ? const Color(0xFF4F5BA8)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // 3. KONTEN TAB SESUAI PILIHAN
            Expanded(
              child: _selectedMainTab == 0
                  ? _buildAbsensiContent()
                  : _buildCutiContent(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // KONTEN TAB 0: RIWAYAT ABSENSI HARIAN
  // ==========================================
  Widget _buildAbsensiContent() {
    // Hitung ringkasan statistik
    int countHadir = 0;
    int countTerlambat = 0;
    int countCuti = 0;

    for (final item in _listRiwayat) {
      final st = (item['status'] ?? '').toString().toLowerCase();
      if (st.contains('terlambat')) {
        countTerlambat++;
      } else if (st.contains('cuti') || st.contains('izin')) {
        countCuti++;
      } else {
        countHadir++;
      }
    }

    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _listRiwayat.where((item) {
      final st = (item['status'] ?? '').toString();
      final jp = (item['jam_pulang'] ?? '').toString();
      if (_selectedFilter == 'Hadir' &&
          !st.toLowerCase().contains('hadir') &&
          !st.toLowerCase().contains('awal') &&
          !st.toLowerCase().contains('tepat')) {
        return false;
      }
      if (_selectedFilter == 'Sudah Pulang' && (jp.isEmpty || jp == '—'))
        return false;
      if (_selectedFilter == 'Terlambat' &&
          !st.toLowerCase().contains('terlambat')) return false;
      if (_selectedFilter == 'Izin Cuti' &&
          (!st.toLowerCase().contains('cuti') &&
              !st.toLowerCase().contains('izin'))) return false;

      if (query.isNotEmpty) {
        final tgl = (item['tanggal'] ?? '').toString().toLowerCase();
        final hari = (item['hari'] ?? '').toString().toLowerCase();
        final tglNo = (item['tgl'] ?? '').toString().toLowerCase();
        final bln = (item['bulan'] ?? '').toString().toLowerCase();
        return tgl.contains(query) ||
            hari.contains(query) ||
            tglNo.contains(query) ||
            bln.contains(query);
      }
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _muatData,
      child: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFD1D5DB), width: 1.2),
              ),
              child: Stack(
                alignment: Alignment.center,
                fit: StackFit.expand,
                children: [
                  TextField(
                    controller: _searchCtrl,
                    textAlign: TextAlign.center,
                    textAlignVertical: TextAlignVertical.center,
                    minLines: 1,
                    maxLines: 1,
                    style: const TextStyle(
                      fontSize: 13.5,
                      color: Color(0xFF111827),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Cari tanggal absensi...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 13,
                      ),
                      isCollapsed: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const Positioned(
                    left: 12,
                    child: IgnorePointer(
                      child: Icon(
                        Icons.search,
                        size: 18,
                        color: Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Hadir'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Sudah Pulang'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Terlambat'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Izin Cuti'),
                ],
              ),
            ),
          ),

          // Baris Kartu Ringkasan
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    count: countHadir.toString(),
                    label: 'Hadir',
                    valueColor: const Color(0xFF16A34A),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    count: countTerlambat.toString(),
                    label: 'Terlambat',
                    valueColor: const Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    count: countCuti.toString(),
                    label: 'Cuti/Izin',
                    valueColor: const Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),

          // List Absensi
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'Tidak ada riwayat absensi ditemukan',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final item = filtered[i];
                          return _buildRiwayatCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // KONTEN TAB 1: RIWAYAT PENGAJUAN CUTI
  // ==========================================
  Widget _buildCutiContent() {
    final filteredCuti = _listCuti.where((item) {
      final st = (item['status'] ?? '').toString().toLowerCase();
      if (_selectedCutiFilter == 'Menunggu' && !st.contains('menunggu'))
        return false;
      if (_selectedCutiFilter == 'Disetujui' && !st.contains('disetujui'))
        return false;
      if (_selectedCutiFilter == 'Ditolak' && !st.contains('ditolak'))
        return false;
      return true;
    }).toList();

    return RefreshIndicator(
      onRefresh: _muatDataCuti,
      child: Column(
        children: [
          // Banner Cepat: Sisa Kuota & Tombol Ajukan Cuti Baru
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC7D2FE)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      color: Color(0xFF4F5BA8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.date_range_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sisa Kuota Cuti Tahunan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4F5BA8),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          '9 Hari Tersedia • 3 Terpakai',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F5BA8),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _bukaFormPengajuanCuti,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 16),
                        SizedBox(width: 4),
                        Text('Ajukan',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Filter Cuti Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCutiFilterChip('Semua'),
                  const SizedBox(width: 8),
                  _buildCutiFilterChip('Menunggu'),
                  const SizedBox(width: 8),
                  _buildCutiFilterChip('Disetujui'),
                  const SizedBox(width: 8),
                  _buildCutiFilterChip('Ditolak'),
                ],
              ),
            ),
          ),

          // List Pengajuan Cuti
          Expanded(
            child: _loadingCuti
                ? const Center(child: CircularProgressIndicator())
                : filteredCuti.isEmpty
                    ? ListView(
                        children: const [
                          Padding(
                            padding: EdgeInsets.all(40),
                            child: Center(
                              child: Text(
                                'Tidak ada data pengajuan cuti',
                                style: TextStyle(color: Color(0xFF6B7280)),
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                        itemCount: filteredCuti.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, i) {
                          final item = filteredCuti[i];
                          return _buildCutiCard(item);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final bool active = _selectedFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? AppConstants.primaryColor : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildCutiFilterChip(String label) {
    final bool active = _selectedCutiFilter == label;
    return GestureDetector(
      onTap: () => setState(() => _selectedCutiFilter = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF4F5BA8) : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: active ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String count,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _bukaDetail(item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Date Squircle Badge (e.g. 18 AGU)
                Container(
                  width: 52,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item['tgl'] ?? '01',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                          height: 1.1,
                        ),
                      ),
                      Text(
                        item['bulan'] ?? 'BLN',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Content (Hari + Status Badge + Jam Masuk & Pulang)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Text(
                            item['hari'] ?? 'Hari',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                          _buildStatusPill(item['status'] ?? 'Hadir'),
                          if ((item['status'] ?? '') != 'Izin Cuti')
                            _buildPulangPill(item['jam_pulang'] != null &&
                                item['jam_pulang'] != '—'),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          // Jam Masuk
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.login_rounded,
                                  size: 13, color: Color(0xFF16A34A)),
                              const SizedBox(width: 4),
                              Text(
                                '${item['jam_masuk']}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          // Jam Pulang
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                size: 13,
                                color: (item['jam_pulang'] != null &&
                                        item['jam_pulang'] != '—')
                                    ? const Color(0xFF0284C7)
                                    : const Color(0xFF9CA3AF),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                (item['jam_pulang'] != null &&
                                        item['jam_pulang'] != '—')
                                    ? '${item['jam_pulang']}'
                                    : 'Belum Pulang',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: (item['jam_pulang'] != null &&
                                          item['jam_pulang'] != '—')
                                      ? const Color(0xFF1F2937)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Right Chevron
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9CA3AF),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCutiCard(Map<String, dynamic> item) {
    final status = (item['status'] ?? 'Menunggu').toString();
    final bool isDisetujui = status.toLowerCase() == 'disetujui';
    final bool isDitolak = status.toLowerCase() == 'ditolak';

    Color badgeBg = const Color(0xFFFEF3C7);
    Color badgeColor = const Color(0xFFD97706);
    IconData badgeIcon = Icons.access_time_rounded;

    if (isDisetujui) {
      badgeBg = const Color(0xFFDCFCE7);
      badgeColor = const Color(0xFF16A34A);
      badgeIcon = Icons.check_circle_rounded;
    } else if (isDitolak) {
      badgeBg = const Color(0xFFFEE2E2);
      badgeColor = const Color(0xFFDC2626);
      badgeIcon = Icons.cancel_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Jenis Cuti & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['jenis_cuti'] ?? 'Cuti Tahunan',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 13, color: badgeColor),
                    const SizedBox(width: 4),
                    Text(
                      status,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Periode & Durasi
          Row(
            children: [
              const Icon(Icons.date_range_outlined,
                  size: 15, color: Color(0xFF6B7280)),
              const SizedBox(width: 6),
              Text(
                item['periode'] ?? '',
                style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF4B5563),
                    fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item['durasi'] ?? '',
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151)),
                ),
              ),
            ],
          ),

          // Alasan Cuti Karyawan
          if (item['alasan'] != null &&
              item['alasan'].toString().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Alasan: ${item['alasan']}',
              style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF6B7280),
                  fontStyle: FontStyle.italic),
            ),
          ],

          // Box Alasan Penolakan (Jika ditolak)
          if (isDitolak && item['alasan_tolak'] != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECDD3)),
              ),
              child: Text(
                item['alasan_tolak'].toString(),
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFFBE123C),
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
