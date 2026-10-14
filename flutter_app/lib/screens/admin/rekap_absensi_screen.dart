import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import 'components/month_picker_widget.dart';
import 'components/notifikasi_sheet.dart';

class RekapAbsensiScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaKaryawan;
  final VoidCallback? onBukaPersetujuanCuti;
  final VoidCallback? onBukaProfil;

  const RekapAbsensiScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onBack,
    this.onOpenNotifikasi,
    this.onBukaKaryawan,
    this.onBukaPersetujuanCuti,
    this.onBukaProfil,
  });

  @override
  State<RekapAbsensiScreen> createState() => _RekapAbsensiScreenState();
}

class _RekapAbsensiScreenState extends State<RekapAbsensiScreen> {
  static const _namaBulan = [
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

  late final List<String> _months;
  late String _selectedMonth;
  String _searchFilter = '';
  late Future<_RekapAbsensiHasil> _future;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _months = List.generate(
      12,
      (i) => '${_namaBulan[i]} ${now.year}',
    );
    _selectedMonth = '${_namaBulan[now.month - 1]} ${now.year}';
    _muat();
  }

  int? _extractMonth(String str) {
    if (str.startsWith('Januari')) return 1;
    if (str.startsWith('Februari')) return 2;
    if (str.startsWith('Maret')) return 3;
    if (str.startsWith('April')) return 4;
    if (str.startsWith('Mei')) return 5;
    if (str.startsWith('Juni')) return 6;
    if (str.startsWith('Juli')) return 7;
    if (str.startsWith('Agustus')) return 8;
    if (str.startsWith('September')) return 9;
    if (str.startsWith('Oktober')) return 10;
    if (str.startsWith('November')) return 11;
    if (str.startsWith('Desember')) return 12;
    return null;
  }

  int? _extractYear(String str) {
    final parts = str.split(' ');
    if (parts.length >= 2) {
      return int.tryParse(parts[1]);
    }
    return DateTime.now().year;
  }

  Map<String, dynamic> _barisKaryawan(int uid, String rawNama) {
    final parts = rawNama.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty || parts.first.isEmpty
        ? 'K'
        : (parts.length >= 2 && parts[1].isNotEmpty
            ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
            : parts[0][0].toUpperCase());
    final formattedNama = parts.length >= 2
        ? '${parts[0]}\n${parts.sublist(1).join(' ')}'
        : rawNama;
    return {
      'id': uid,
      'nama': formattedNama,
      'initials': initials,
      'avatarColor': uid.isEven
          ? const Color(0xFF385C83)
          : const Color(0xFF2F6B64),
      'hadir': 0,
      'terlambat': 0,
      'tidak_hadir': 0,
    };
  }

  Future<_RekapAbsensiHasil> _ambilRekap() async {
    final bulan = _extractMonth(_selectedMonth);
    final tahun = _extractYear(_selectedMonth);
    final results = await Future.wait([
      ApiService.rekapAbsensiAdmin(bulan: bulan, tahun: tahun),
      ApiService.daftarKaryawan(),
    ]);
    final absensi = results[0];
    final karyawan = results[1];
    final grouped = <int, Map<String, dynamic>>{};

    for (final k in karyawan) {
      final uid = int.tryParse('${k['id'] ?? ''}') ?? 0;
      if (uid < 1) continue;
      grouped[uid] = _barisKaryawan(
        uid,
        (k['nama'] ?? 'Karyawan').toString(),
      );
    }

    for (final r in absensi) {
      final user = r['User'] is Map ? r['User'] as Map : const {};
      final uid = int.tryParse('${user['id'] ?? r['user_id'] ?? 0}') ?? 0;
      if (uid < 1) continue;
      final rawNama = (user['nama'] ?? 'Karyawan').toString();
      grouped.putIfAbsent(uid, () => _barisKaryawan(uid, rawNama));

      final status = (r['status'] ?? '').toString().toLowerCase();
      if (status.contains('telat') || status.contains('terlambat')) {
        grouped[uid]!['terlambat'] = (grouped[uid]!['terlambat'] as int) + 1;
        grouped[uid]!['hadir'] = (grouped[uid]!['hadir'] as int) + 1;
      } else if (status.contains('hadir') || status.contains('tepat')) {
        grouped[uid]!['hadir'] = (grouped[uid]!['hadir'] as int) + 1;
      } else {
        grouped[uid]!['tidak_hadir'] =
            (grouped[uid]!['tidak_hadir'] as int) + 1;
      }
    }

    final items = grouped.values.toList()
      ..sort((a, b) => (a['nama'] as String)
          .replaceAll('\n', ' ')
          .compareTo((b['nama'] as String).replaceAll('\n', ' ')));

    final totalHadir =
        items.fold<int>(0, (sum, item) => sum + (item['hadir'] as int));
    final totalTidakHadir =
        items.fold<int>(0, (sum, item) => sum + (item['tidak_hadir'] as int));
    final totalHari = totalHadir + totalTidakHadir;
    final rataPersen =
        totalHari == 0 ? 0 : ((totalHadir / totalHari) * 100).round();

    return _RekapAbsensiHasil(
      items: items,
      rataKehadiranPersen: rataPersen,
      totalTidakHadir: totalTidakHadir,
    );
  }

