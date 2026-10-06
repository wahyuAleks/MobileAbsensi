import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import 'buat_laporan_screen.dart';
import 'detail_laporan_screen.dart';

class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});

  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  String _selectedFilter = 'Semua'; // 'Semua', 'Terkirim', 'Draft'
  bool _loading = true;
  List<Map<String, dynamic>> _listLaporan = [];
  Map<String, dynamic>? _laporanTerpilih;

  // Data demo fallback yang persis seperti pada desain mockup
  final List<Map<String, dynamic>> _demoLaporan = [
    {
      'id': 1,
      'judul': 'Penyemprotan pestisida area Blok A — 8 Ha',
      'tanggal': '17 Agustus 2026',
      'waktu': '16:30',
      'status': 'Terkirim',
      'jenis_kegiatan': 'Penyemprotan Pestisida',
      'lokasi': 'Sawah Blok A — Karawang',
      'unit_drone': 'DA-001 (DJI Agras T40)',
      'luas_area': '8 Ha',
      'uraian_pekerjaan':
          'Penyemprotan pestisida dilakukan pada lahan Blok A seluas 8 Ha. Drone DA-001 beroperasi dari pukul 07.00 – 11.30. Seluruh area berhasil disemprot dengan dosis sesuai anjuran.',
      'hasil': 'Penyemprotan 100% selesai. Tidak ada kendala signifikan.',
      'rencana_esok': 'Penyemprotan Blok B — 5 Ha dengan drone DA-002.',
      'isi_laporan':
          'Kegiatan operasional drone sprayer pada Blok A seluas 8 Hektar selesai sesuai SOP.',
    },
    {
      'id': 2,
      'judul': 'Survei dan pemetaan lahan baru Subang',
      'tanggal': '16 Agt 2026',
      'waktu': '17:00',
      'status': 'Terkirim',
      'jenis_kegiatan': 'Survei dan Pemetaan Lahan',
      'lokasi': 'Lahan Perkebunan Subang',
      'unit_drone': 'DA-003 (DJI Mavic 3M)',
      'luas_area': '15 Ha',
      'uraian_pekerjaan':
          'Pemetaan kontur elevasi dan indeks vegetasi NDVI lahan baru Subang selesai dipetakan untuk perencanaan irigasi presisi.',
      'hasil':
          'Peta ortomosaik resolusi tinggi selesai diproses di server GIS.',
      'rencana_esok': 'Analisis data NDVI bersama tim agronomi internal.',
      'isi_laporan':
          'Pemetaan elevasi dan batas kontur lahan baru wilayah Subang menggunakan drone pemeta.',
    },
    {
      'id': 3,
      'judul': 'Pemeliharaan rutin drone DA-001 dan DA-002',
      'tanggal': '15 Agt 2026',
      'waktu': '15:45',
      'status': 'Terkirim',
      'jenis_kegiatan': 'Pemeliharaan Rutin Drone',
      'lokasi': 'Hangar Drone Agrikultur',
      'unit_drone': 'DA-001 & DA-002',
      'luas_area': '-',
      'uraian_pekerjaan':
          'Pemeriksaan motor brushless, kalibrasi sensor kompas, dan pembersihan rotor unit DA-001 & DA-002 selesai sesuai SOP.',
      'hasil': 'Kondisi unit drone 100% siap terbang operasional besok.',
      'rencana_esok': 'Uji coba penerbangan sensor multispektral DA-003.',
      'isi_laporan':
          'Pemeriksaan motor brushless, kalibrasi sensor kompas, dan pembersihan rotor unit DA-001 & DA-002.',
    },
    {
      'id': 4,
      'judul': 'Penyebaran pupuk urea Blok B — 5 Ha',
      'tanggal': '14 Agt 2026',
      'waktu': '16:50',
      'status': 'Terkirim',
      'jenis_kegiatan': 'Penyebaran Pupuk Urea',
      'lokasi': 'Sawah Blok B — Karawang',
      'unit_drone': 'DA-002 (DJI Agras T40)',
      'luas_area': '5 Ha',
      'uraian_pekerjaan':
          'Penyebaran butiran pupuk urea dengan spreader drone selesai dengan tingkat presisi dan sebaran merata.',
      'hasil': 'Penyebaran pupuk 100% selesai sesuai takaran agronomis.',
      'rencana_esok': 'Inspeksi visual perkembangan tunas pada Blok B.',
      'isi_laporan':
          'Penyebaran butiran pupuk urea dengan spreader drone selesai dengan presisi tinggi.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _muatData();
  }

  String _formatTanggalIndo(DateTime dt) {
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
    return '${dt.day} ${namaBulan[dt.month - 1]} ${dt.year}';
  }

  Future<void> _muatData() async {
    setState(() => _loading = true);
    try {
      final res = await ApiService.laporanSaya();
      final parsed = <Map<String, dynamic>>[];

      for (final item in res) {
        final tglRaw = item['tanggal']?.toString() ?? '';
        DateTime? dt;
        try {
          dt = DateTime.parse(tglRaw);
        } catch (_) {}

        String tglFmt = tglRaw;
        if (dt != null) {
          tglFmt = _formatTanggalIndo(dt);
        }

        String waktuFmt = '16:00';
        if (item['createdAt'] != null) {
          try {
            final dtCreated =
                DateTime.parse(item['createdAt'].toString()).toLocal();
            waktuFmt = DateFormat('HH:mm').format(dtCreated);
          } catch (_) {}
        }

        parsed.add({
          'id': item['id'],
          'tanggal_raw': tglRaw,
          'judul': item['judul'] ?? 'Laporan Kegiatan',
          'tanggal': tglFmt,
          'waktu': waktuFmt,
          'status': item['status'] ?? 'Terkirim',
          'isi_laporan': item['isi_laporan'] ?? '',
          'jenis_kegiatan': item['jenis_kegiatan'] ??
              item['judul'] ??
              'Penyemprotan Pestisida',
          'lokasi': item['lokasi'] ?? 'Sawah Blok A — Karawang',
          'unit_drone': item['unit_drone'] ?? 'DA-001 (DJI Agras T40)',
          'luas_area': item['luas_area'] ?? '8 Ha',
          'uraian_pekerjaan':
              item['uraian_pekerjaan'] ?? item['isi_laporan'] ?? '',
          'hasil': item['hasil'] ??
              'Penyemprotan 100% selesai. Tidak ada kendala signifikan.',
          'rencana_esok': item['rencana_esok'] ??
              'Penyemprotan Blok B — 5 Ha dengan drone DA-002.',
        });
      }

      setState(() {
        if (parsed.isNotEmpty) {
          _listLaporan = [...parsed, ..._demoLaporan];
        } else {
          _listLaporan = _demoLaporan;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _listLaporan = _demoLaporan;
          _loading = false;
        });
      }
    }
  }

  void _bukaDetailLaporan(Map<String, dynamic> item) {
    setState(() {
      _laporanTerpilih = item;
    });
  }

  Future<void> _bukaFormTambah({Map<String, dynamic>? draft}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => BuatLaporanScreen(draft: draft),
      ),
    );
    if (result == true && mounted) {
      await _muatData();
    }
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

  Widget _buildStatusPill(String status) {
    Color bg = const Color(0xFFC7DBC5);
    Color textColor = const Color(0xFF3F623C);

    if (status.toLowerCase().contains('draft')) {
      bg = const Color(0xFFFEF3C7);
      textColor = const Color(0xFFD97706);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  @override
  Widget build(BuildContext context) {
    if (_laporanTerpilih != null) {
      return DetailLaporanScreen(
        item: _laporanTerpilih!,
        onBack: () => setState(() => _laporanTerpilih = null),
      );
    }

    final filtered = _listLaporan.where((item) {
      if (_selectedFilter == 'Terkirim') {
        return (item['status'] ?? '').toString().toLowerCase() == 'terkirim';
      }
      if (_selectedFilter == 'Draft') {
        return (item['status'] ?? '').toString().toLowerCase() == 'draft';
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 3,
        icon: const Icon(Icons.add_circle_outline, size: 20),
        label: const Text(
          'Buat Laporan Baru',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
        ),
        onPressed: _bukaFormTambah,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muatData,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header (Riwayat Laporan)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 20, color: Color(0xFF111827)),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'Riwayat Laporan',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Filter Chips (Semua, Terkirim, Draft)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _buildFilterChip('Semua'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Terkirim'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Draft'),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 3. Daftar Kartu Laporan
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : filtered.isEmpty
                        ? ListView(
                            padding: const EdgeInsets.all(32),
                            children: [
                              const SizedBox(height: 40),
                              Center(
                                child: Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    size: 32,
                                    color: AppConstants.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Center(
                                child: Text(
                                  'Belum Ada Laporan',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Center(
                                child: Text(
                                  'Buat laporan kegiatan harian Anda sekarang.',
                                  style: TextStyle(
                                      fontSize: 13, color: Color(0xFF6B7280)),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
                            itemCount: filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, i) {
                              final item = filtered[i];
                              return _buildLaporanCard(item);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLaporanCard(Map<String, dynamic> item) {
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
          onTap: (item['status'] ?? '').toString().toLowerCase() == 'draft'
              ? () => _bukaFormTambah(draft: item)
              : () => _bukaDetailLaporan(item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Baris Atas: Ikon + Tanggal/Waktu + Badge Terkirim
                Row(
                  children: [
                    // Squircle Document Icon
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.article,
                        color: Color(0xFF4F5BA8),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Tanggal / Waktu
                    Expanded(
                      child: Text(
                        '${item['tanggal']} • ${item['waktu']}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    // Status Pill
                    _buildStatusPill(item['status'] ?? 'Terkirim'),
                  ],
                ),
                const SizedBox(height: 12),

                // Judul Laporan Tebal
                Text(
                  item['judul'] ?? '',
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
