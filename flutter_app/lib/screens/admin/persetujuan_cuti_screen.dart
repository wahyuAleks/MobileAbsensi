import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import 'components/alasan_penolakan_dialog.dart';
import 'components/notifikasi_sheet.dart';

class PersetujuanCutiScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaProfil;
  final VoidCallback? onBukaRekapAbsensi;

  const PersetujuanCutiScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onBack,
    this.onOpenNotifikasi,
    this.onBukaProfil,
    this.onBukaRekapAbsensi,
  });

  @override
  State<PersetujuanCutiScreen> createState() => _PersetujuanCutiScreenState();
}

class _PersetujuanCutiScreenState extends State<PersetujuanCutiScreen> {
  late Future<List<dynamic>> _future;
  String _activeFilter = 'semua'; // 'semua', 'menunggu', 'disetujui', 'ditolak'

  // Data default persis sesuai mockup gambar yang dikirimkan user (ditandai isMock: true)
  final List<Map<String, dynamic>> _mockCuti = [
    {
      'id': -1,
      'isMock': true,
      'nama': 'Mommy Jenner',
      'initials': 'MJ',
      'avatarColor': const Color(0xFF385C83),
      'tipe': 'Cuti Tahunan',
      'durasi': '2 Hari',
      'periode': '25 - 26 Agustus 2026',
      'alasan': 'Ada urusan keluarga',
      'status': 'disetujui',
      'alasan_penolakan': null,
    },
    {
      'id': -2,
      'isMock': true,
      'nama': 'Alak Bizher',
      'initials': 'AB',
      'avatarColor': const Color(0xFF385C83),
      'tipe': 'Cuti Sakit',
      'durasi': '1 Hari',
      'periode': '28 Agustus 2026',
      'alasan': 'Sakit flu dengan surat\ndokter',
      'status': 'menunggu',
      'alasan_penolakan': null,
    },
    {
      'id': -3,
      'isMock': true,
      'nama': 'Alak Bizher',
      'initials': 'AB',
      'avatarColor': const Color(0xFF385C83),
      'tipe': 'Cuti Sakit',
      'durasi': '1 Hari',
      'periode': '28 Agustus 2026',
      'alasan': 'Sakit flu dengan surat\ndokter',
      'status': 'ditolak',
      'alasan_penolakan':
          'Ditolak: Staf terlalu sedikit saya periode tersebut.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  void _muat() {
    setState(() {
      _future = ApiService.daftarPengajuanCuti();
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

  Future<void> _setujuiCuti(Map<String, dynamic> item) async {
    final nama = item['nama'] ?? 'Karyawan';
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Setujui Pengajuan Cuti',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Yakin ingin menyetujui pengajuan cuti untuk $nama?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF33691E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Setujui'),
          ),
        ],
      ),
    );

    if (konfirmasi != true) return;

