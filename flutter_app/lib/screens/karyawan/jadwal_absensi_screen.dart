import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/app_events.dart';
import 'verifikasi_wajah_screen.dart';

class JadwalAbsensiScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const JadwalAbsensiScreen({super.key, this.onBack});

  @override
  State<JadwalAbsensiScreen> createState() => _JadwalAbsensiScreenState();
}

class _JadwalAbsensiScreenState extends State<JadwalAbsensiScreen> {
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;
  String? _error;
  String? _tanggal;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _muatJadwal();
    _refreshTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => _muatJadwal(showLoading: false),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _muatJadwal({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final response = await ApiService.jadwalKerjaHariIni();
      final rawSlots = response['slots'];
      if (rawSlots is! List) {
        throw const FormatException('Format jadwal kerja tidak valid.');
      }
      if (!mounted) return;
      setState(() {
        _slots =
            rawSlots.map((item) => Map<String, dynamic>.from(item)).toList();
        _tanggal = response['tanggal']?.toString();
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _mulaiAbsen(Map<String, dynamic> slot, bool isMasuk) async {
    final id = int.tryParse(slot['id'].toString());
    final location = slot['Location'];
    final locationName = location is Map
        ? location['nama']?.toString() ?? 'Lokasi kerja'
        : 'Lokasi kerja';
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Data slot kerja tidak valid. Muat ulang jadwal Anda.')),
      );
      return;
    }
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => VerifikasiWajahScreen(
          isMasuk: isMasuk,
          jadwalId: id,
          lokasiNama: locationName,
        ),
      ),
    );
    if (success == true) {
      await _muatJadwal();
      AppEvents.notifyAttendanceUpdated();
    }
  }

  String _tanggalIndo(String? value) {
    if (value == null) return 'Hari ini';
    final date = DateTime.tryParse(value);
    if (date == null) return 'Hari ini';
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const months = [
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
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _jam(String? value) =>
      value != null && value.length >= 5 ? value.substring(0, 5) : '--:--';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muatJadwal,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
            children: [
              Row(
                children: [
                  if (widget.onBack != null || Navigator.canPop(context)) ...[
                    IconButton(
                      tooltip: 'Kembali ke halaman sebelumnya',
                      onPressed: widget.onBack ??
                          () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'Absensi',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF111827),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _tanggalIndo(_tanggal),
                style: const TextStyle(color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 18),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _buildError()
              else if (_slots.isEmpty)
                _buildNoSchedule()
              else ...[
                Text(
                  _slots.length == 1
                      ? 'Jadwal kerja hari ini'
                      : '${_slots.length} jadwal kerja hari ini',
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                for (final slot in _slots) ...[
                  _buildSlotCard(slot),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 4),
                const Text(
                  'Absen masuk tersedia mulai 30 menit sebelum jadwal. Absen pulang tersedia setelah jam kerja selesai.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final location = slot['Location'];
    final locationName = location is Map
        ? location['nama']?.toString() ?? 'Lokasi kerja'
        : 'Lokasi kerja';
    final status = slot['status']?.toString() ?? '';
    final action = slot['action']?.toString();
    final color = switch (status) {
      'bisa_masuk' => const Color(0xFF15803D),
      'terlambat' => const Color(0xFFB45309),
      'menunggu_pulang' => const Color(0xFF1D4ED8),
      'selesai' => const Color(0xFF047857),
      'terlewat' => const Color(0xFFB91C1C),
      _ => const Color(0xFF6B7280),
    };
    final title = switch (status) {
      'belum_waktunya' => 'Belum waktunya',
      'bisa_masuk' => 'Bisa absen masuk',
      'terlambat' => 'Terlambat',
      'menunggu_pulang' => 'Sedang bekerja',
      'selesai' => 'Selesai',
      'terlewat' => 'Slot terlewat',
      _ => 'Jadwal kerja',
    };
    final attendance = slot['absensi'];
    final record = attendance is List && attendance.isNotEmpty
        ? Map<String, dynamic>.from(attendance.first)
        : null;
    final checkedIn = record?['jam_masuk']?.toString();
    final checkedOut = record?['jam_pulang']?.toString();

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    color: Color(0xFF4F5BA8)),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        locationName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_jam(slot['jam_mulai']?.toString())}–${_jam(slot['jam_selesai']?.toString())}',
                        style: const TextStyle(color: Color(0xFF4B5563)),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              slot['message']?.toString() ?? '',
              style: const TextStyle(
                color: Color(0xFF4B5563),
                height: 1.35,
              ),
            ),
            if (checkedIn != null || checkedOut != null) ...[
              const SizedBox(height: 9),
              Text(
                'Masuk: ${_jam(checkedIn)}${checkedOut == null ? '' : '   •   Pulang: ${_jam(checkedOut)}'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
            if (action == 'masuk' || action == 'pulang') ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _mulaiAbsen(slot, action == 'masuk'),
                  icon: Icon(action == 'masuk'
                      ? Icons.login_rounded
                      : Icons.logout_rounded),
                  label:
                      Text(action == 'masuk' ? 'Mulai Absen' : 'Absen Pulang'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF4F5BA8),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoSchedule() => Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Column(
          children: [
            Icon(Icons.event_busy_outlined, size: 42, color: Color(0xFF9CA3AF)),
            SizedBox(height: 10),
            Text(
              'Belum ada jadwal kerja hari ini',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            SizedBox(height: 6),
            Text(
              'Kalau kamu merasa seharusnya ada jadwal, hubungi admin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
          ],
        ),
      );

  Widget _buildError() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_outlined, color: Color(0xFFB91C1C)),
            const SizedBox(height: 8),
            const Text(
              'Jadwal kerja belum dapat dimuat.',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), fontSize: 12),
            ),
            TextButton(
              onPressed: _muatJadwal,
              child: const Text('Coba lagi'),
            ),
          ],
        ),
      );
}
