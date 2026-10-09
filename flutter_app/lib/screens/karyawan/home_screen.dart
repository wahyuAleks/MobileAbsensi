import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/session.dart';
import '../../core/notifikasi_service.dart';
import '../../core/app_events.dart';
import 'jadwal_absensi_screen.dart';
import 'riwayat_absen_screen.dart';
import 'laporan_screen.dart';
import 'pengajuan_cuti_screen.dart';
import 'components/notifikasi_karyawan_popup.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback? onOpenAbsensi;

  const HomeScreen({super.key, this.onOpenAbsensi});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _loading = true;
  String _nama = 'Ahmad Fauzi';
  String? _fotoProfil;
  String? _jamMasuk;
  String? _jamPulang;
  List<Map<String, dynamic>> _jadwalHariIni = [];
  String? _jadwalError;

  int _countHadir = 14;
  int _countTerlambat = 2;
  int _countLaporan = 13;
  int _countCuti = 1;

  @override
  void initState() {
    super.initState();
    NotifikasiService.init();
    _muat();
    AppEvents.profileUpdated.addListener(_onSyncEvent);
    AppEvents.attendanceUpdated.addListener(_onSyncEvent);
  }

  void _onSyncEvent() {
    if (mounted) {
      _muat();
    }
  }

  @override
  void dispose() {
    AppEvents.profileUpdated.removeListener(_onSyncEvent);
    AppEvents.attendanceUpdated.removeListener(_onSyncEvent);
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _jadwalHariIni = [];
      _jamMasuk = null;
      _jamPulang = null;
    });
    try {
      _jadwalError = null;
      try {
        final jadwal = await ApiService.jadwalKerjaHariIni();
        final slots = jadwal['slots'];
        if (slots is List && mounted) {
          _jadwalHariIni =
              slots.map((item) => Map<String, dynamic>.from(item)).toList();
        } else {
          throw const FormatException('Format jadwal kerja tidak valid.');
        }
      } catch (e) {
        if (mounted) _jadwalError = e.toString();
      }
      final slotBerikutnya = _jadwalHariIni
          .cast<Map<String, dynamic>?>()
          .firstWhere(
            (slot) =>
                slot?['status'] != 'selesai' && slot?['status'] != 'terlewat',
            orElse: () => null,
          );
      _jamMasuk = _formatJam(slotBerikutnya?['jam_mulai']);
      _jamPulang = _formatJam(slotBerikutnya?['jam_selesai']);
      final nama = await Session.getNama();
      if (mounted && nama != null && nama.isNotEmpty) {
        _nama = nama;
      }

      try {
        final prof = await ApiService.getProfile();
        if (mounted) {
          if (prof['nama'] != null &&
              prof['nama'].toString().trim().isNotEmpty) {
            _nama = prof['nama'].toString().trim();
            await Session.setNama(_nama);
          }
          if (prof['foto_profil'] != null) {
            _fotoProfil = prof['foto_profil'];
          }
        }
      } catch (_) {}

      // Ambil ringkasan riwayat jika tersedia
      try {
        final riwayat = await ApiService.riwayatAbsen();
        if (riwayat.isNotEmpty) {
          int hadir = 0;
          int terlambat = 0;
          for (final r in riwayat) {
            final st = (r['status'] ?? '').toString().toLowerCase();
            if (st.contains('terlambat') || st == 'telat') {
              terlambat++;
            } else if (r['jam_masuk'] != null) {
              hadir++;
            }
          }
          if (mounted && hadir > 0) {
            _countHadir = hadir;
            _countTerlambat = terlambat;
          }
        }
      } catch (_) {}

      try {
        final lap = await ApiService.laporanSaya();
        if (mounted && lap.isNotEmpty) {
          _countLaporan = lap.length;
        }
      } catch (_) {}

      try {
        final cutiList = await ApiService.informasiCutiSaya();
        if (mounted && cutiList.isNotEmpty) {
          _countCuti = cutiList.length;
        }
      } catch (_) {}

      // Sinkronkan notifikasi live dari backend
      try {
        await NotifikasiService.syncFromBackend();
      } catch (_) {}
    } catch (_) {
      // biarkan default fallback mockup jika offline
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _salamWaktu() {
    final jam = DateTime.now().hour;
    if (jam >= 4 && jam < 11) return 'Selamat Pagi,';
    if (jam >= 11 && jam < 15) return 'Selamat Siang,';
    if (jam >= 15 && jam < 18) return 'Selamat Sore,';
    return 'Selamat Malam,';
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'AF';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  String? _formatJam(dynamic value) {
    if (value == null) return null;
    final jam = value.toString();
    return jam.length >= 5 ? jam.substring(0, 5) : jam;
  }

  Widget _buildJadwalHariIni() {
    final active = _jadwalHariIni.where(
        (slot) => slot['status'] != 'selesai' && slot['status'] != 'terlewat');
    final next = active.isEmpty ? null : active.first;
    final location = next?['Location'];
    final locationName = location is Map
        ? location['nama']?.toString() ?? 'Lokasi kerja'
        : 'Lokasi kerja';
    final start = next?['jam_mulai']?.toString();
    final startText =
        start != null && start.length >= 5 ? start.substring(0, 5) : '';

    return InkWell(
      onTap: _bukaAbsensi,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFDDE3FF)),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_note_rounded, color: Color(0xFF4F5BA8)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Jadwal kerja hari ini',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF27315B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _jadwalError != null
                        ? 'Jadwal belum dapat dimuat. Ketuk untuk mencoba lagi.'
                        : _jadwalHariIni.isEmpty
                            ? 'Belum ada jadwal kerja hari ini.'
                            : next == null
                                ? 'Semua slot kerja hari ini sudah lewat. Hubungi admin jika kamu belum sempat absen.'
                                : '${_jadwalHariIni.length} slot kerja. Slot berikutnya: $locationName${startText.isEmpty ? '' : ', pukul $startText'}.',
                    style: const TextStyle(
                      color: Color(0xFF4B5563),
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Lihat jadwal',
                    style: TextStyle(
                      color: Color(0xFF4F5BA8),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF4F5BA8)),
          ],
        ),
      ),
    );
  }

  void _bukaAbsensi() {
    if (widget.onOpenAbsensi != null) {
      widget.onOpenAbsensi!();
      return;
    }
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const JadwalAbsensiScreen(),
          ),
        )
        .then((_) => _muat());
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppConstants.primaryColor;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _muat,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER BIRU & KARTU FLOATING ABSENSI (PERSIS FIGMA)
                    Stack(
                      children: [
                        // Background biru di bagian atas (Hero Banner)
                        Container(
                          height: 200 + MediaQuery.of(context).padding.top,
                          width: double.infinity,
                          color: primaryColor,
                        ),

                        // Konten: Avatar & User Info, dilanjutkan Kartu Floating Absensi
                        SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Baris Avatar, Salam & Nama, Notifikasi
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        // Avatar Lingkaran Inisial / Foto
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF9AA7DD),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white
                                                  .withValues(alpha: 0.3),
                                              width: 1.5,
                                            ),
                                          ),
                                          child: ClipOval(
                                            child: AppConstants.getImageUrl(
                                                        _fotoProfil) !=
                                                    null
                                                ? Image.network(
                                                    AppConstants.getImageUrl(
                                                        _fotoProfil)!,
                                                    width: 44,
                                                    height: 44,
                                                    fit: BoxFit.cover,
                                                    errorBuilder:
                                                        (_, __, ___) => Center(
                                                      child: Text(
                                                        _getInitials(_nama),
                                                        style: const TextStyle(
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                                    ),
                                                  )
                                                : Center(
                                                    child: Text(
                                                      _getInitials(_nama),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Colors.white,
                                                      ),
                                                    ),
                                                  ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _salamWaktu(),
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.white
                                                    .withValues(alpha: 0.88),
                                              ),
                                            ),
                                            Text(
                                              _nama,
                                              style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    // Lonceng Notifikasi dengan Counter Angka Belum Dibaca
                                    ValueListenableBuilder<int>(
                                      valueListenable:
                                          NotifikasiService.unreadCountNotifier,
                                      builder: (context, unreadCount, _) {
                                        return IconButton(
                                          icon: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              const Icon(
                                                  Icons
                                                      .notifications_none_rounded,
                                                  color: Colors.white,
                                                  size: 26),
                                              if (unreadCount > 0)
                                                Positioned(
                                                  top: -3,
                                                  right: -4,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                      horizontal: 5,
                                                      vertical: 1.5,
                                                    ),
                                                    constraints:
                                                        const BoxConstraints(
                                                      minWidth: 18,
                                                      minHeight: 18,
                                                    ),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFEF4444),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              10),
                                                      border: Border.all(
                                                        color: Colors.white,
                                                        width: 1.8,
                                                      ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Colors.black
                                                              .withValues(
                                                                  alpha: 0.25),
                                                          blurRadius: 4,
                                                          offset: const Offset(
                                                              0, 1),
                                                        ),
                                                      ],
                                                    ),
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      unreadCount > 9
                                                          ? '9+'
                                                          : '$unreadCount',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 10,
                                                        fontWeight:
                                                            FontWeight.w800,
                                                        height: 1.1,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          onPressed: () {
                                            NotifikasiService.syncFromBackend();
                                            NotifikasiKaryawanPopup.show(
                                                context);
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 18),

                                // Kartu Floating Absensi (Jam Masuk, Jam Pulang, Absensi Sekarang)
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                        color: const Color(0xFFE5E7EB),
                                        width: 1.2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withValues(alpha: 0.06),
                                        blurRadius: 14,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Mulai Slot Berikutnya',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFF6B7280)),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _jamMasuk ?? '—:—',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 14,
                                                      vertical: 12),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFF8FAFC),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'Selesai Slot Berikutnya',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color:
                                                            Color(0xFF6B7280)),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    _jamPulang ?? '—:—',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Color(0xFF111827),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        height: 48,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: primaryColor,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                          ),
                                          onPressed: () => _bukaAbsensi(),
                                          icon: const Icon(Icons.camera_alt,
                                              size: 18),
                                          label: const Text(
                                            'Absensi Sekarang',
                                            style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: _buildJadwalHariIni(),
                    ),
                    const SizedBox(height: 20),

                    // 3. MENU CEPAT
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 8, 20, 10),
                      child: Text(
                        'MENU CEPAT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMenuCepatItem(
                            icon: Icons.camera_alt,
                            iconBg: const Color(0xFFEEF2FF),
                            iconColor: const Color(0xFF3B82F6),
                            label: 'Absen\nMasuk',
                            onTap: _bukaAbsensi,
                          ),
                          _buildMenuCepatItem(
                            icon: Icons.access_time_filled,
                            iconBg: const Color(0xFFDCFCE7),
                            iconColor: const Color(0xFF16A34A),
                            label: 'Absen\nKeluar',
                            onTap: _bukaAbsensi,
                          ),
                          _buildMenuCepatItem(
                            icon: Icons.format_list_bulleted,
                            iconBg: const Color(0xFFFFEDD5),
                            iconColor: const Color(0xFFF97316),
                            label: 'Riwayat\n ',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const RiwayatAbsenScreen()),
                              );
                            },
                          ),
                          _buildMenuCepatItem(
                            icon: Icons.assignment,
                            iconBg: const Color(0xFFEDE9FE),
                            iconColor: const Color(0xFF8B5CF6),
                            label: 'Laporan\n ',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const LaporanScreen()),
                              );
                            },
                          ),
                          _buildMenuCepatItem(
                            icon: Icons.credit_card,
                            iconBg: const Color(0xFFFEE2E2),
                            iconColor: const Color(0xFFEF4444),
                            label: 'Pengajuan\nCuti',
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const PengajuanCutiScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 4. RINGKASAN BULAN INI (2x2 Grid)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'RINGKASAN BULAN INI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.check_circle,
                                  iconBg: const Color(0xFFDCFCE7),
                                  iconColor: const Color(0xFF16A34A),
                                  title: 'Hadir',
                                  value: '$_countHadir',
                                  subtitle: 'dari 18 hari kerja',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.access_time,
                                  iconBg: const Color(0xFFFFEDD5),
                                  iconColor: const Color(0xFFEA580C),
                                  title: 'Terlambat',
                                  value: '$_countTerlambat',
                                  subtitle: 'kali terlambat',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.article,
                                  iconBg: const Color(0xFFEDE9FE),
                                  iconColor: const Color(0xFF8B5CF6),
                                  title: 'Laporan',
                                  value: '$_countLaporan',
                                  subtitle: 'laporan dikirim',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  icon: Icons.event_note,
                                  iconBg: const Color(0xFFFEE2E2),
                                  iconColor: const Color(0xFFEF4444),
                                  title: 'Cuti',
                                  value: '$_countCuti',
                                  subtitle: 'hari cuti terpakai',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 5. AKTIVITAS TERKINI (Terlihat saat scroll ke bawah)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text(
                        'AKTIVITAS TERKINI',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF9CA3AF),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: const Color(0xFFE5E7EB), width: 1.2),
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
                            _buildAktivitasItem(
                              icon: Icons.check_circle,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              title: 'Absensi Masuk',
                              subtitle: 'Kemarin, 17 Agt',
                            ),
                            const Divider(
                                height: 1,
                                indent: 60,
                                endIndent: 16,
                                color: Color(0xFFF3F4F6)),
                            _buildAktivitasItem(
                              icon: Icons.check_circle,
                              iconBg: const Color(0xFFDCFCE7),
                              iconColor: const Color(0xFF16A34A),
                              title: 'Laporan Dikirim',
                              subtitle: 'Kemarin, 17 Agt',
                            ),
                            const Divider(
                                height: 1,
                                indent: 60,
                                endIndent: 16,
                                color: Color(0xFFF3F4F6)),
                            _buildAktivitasItem(
                              icon: Icons.access_time,
                              iconBg: const Color(0xFFFFEDD5),
                              iconColor: const Color(0xFFEA580C),
                              title: 'Absensi Terlambat',
                              subtitle: '16 Agustus',
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMenuCepatItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1F2937),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAktivitasItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
