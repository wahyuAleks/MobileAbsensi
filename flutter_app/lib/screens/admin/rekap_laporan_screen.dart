import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../karyawan/detail_laporan_screen.dart';
import 'components/notifikasi_sheet.dart';

class RekapLaporanScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaProfil;

  const RekapLaporanScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onBack,
    this.onOpenNotifikasi,
    this.onBukaProfil,
  });

  @override
  State<RekapLaporanScreen> createState() => _RekapLaporanScreenState();
}

class _RekapLaporanScreenState extends State<RekapLaporanScreen> {
  late Future<List<dynamic>> _future;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _selectedProject = 'Semua Project';
  String _selectedLokasi = 'Semua Lokasi';

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
      _future = ApiService.rekapLaporan();
    });
  }

  Future<void> _bukaNotifikasi() async {
    if (widget.onOpenNotifikasi != null) {
      widget.onOpenNotifikasi!();
      return;
    }
    await NotifikasiSheet.show(
      context,
      jumlahCutiMenunggu: 3,
      jumlahBelumAbsen: 5,
      jumlahTerlambat: 2,
    );
  }

  static const _namaBulan = [
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

  String _formatTanggal(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day} ${_namaBulan[dt.month]} ${dt.year}';
    } catch (_) {
      return raw.replaceAll('\n', ' ');
    }
  }

  Future<void> _lihatDetailLaporan(Map<String, dynamic> item) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailLaporanScreen(
          item: item,
          namaKaryawan: (item['nama'] ?? '').toString().replaceAll('\n', ' '),
          useSampleFallbacks: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _muat(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. FLOATING TOP BAR PERSIS GAMBAR MOCKUP
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          size: 26,
                          color: Color(0xFF111827),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: widget.onOpenDrawer,
                      ),

                      // Bell Notifikasi & Avatar "SA"
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_rounded,
                                  size: 24,
                                  color: Color(0xFF111827),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _bukaNotifikasi,
                              ),
                              Positioned(
                                top: -2,
                                right: -2,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 1),
                                  constraints: const BoxConstraints(
                                      minWidth: 16, minHeight: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.white, width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Text(
                                    '3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.bold,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: widget.onBukaProfil,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFF488286), // Teal SA
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'SA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (widget.onBack != null) ...[
                      IconButton(
                        tooltip: 'Kembali ke halaman sebelumnya',
                        icon: const Icon(Icons.arrow_back_rounded),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'Rekap Laporan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. KOTAK SEARCH "Cari nama karyawan..." PERSIS GAMBAR
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search_rounded,
                          color: Color(0xFF9CA3AF), size: 22),
                      hintText: 'Cari nama, judul, atau isi laporan...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. DUA KARTU METRIK VERTIKAL (Laporan Masuk & Total Karyawan)
                FutureBuilder<List<dynamic>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    if (snap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text(
                            'Gagal memuat laporan.\nTarik ke bawah untuk coba lagi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }

                    final items = (snap.data ?? []).asMap().entries.map((entry) {
                      final i = entry.key;
                      final m = Map<String, dynamic>.from(entry.value as Map);
                      final user = m['User'] is Map
                          ? Map<String, dynamic>.from(m['User'] as Map)
                          : const <String, dynamic>{};
                      final rawNama =
                          (user['nama'] ?? m['nama'] ?? 'Karyawan').toString();
                      final parts = rawNama.trim().split(RegExp(r'\s+'));
                      final initials = parts.isEmpty || parts.first.isEmpty
                          ? 'K'
                          : (parts.length >= 2 && parts[1].isNotEmpty
                              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                              : parts[0][0].toUpperCase());
                      final formattedNama = parts.length >= 2
                          ? '${parts[0]}\n${parts.sublist(1).join(' ')}'
                          : rawNama;
                      final rawTgl =
                          (m['tanggal'] ?? m['createdAt'] ?? '-').toString();

                      return {
                        'id': m['id'] ?? (i + 1),
                        'nama': formattedNama,
                        'initials': initials,
                        'avatarColor': i.isEven
                            ? const Color(0xFF2F6B64)
                            : const Color(0xFF385C83),
                        'tanggal': _formatTanggal(rawTgl),
                        'judul': m['judul'] ?? 'Laporan Kegiatan',
                        'isi': m['isi_laporan'] ?? m['uraian_pekerjaan'] ?? '-',
                        'isi_laporan':
                            m['isi_laporan'] ?? m['uraian_pekerjaan'] ?? '',
                        'lampiran': m['lampiran'],
                        'status': m['status'] ?? 'Terkirim',
                        'jenis_kegiatan': m['jenis_kegiatan'] ?? '',
                        'lokasi': m['lokasi'] ?? '',
                        'unit_drone': m['unit_drone'] ?? '',
                        'luas_area': m['luas_area'] ?? '',
                        'uraian_pekerjaan':
                            m['uraian_pekerjaan'] ?? m['isi_laporan'] ?? '',
                        'hasil': m['hasil'] ?? '',
                        'rencana_esok': m['rencana_esok'] ?? '',
                      };
                    }).toList();

                    final Set<String> projectSet = {'Semua Project'};
                    final Set<String> lokasiSet = {'Semua Lokasi'};
                    for (final item in items) {
                      final p = (item['jenis_kegiatan'] ?? '').toString().trim();
                      if (p.isNotEmpty) projectSet.add(p);
                      final l = (item['lokasi'] ?? '').toString().trim();
                      if (l.isNotEmpty) lokasiSet.add(l);
                    }
                    final projectList = projectSet.toList();
                    final lokasiList = lokasiSet.toList();

                    final totalLaporan = items.length;
                    final totalKaryawan = items
                        .map((item) =>
                            (item['nama'] ?? '').toString().replaceAll('\n', ' '))
                        .toSet()
                        .length;

                    final filtered = items.where((k) {
                      if (_selectedProject != 'Semua Project') {
                        final p = (k['jenis_kegiatan'] ?? '').toString().toLowerCase();
                        if (!p.contains(_selectedProject.toLowerCase())) return false;
                      }
                      if (_selectedLokasi != 'Semua Lokasi') {
                        final l = (k['lokasi'] ?? '').toString().toLowerCase();
                        if (!l.contains(_selectedLokasi.toLowerCase())) return false;
                      }
                      if (_query.isEmpty) return true;
                      final nama = (k['nama'] ?? '').toString().toLowerCase();
                      final judul = (k['judul'] ?? '').toString().toLowerCase();
                      final isi = (k['isi'] ?? '').toString().toLowerCase();
                      return nama.contains(_query) ||
                          judul.contains(_query) ||
                          isi.contains(_query);
                    }).toList();

                    final isFiltered = _selectedProject != 'Semua Project' ||
                        _selectedLokasi != 'Semua Lokasi' ||
                        _query.isNotEmpty;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Filter Bar Dropdown (Per Project & Per Lokasi)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Filter Project
                                  Expanded(
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedProject != 'Semua Project'
                                            ? const Color(0xFFE8F5E9)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedProject != 'Semua Project'
                                              ? const Color(0xFF2E7D32)
                                              : const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: projectList.contains(_selectedProject)
                                              ? _selectedProject
                                              : 'Semua Project',
                                          isDense: true,
                                          isExpanded: true,
                                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
                                          items: projectList.map((p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p, overflow: TextOverflow.ellipsis),
                                          )).toList(),
                                          onChanged: (val) {
                                            if (val != null) setState(() => _selectedProject = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Filter Lokasi
                                  Expanded(
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      decoration: BoxDecoration(
                                        color: _selectedLokasi != 'Semua Lokasi'
                                            ? const Color(0xFFFFF7ED)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _selectedLokasi != 'Semua Lokasi'
                                              ? const Color(0xFFEA580C)
                                              : const Color(0xFFD1D5DB),
                                        ),
                                      ),
                                      child: DropdownButtonHideUnderline(
                                        child: DropdownButton<String>(
                                          value: lokasiList.contains(_selectedLokasi)
                                              ? _selectedLokasi
                                              : 'Semua Lokasi',
                                          isDense: true,
                                          isExpanded: true,
                                          icon: const Icon(Icons.arrow_drop_down, size: 20),
                                          style: const TextStyle(fontSize: 12, color: Color(0xFF1F2937)),
                                          items: lokasiList.map((l) => DropdownMenuItem(
                                            value: l,
                                            child: Text(l, overflow: TextOverflow.ellipsis),
                                          )).toList(),
                                          onChanged: (val) {
                                            if (val != null) setState(() => _selectedLokasi = val);
                                          },
                                        ),
                                      ),
                                    ),
                                  ),
                                  if (isFiltered) ...[
                                    const SizedBox(width: 6),
                                    IconButton(
                                      icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFFDC2626)),
                                      tooltip: 'Reset filter',
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      onPressed: () {
                                        setState(() {
                                          _selectedProject = 'Semua Project';
                                          _selectedLokasi = 'Semua Lokasi';
                                          _searchCtrl.clear();
                                          _query = '';
                                        });
                                      },
                                    ),
                                  ],
                                ],
                              ),
                              if (isFiltered)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'Ditemukan ${filtered.length} dari $totalLaporan laporan',
                                    style: const TextStyle(fontSize: 11, color: Color(0xFF4B5563), fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Kartu 1: Laporan Masuk
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFD1D5DB)
                                    .withValues(alpha: 0.6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Laporan Masuk',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalLaporan',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Kartu 2: Total Karyawan
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFD1D5DB)
                                    .withValues(alpha: 0.6)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Karyawan',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$totalKaryawan',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        // 4. TABEL REKAP LAPORAN PERSIS GAMBAR
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'NAMA',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF6B7280),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      'TANGGAL',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF6B7280),
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),

                              // Daftar Baris Laporan
                              if (filtered.isEmpty)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Center(
                                    child: Text(
                                      'Laporan tidak ditemukan',
                                      style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13),
                                    ),
                                  ),
                                )
                              else
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: filtered.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 22),
                                  itemBuilder: (context, i) {
                                    final item = filtered[i];
                                    final nama = item['nama'] as String;
                                    final initials = item['initials'] as String;
                                    final avatarColor =
                                        (item['avatarColor'] as Color?) ??
                                            const Color(0xFF2F6B64);
                                    final tanggal = item['tanggal'] as String;

                                    return InkWell(
                                      onTap: () => _lihatDetailLaporan(item),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                CircleAvatar(
                                                  radius: 17,
                                                  backgroundColor: avatarColor,
                                                  child: Text(
                                                    initials,
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 11.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        nama,
                                                        style: const TextStyle(
                                                          fontSize: 12.5,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Color(0xFF111827),
                                                          height: 1.25,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        (item['judul'] ??
                                                                'Laporan')
                                                            .toString(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                          fontSize: 11.5,
                                                          color:
                                                              Color(0xFF4F5BA8),
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    tanggal,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF4B5563),
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                ),
                                                const Icon(
                                                  Icons
                                                      .chevron_right_rounded,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

