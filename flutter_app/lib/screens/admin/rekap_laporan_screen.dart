import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
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

  // Data default persis sesuai mockup gambar yang dikirimkan user
  final List<Map<String, dynamic>> _mockLaporan = [
    {
      'id': 1,
      'nama': 'Lilit\nRansink',
      'initials': 'LR',
      'avatarColor': const Color(0xFF2F6B64),
      'tanggal': '18 Agustus\n2026',
      'judul': 'Laporan Shift Pagi',
      'isi': 'Semua target operasional shift pagi berjalan optimal sesuai SOP.',
    },
    {
      'id': 2,
      'nama': 'Ransink\nLilit',
      'initials': 'RS',
      'avatarColor': const Color(0xFF385C83),
      'tanggal': '18 Agustus\n2026',
      'judul': 'Laporan Pemasaran',
      'isi':
          'Analisis campaign kuartal ketiga menunjukkan pertumbuhan impresi 18%.',
    },
    {
      'id': 3,
      'nama': 'Udin\nKomarudin',
      'initials': 'UK',
      'avatarColor': const Color(0xFF2F6B64),
      'tanggal': '18 Agustus\n2026',
      'judul': 'Maintenance Server',
      'isi': 'Pembaruan paket keamanan server internal selesai tanpa downtime.',
    },
    {
      'id': 4,
      'nama': 'Alak\nBizher',
      'initials': 'AB',
      'avatarColor': const Color(0xFF385C83),
      'tanggal': '18 Agustus\n2026',
      'judul': 'Pemeriksaan Logistik',
      'isi': 'Stok barang masuk dan keluar telah diverifikasi sesuai manifes.',
    },
  ];

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

  Future<void> _lihatDetailLaporan(Map<String, dynamic> item) async {
    final lampiran = item['lampiran']?.toString();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item['judul'] ?? 'Detail Laporan',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.person_outline,
                      size: 16, color: Color(0xFF4F5BA8)),
                  const SizedBox(width: 6),
                  Text(
                    (item['nama'] ?? '').toString().replaceAll('\n', ' '),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 16, color: Color(0xFF6B7280)),
                  const SizedBox(width: 6),
                  Text(
                    (item['tanggal'] ?? '').toString().replaceAll('\n', ' '),
                    style: const TextStyle(
                        fontSize: 12.5, color: Color(0xFF6B7280)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                item['isi'] ?? '-',
                style: const TextStyle(
                    fontSize: 13, height: 1.4, color: Color(0xFF374151)),
              ),
              if (lampiran != null && lampiran.isNotEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  'Dokumentasi kegiatan lapangan',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    AppConstants.getImageUrl(lampiran)!,
                    width: double.infinity,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Text(
                      'Foto dokumentasi tidak dapat dimuat.',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (item['can_edit'] == true)
            TextButton.icon(
              onPressed: () async {
                final edited = await showDialog<Map<String, String>>(
                  context: ctx,
                  builder: (_) => _EditLaporanDialog(laporan: item),
                );
                if (edited == null || !mounted) return;
                try {
                  await ApiService.editLaporanAdmin(
                    int.parse(item['id'].toString()),
                    tanggal: edited['tanggal']!,
                    judul: edited['judul']!,
                    isiLaporan: edited['isi_laporan']!,
                    jenisKegiatan: edited['jenis_kegiatan'],
                    lokasi: edited['lokasi'],
                    unitDrone: edited['unit_drone'],
                    luasArea: edited['luas_area'],
                    uraianPekerjaan: edited['uraian_pekerjaan'],
                    hasil: edited['hasil'],
                    rencanaEsok: edited['rencana_esok'],
                  );
                  if (!mounted) return;
                  Navigator.pop(context);
                  _muat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Laporan berhasil diperbarui.')),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Gagal mengedit laporan: $e')),
                  );
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit laporan'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup',
                style: TextStyle(
                    color: Color(0xFF4F5BA8), fontWeight: FontWeight.bold)),
          ),
        ],
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
                      hintText: 'Cari nama karyawan...',
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
                    List<Map<String, dynamic>> items;

                    if (snap.hasData && snap.data!.isNotEmpty) {
                      items = snap.data!.asMap().entries.map((entry) {
                        final i = entry.key;
                        final m = Map<String, dynamic>.from(entry.value);
                        final user = m['User'] ?? {};
                        final rawNama =
                            (user['nama'] ?? m['nama'] ?? 'Karyawan')
                                .toString();
                        final parts = rawNama.trim().split(RegExp(r'\s+'));
                        final initials = parts.length >= 2
                            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                            : rawNama.toUpperCase();
                        final formattedNama = parts.length >= 2
                            ? '${parts[0]}\n${parts.sublist(1).join(' ')}'
                            : rawNama;

                        final rawTgl = (m['tanggal'] ??
                                m['createdAt'] ??
                                '18 Agustus 2026')
                            .toString();
                        final formattedTgl = rawTgl.contains(' ')
                            ? rawTgl.replaceFirst(' ', '\n')
                            : rawTgl;

                        return {
                          'id': m['id'] ?? (i + 1),
                          'nama': formattedNama,
                          'initials': initials,
                          'avatarColor': i.isEven
                              ? const Color(0xFF2F6B64)
                              : const Color(0xFF385C83),
                          'tanggal': formattedTgl,
                          'judul': m['judul'] ?? 'Laporan Kegiatan',
                          'isi': m['isi_laporan'] ?? '-',
                          'lampiran': m['lampiran'],
                          'tanggal_raw': m['tanggal']?.toString() ?? '',
                          'jenis_kegiatan': m['jenis_kegiatan'] ?? '',
                          'lokasi': m['lokasi'] ?? '',
                          'unit_drone': m['unit_drone'] ?? '',
                          'luas_area': m['luas_area'] ?? '',
                          'uraian_pekerjaan':
                              m['uraian_pekerjaan'] ?? m['isi_laporan'] ?? '',
                          'hasil': m['hasil'] ?? '',
                          'rencana_esok': m['rencana_esok'] ?? '',
                          'can_edit': true,
                        };
                      }).toList();
                    } else {
                      items = _mockLaporan;
                    }

                    int totalLaporan = items.length;
                    int totalKaryawan = 20; // Sesuai mockup gambar

                    if (items == _mockLaporan) {
                      totalLaporan = 15;
                      totalKaryawan = 20;
                    }

                    final filtered = items.where((k) {
                      if (_query.isEmpty) return true;
                      final nama = (k['nama'] ?? '').toString().toLowerCase();
                      final judul = (k['judul'] ?? '').toString().toLowerCase();
                      return nama.contains(_query) || judul.contains(_query);
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                              // Header Kolom: NAMA & TANGGAL (Tanpa garis divider)
                              const Row(
                                children: [
                                  Expanded(
                                    flex: 1,
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
                                    flex: 1,
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
                                          // Kolom NAMA (Avatar + Nama 2 baris)
                                          Expanded(
                                            flex: 1,
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
                                                  child: Text(
                                                    nama,
                                                    style: const TextStyle(
                                                      fontSize: 12.5,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF111827),
                                                      height: 1.25,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Kolom TANGGAL (2 baris)
                                          Expanded(
                                            flex: 1,
                                            child: Text(
                                              tanggal,
                                              style: const TextStyle(
                                                fontSize: 12.5,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF4B5563),
                                                height: 1.25,
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

class _EditLaporanDialog extends StatefulWidget {
  final Map<String, dynamic> laporan;

  const _EditLaporanDialog({required this.laporan});

  @override
  State<_EditLaporanDialog> createState() => _EditLaporanDialogState();
}

class _EditLaporanDialogState extends State<_EditLaporanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tanggalCtrl;
  late final TextEditingController _judulCtrl;
  late final TextEditingController _jenisCtrl;
  late final TextEditingController _lokasiCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _luasCtrl;
  late final TextEditingController _uraianCtrl;
  late final TextEditingController _hasilCtrl;
  late final TextEditingController _rencanaCtrl;

  @override
  void initState() {
    super.initState();
    _tanggalCtrl =
        TextEditingController(text: widget.laporan['tanggal_raw']?.toString());
    _judulCtrl =
        TextEditingController(text: widget.laporan['judul']?.toString());
    _jenisCtrl = TextEditingController(
        text: widget.laporan['jenis_kegiatan']?.toString());
    _lokasiCtrl =
        TextEditingController(text: widget.laporan['lokasi']?.toString());
    _unitCtrl =
        TextEditingController(text: widget.laporan['unit_drone']?.toString());
    _luasCtrl =
        TextEditingController(text: widget.laporan['luas_area']?.toString());
    _uraianCtrl = TextEditingController(
        text: widget.laporan['uraian_pekerjaan']?.toString());
    _hasilCtrl =
        TextEditingController(text: widget.laporan['hasil']?.toString());
    _rencanaCtrl =
        TextEditingController(text: widget.laporan['rencana_esok']?.toString());
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    _judulCtrl.dispose();
    _jenisCtrl.dispose();
    _lokasiCtrl.dispose();
    _unitCtrl.dispose();
    _luasCtrl.dispose();
    _uraianCtrl.dispose();
    _hasilCtrl.dispose();
    _rencanaCtrl.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Wajib diisi' : null
            : null,
      ),
    );
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'tanggal': _tanggalCtrl.text.trim(),
      'judul': _judulCtrl.text.trim(),
      'jenis_kegiatan': _jenisCtrl.text.trim(),
      'lokasi': _lokasiCtrl.text.trim(),
      'unit_drone': _unitCtrl.text.trim(),
      'luas_area': _luasCtrl.text.trim(),
      'isi_laporan': _uraianCtrl.text.trim(),
      'uraian_pekerjaan': _uraianCtrl.text.trim(),
      'hasil': _hasilCtrl.text.trim(),
      'rencana_esok': _rencanaCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Laporan'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Tanggal (YYYY-MM-DD)', _tanggalCtrl, required: true),
                _field('Judul laporan', _judulCtrl, required: true),
                _field('Jenis kegiatan', _jenisCtrl),
                _field('Lokasi / area', _lokasiCtrl),
                _field('Unit drone', _unitCtrl),
                _field(
                  'Luas area',
                  _luasCtrl,
                  hint: 'Contoh: 8 Ha',
                ),
                _field(
                  'Uraian pekerjaan',
                  _uraianCtrl,
                  maxLines: 4,
                  required: true,
                ),
                _field('Hasil pekerjaan', _hasilCtrl, maxLines: 3),
                _field('Rencana esok', _rencanaCtrl, maxLines: 3),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto dokumentasi yang sudah diunggah tetap dipertahankan.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _simpan,
          child: const Text('Simpan perubahan'),
        ),
      ],
    );
  }
}