  void _muat() {
    setState(() {
      _future = _ambilRekap();
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
      onTapCuti: widget.onBukaPersetujuanCuti,
    );
  }

  void _bukaFilterDialog() {
    final ctrl = TextEditingController(text: _searchFilter);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Filter Karyawan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Ketik nama karyawan...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchFilter = '');
              Navigator.pop(ctx);
            },
            child:
                const Text('Reset', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F5BA8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              setState(() => _searchFilter = ctrl.text.trim().toLowerCase());
              Navigator.pop(ctx);
            },
            child: const Text('Terapkan'),
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
                      'Rekap Absensi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. ROW DROPDOWN BULAN & TOMBOL FILTER KARYAWAN
                Row(
                  children: [
                    // Dropdown Pemilih Bulan Persis Komponen Figma Mockup
                    MonthPickerButtonWithPopup(
                      months: _months,
                      selectedMonth: _selectedMonth,
                      onMonthChanged: (newMonth) {
                        setState(() => _selectedMonth = newMonth);
                        _muat();
                      },
                    ),
                    const SizedBox(width: 12),

                    // Tombol Filter Karyawan
                    Expanded(
                      child: InkWell(
                        onTap: _bukaFilterDialog,
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFD1D5DB)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.tune_rounded,
                                size: 18,
                                color: Color(0xFF6B7280),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Filter Karyawan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                FutureBuilder<_RekapAbsensiHasil>(
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
                            'Gagal memuat rekap absensi.\nTarik ke bawah untuk coba lagi.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    }

                    final hasil = snap.data ??
                        const _RekapAbsensiHasil(
                          items: [],
                          rataKehadiranPersen: 0,
                          totalTidakHadir: 0,
                        );
                    final items = hasil.items;
                    final filtered = items.where((k) {
                      if (_searchFilter.isEmpty) return true;
                      final n = (k['nama'] ?? '').toString().toLowerCase();
                      return n.contains(_searchFilter);
                    }).toList();

                    return Column(
                      children: [
                        Container(
                          height: 80,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFD1D5DB),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Rata-rata Kehadiran',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${hasil.rataKehadiranPersen}%',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFA3D9A5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF236A28),
                                    size: 22,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 80,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFD1D5DB),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Total Tidak Hadir',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${hasil.totalTidakHadir}',
                                    style: const TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF111827),
                                      height: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFECDD3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Color(0xFFE11D48),
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.fromLTRB(14, 16, 14, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Kolom: NAMA | HADIR | TERLAMBAT | TIDAK HADIR /CUTI
                          const Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: Text(
                                  'NAMA',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'HADIR',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'TERLAMBAT',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'TIDAK HADIR\n/CUTI',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.2,
                                    height: 1.1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 16),

                          // Daftar Baris Rekap Absensi
                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: Text(
                                  'Tidak ada data rekap absensi',
                                  style: TextStyle(
                                      color: Color(0xFF6B7280), fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 18),
                              itemBuilder: (context, i) {
                                final item = filtered[i];
                                final nama = item['nama'] as String;
                                final initials = item['initials'] as String;
                                final avatarColor =
                                    item['avatarColor'] as Color;
                                final hadir = item['hadir'] ?? 0;
                                final terlambat = item['terlambat'] ?? 0;
                                final tidakHadir = item['tidak_hadir'] ?? 0;

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // 1. NAMA + AVATAR
                                    Expanded(
                                      flex: 4,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            radius: 16,
                                            backgroundColor: avatarColor,
                                            child: Text(
                                              initials,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              nama,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF111827),
                                                height: 1.2,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // 2. HADIR (Angka Hijau)
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '$hadir',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF16A34A),
                                        ),
                                      ),
                                    ),

                                    // 3. TERLAMBAT (Angka Oranye)
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '$terlambat',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF97316),
                                        ),
                                      ),
                                    ),

                                    // 4. TIDAK HADIR / CUTI (Angka Merah)
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        '$tidakHadir',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                        ],
                      ),
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

class _RekapAbsensiHasil {
  final List<Map<String, dynamic>> items;
  final int rataKehadiranPersen;
  final int totalTidakHadir;

  const _RekapAbsensiHasil({
    required this.items,
    required this.rataKehadiranPersen,
    required this.totalTidakHadir,
  });
}
