import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import 'components/month_picker_widget.dart';
import 'components/notifikasi_sheet.dart';

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
  final List<String> _months = const [
    'Januari 2026',
    'Februari 2026',
    'Maret 2026',
    'April 2026',
    'Mei 2026',
    'Juni 2026',
    'Juli 2026',
    'Agustus 2026',
    'September 2026',
    'Oktober 2026',
    'November 2026',
    'Desember 2026',
  ];
  String _selectedMonth = 'Agustus 2026';
  String _searchFilter = '';
  late Future<List<dynamic>> _future;

  // Data default persis sesuai mockup gambar yang dikirimkan user
  final List<Map<String, dynamic>> _mockRekap = [
    {
      'id': 1,
      'nama': 'Jungkook',
      'initials': 'JK',
      'avatarColor': const Color(0xFF2F6B64),
      'hadir': 16,
      'terlambat': 2,
      'tidak_hadir': 0,
    },
    {
      'id': 2,
      'nama': 'Dhila\nCimoy',
      'initials': 'DC',
      'avatarColor': const Color(0xFF385C83),
      'hadir': 14,
      'terlambat': 2,
      'tidak_hadir': 0,
    },
    {
      'id': 3,
      'nama': 'Lino\nBoncel',
      'initials': 'LB',
      'avatarColor': const Color(0xFF2F6B64),
      'hadir': 18,
      'terlambat': 2,
      'tidak_hadir': 0,
    },
    {
      'id': 4,
      'nama': 'Alek\nSiregar',
      'initials': 'AS',
      'avatarColor': const Color(0xFF2F6B64),
      'hadir': 12,
      'terlambat': 2,
      'tidak_hadir': 2,
    },
    {
      'id': 5,
      'nama': 'Apri\nUcup',
      'initials': 'AU',
      'avatarColor': const Color(0xFF2F6B64),
      'hadir': 17,
      'terlambat': 2,
      'tidak_hadir': 1,
    },
    {
      'id': 6,
      'nama': 'Lilit\nRansink',
      'initials': 'AU', // Di mockup gambar inisialnya adalah AU
      'avatarColor': const Color(0xFF385C83),
      'hadir': 15,
      'terlambat': 2,
      'tidak_hadir': 0,
    },
  ];

  @override
  void initState() {
    super.initState();
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
    return 2026;
  }

  void _muat() {
    setState(() {
      final bulan = _extractMonth(_selectedMonth);
      final tahun = _extractYear(_selectedMonth);
      _future = ApiService.rekapAbsensiAdmin(bulan: bulan, tahun: tahun);
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
        title: const Text('Filter Karyawan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Ketik nama karyawan...',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _searchFilter = '');
              Navigator.pop(ctx);
            },
            child: const Text('Reset', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F5BA8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hamburger + Judul Rekap Absensi
                      Row(
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
                          const SizedBox(width: 14),
                          const Text(
                            'Rekap Absensi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ],
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
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.white, width: 1.5),
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

                // 3. DUA KARTU METRIK HORIZONTAL PERSIS GAMBAR
                // Kartu 1: Rata-rata Kehadiran (87% - Centang Hijau)
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Rata-rata Kehadiran',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '87%',
                            style: TextStyle(
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

                // Kartu 2: Rata-rata Kehadiran (4 - Silang Merah)
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Rata-rata Kehadiran',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '4',
                            style: TextStyle(
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

                // 4. TABEL REKAP ABSENSI BULANAN PERSIS GAMBAR
                FutureBuilder<List<dynamic>>(
                  future: _future,
                  builder: (context, snap) {
                    List<Map<String, dynamic>> items;

                    if (snap.hasData && snap.data!.isNotEmpty) {
                      // Jika ada data riil, kelompokkan per karyawan
                      final Map<int, Map<String, dynamic>> grouped = {};
                      for (var r in snap.data!) {
                        final user = r['User'] ?? {};
                        final uid = user['id'] ?? r['user_id'] ?? 1;
                        final rawNama = (user['nama'] ?? 'Karyawan').toString();
                        final status = (r['status'] ?? '').toString().toLowerCase();

                        if (!grouped.containsKey(uid)) {
                          final parts = rawNama.trim().split(RegExp(r'\s+'));
                          final initials = parts.length >= 2
                              ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
                              : rawNama[0].toUpperCase();
                          final formattedNama = parts.length >= 2
                              ? '${parts[0]}\n${parts.sublist(1).join(' ')}'
                              : rawNama;

                          grouped[uid] = {
                            'id': uid,
                            'nama': formattedNama,
                            'initials': initials,
                            'avatarColor': uid.isEven ? const Color(0xFF385C83) : const Color(0xFF2F6B64),
                            'hadir': 0,
                            'terlambat': 0,
                            'tidak_hadir': 0,
                          };
                        }

                        if (status.contains('terlambat') || status == 'telat') {
                          grouped[uid]!['terlambat'] = (grouped[uid]!['terlambat'] as int) + 1;
                          grouped[uid]!['hadir'] = (grouped[uid]!['hadir'] as int) + 1;
                        } else if (status.contains('hadir') || status.contains('tepat')) {
                          grouped[uid]!['hadir'] = (grouped[uid]!['hadir'] as int) + 1;
                        } else {
                          grouped[uid]!['tidak_hadir'] = (grouped[uid]!['tidak_hadir'] as int) + 1;
                        }
                      }
                      items = grouped.values.toList();
                    } else {
                      items = _mockRekap;
                    }

                    // Filter nama jika user mengetik filter
                    final filtered = items.where((k) {
                      if (_searchFilter.isEmpty) return true;
                      final n = (k['nama'] ?? '').toString().toLowerCase();
                      return n.contains(_searchFilter);
                    }).toList();

                    return Container(
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
                          const Divider(height: 1, thickness: 1, color: Color(0xFFD1D5DB)),
                          const SizedBox(height: 16),

                          // Daftar Baris Rekap Absensi
                          if (filtered.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 30),
                              child: Center(
                                child: Text(
                                  'Tidak ada data rekap absensi',
                                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 18),
                              itemBuilder: (context, i) {
                                final item = filtered[i];
                                final nama = item['nama'] as String;
                                final initials = item['initials'] as String;
                                final avatarColor = item['avatarColor'] as Color;
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
                                        crossAxisAlignment: CrossAxisAlignment.center,
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