    try {
      if (item['isMock'] == true) {
        setState(() {
          final idx = _mockCuti.indexWhere((x) => x['id'] == item['id']);
          if (idx != -1) {
            _mockCuti[idx]['status'] = 'disetujui';
          }
        });
      } else if (item['id'] != null) {
        final id = int.tryParse(item['id'].toString());
        if (id != null) {
          await ApiService.prosesCuti(id, 'diterima');
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pengajuan cuti berhasil disetujui'),
            backgroundColor: Color(0xFF16A34A)),
      );
      _muat();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _tolakCuti(Map<String, dynamic> item) async {
    final nama = item['nama'] ?? 'Karyawan';
    final alasan = await AlasanPenolakanDialog.show(
      context,
      title: 'Tolak Cuti',
      label: 'Alasan Penolakan',
      hintText: 'Tuliskan alasan penolakan cuti untuk $nama...',
      confirmText: 'Konfirmasi Penolakan',
      cancelText: 'Batal',
    );

    if (alasan == null || alasan.trim().isEmpty) return;

    try {
      if (item['isMock'] == true) {
        setState(() {
          final idx = _mockCuti.indexWhere((x) => x['id'] == item['id']);
          if (idx != -1) {
            _mockCuti[idx]['status'] = 'ditolak';
            _mockCuti[idx]['alasan_penolakan'] = 'Ditolak: ${alasan.trim()}';
          }
        });
      } else if (item['id'] != null) {
        final id = int.tryParse(item['id'].toString());
        if (id != null) {
          await ApiService.prosesCuti(id, 'ditolak', catatan: alasan.trim());
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Pengajuan cuti ditolak'),
            backgroundColor: Color(0xFFDC2626)),
      );
      _muat();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _lihatDetail(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          item['nama'] ?? 'Detail Cuti',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Jenis: ${item['tipe']}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('Durasi: ${item['durasi']}'),
            const SizedBox(height: 6),
            Text('Periode: ${item['periode']}'),
            const SizedBox(height: 6),
            Text('Alasan: ${item['alasan']}'),
            if (item['alasan_penolakan'] != null) ...[
              const SizedBox(height: 8),
              Text(
                '${item['alasan_penolakan']}',
                style: const TextStyle(
                    color: Color(0xFFDC2626), fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _buildSummaryBadge({
    required String label,
    required int count,
    required Color labelBg,
    required Color labelColor,
    required String filterKey,
  }) {
    final isSelected = _activeFilter == filterKey;
    return InkWell(
      onTap: () {
        setState(() {
          _activeFilter = isSelected ? 'semua' : filterKey;
        });
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color:
                isSelected ? const Color(0xFF4F5BA8) : const Color(0xFFE5E7EB),
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: labelBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: labelColor,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ],
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
                      'Persetujuan Cuti',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // 2. DAFTAR & SUMMARY BADGES DINAMIS
                FutureBuilder<List<dynamic>>(
                  future: _future,
                  builder: (context, snap) {
                    List<Map<String, dynamic>> items;

                    if (snap.hasData && snap.data!.isNotEmpty) {
                      items = snap.data!.map((e) {
                        final m = Map<String, dynamic>.from(e);
                        final user = m['User'] ?? {};
                        final rawNama =
                            (user['nama'] ?? m['nama'] ?? 'Karyawan')
                                .toString();
                        final parts = rawNama.trim().split(RegExp(r'\s+'));
                        final initials = parts.length >= 2
                            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                            : (rawNama.isNotEmpty
                                ? rawNama[0].toUpperCase()
                                : 'K');

                        final statusRaw = (m['status'] ?? 'menunggu')
                            .toString()
                            .toLowerCase();
                        String normalizedStatus = 'menunggu';
                        if (statusRaw.contains('terima') ||
                            statusRaw.contains('setuju')) {
                          normalizedStatus = 'disetujui';
                        } else if (statusRaw.contains('tolak')) {
                          normalizedStatus = 'ditolak';
                        }

                        final tglMulai = m['tanggal_mulai'] ?? '-';
                        final tglSelesai = m['tanggal_selesai'] ?? '-';
                        final periode = (tglMulai == tglSelesai)
                            ? '$tglMulai'
                            : '$tglMulai - $tglSelesai';

                        int durasiHari = 1;
                        try {
                          final d1 = DateTime.parse(tglMulai.toString());
                          final d2 = DateTime.parse(tglSelesai.toString());
                          durasiHari = d2.difference(d1).inDays + 1;
                          if (durasiHari < 1) durasiHari = 1;
                        } catch (_) {}

                        return {
                          'id': m['id'],
                          'isMock': false,
                          'nama': rawNama,
                          'initials': initials,
                          'avatarColor': const Color(0xFF385C83),
                          'tipe':
                              m['jenis_cuti'] ?? m['tipe'] ?? 'Cuti Tahunan',
                          'durasi': '$durasiHari Hari',
                          'periode': periode,
                          'alasan': m['alasan'] ?? '-',
                          'status': normalizedStatus,
                          'alasan_penolakan': m['catatan_admin'],
                        };
                      }).toList();
                    } else {
                      items = _mockCuti;
                    }

                    final countMenunggu =
                        items.where((k) => k['status'] == 'menunggu').length;
                    final countDisetujui =
                        items.where((k) => k['status'] == 'disetujui').length;
                    final countDitolak =
                        items.where((k) => k['status'] == 'ditolak').length;

                    // Filter list
                    final displayed = items.where((k) {
                      if (_activeFilter == 'semua') return true;
                      return k['status'] == _activeFilter;
                    }).toList();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row 1: Menunggu & Disetujui
                        Row(
                          children: [
                            _buildSummaryBadge(
                              label: 'Menunggu',
                              count: countMenunggu,
                              labelBg: const Color(0xFFFDE8C7),
                              labelColor: const Color(0xFFD97706),
                              filterKey: 'menunggu',
                            ),
                            const SizedBox(width: 12),
                            _buildSummaryBadge(
                              label: 'Disetujui',
                              count: countDisetujui,
                              labelBg: const Color(0xFFDCFCE7),
                              labelColor: const Color(0xFF15803D),
                              filterKey: 'disetujui',
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Row 2: Ditolak
                        _buildSummaryBadge(
                          label: 'Ditolak',
                          count: countDitolak,
                          labelBg: const Color(0xFFFECDD3),
                          labelColor: const Color(0xFFDC2626),
                          filterKey: 'ditolak',
                        ),
                        const SizedBox(height: 18),

                        if (displayed.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(
                              child: Text(
                                'Tidak ada pengajuan cuti untuk status ini',
                                style: TextStyle(
                                    color: Color(0xFF6B7280), fontSize: 14),
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: displayed.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, i) {
                              final item = displayed[i];
                              final status = item['status'] as String;
                              final nama = item['nama'] as String;
                              final initials = item['initials'] as String;
                              final avatarColor =
                                  (item['avatarColor'] as Color?) ??
                                      const Color(0xFF385C83);
                              final tipe = item['tipe'] as String;
                              final durasi = item['durasi'] as String;
                              final periode = item['periode'] as String;
                              final alasan = item['alasan'] as String;
                              final alasanPenolakan =
                                  item['alasan_penolakan'] as String?;

                              // Status Badge Colors
                              Color badgeBg;
                              Color badgeTextColor;
                              String badgeText;

                              if (status == 'disetujui') {
                                badgeBg = const Color(0xFFDCFCE7);
                                badgeTextColor = const Color(0xFF15803D);
                                badgeText = 'Disetujui';
                              } else if (status == 'ditolak') {
                                badgeBg = const Color(0xFFFECDD3);
                                badgeTextColor = const Color(0xFFDC2626);
                                badgeText = 'Ditolak';
                              } else {
                                badgeBg = const Color(0xFFFDE8C7);
                                badgeTextColor = const Color(0xFFD97706);
                                badgeText = 'Menunggu';
                              }

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // 1. Header Card: Avatar + Nama/Cuti & Status Badge
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 18,
                                              backgroundColor: avatarColor,
                                              child: Text(
                                                initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  nama,
                                                  style: const TextStyle(
                                                    fontSize: 14.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF111827),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '$tipe • $durasi',
                                                  style: const TextStyle(
                                                    fontSize: 12,
                                                    color: Color(0xFF9CA3AF),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 14, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: badgeBg,
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            badgeText,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: badgeTextColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // 2. Info Periode & Alasan
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Kolom Periode
                                        Expanded(
                                          flex: 4,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Periode',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                periode,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF111827),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Kolom Alasan
                                        Expanded(
                                          flex: 5,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Alasan',
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                  color: Color(0xFF9CA3AF),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                alasan,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF111827),
                                                  height: 1.25,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // 3. Tombol Aksi Untuk Status 'Menunggu' (✓ Setujui | X Tolak | Detail)
                                    if (status == 'menunggu') ...[
                                      const SizedBox(height: 16),
                                      Row(
                                        children: [
                                          // Tombol Setujui
                                          InkWell(
                                            onTap: () => _setujuiCuti(item),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                    0xFF33691E), // Olive green persis gambar
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                '✓ Setujui',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Tombol Tolak
                                          InkWell(
                                            onTap: () => _tolakCuti(item),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: const Color(
                                                    0xFFE11D48), // Crimson red persis gambar
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: const Text(
                                                'X Tolak',
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),

                                          // Tombol Detail
                                          InkWell(
                                            onTap: () => _lihatDetail(item),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 16,
                                                      vertical: 8),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: Colors.black
                                                        .withValues(
                                                            alpha: 0.05),
                                                    blurRadius: 4,
                                                    offset: const Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                              child: const Text(
                                                'Detail',
                                                style: TextStyle(
                                                  color: Color(0xFF111827),
                                                  fontSize: 12.5,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],

                                    // 4. Kotak Alasan Penolakan Untuk Status 'Ditolak'
                                    if (status == 'ditolak' &&
                                        alasanPenolakan != null &&
                                        alasanPenolakan.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 14, vertical: 10),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFCE7F3)
                                              .withValues(
                                                  alpha: 0.8), // Light pink box
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          alasanPenolakan,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFFDC2626),
                                            height: 1.25,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
