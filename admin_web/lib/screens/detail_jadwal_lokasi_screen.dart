import 'package:flutter/material.dart';
import '../core/api_service.dart';
import 'components/karyawan_multi_picker.dart';

String _formatRadiusKm(Object? radiusMeters) {
  final meters = double.tryParse(radiusMeters?.toString() ?? '');
  if (meters == null || !meters.isFinite) return '0 km';
  final km = (meters / 1000).toStringAsFixed(3);
  return '${km.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} km';
}

String _formatTanggal(DateTime date) {
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

class DetailJadwalLokasiScreen extends StatefulWidget {
  final Map<String, dynamic> location;
  final DateTime tanggal;
  final List<Map<String, dynamic>> allEmployees;
  final VoidCallback onJadwalChanged;

  const DetailJadwalLokasiScreen({
    super.key,
    required this.location,
    required this.tanggal,
    required this.allEmployees,
    required this.onJadwalChanged,
  });

  @override
  State<DetailJadwalLokasiScreen> createState() =>
      _DetailJadwalLokasiScreenState();
}

class _DetailJadwalLokasiScreenState extends State<DetailJadwalLokasiScreen> {
  List<Map<String, dynamic>> _slots = [];
  bool _loading = true;
  String? _error;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  String get _tanggalApi =>
      widget.tanggal.toIso8601String().substring(0, 10);

  int get _locationId =>
      int.tryParse(widget.location['id']?.toString() ?? '') ?? -1;

  String get _locationName =>
      widget.location['nama']?.toString() ?? 'Lokasi';

  @override
  void initState() {
    super.initState();
    _muatJadwal();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _muatJadwal() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rawSlots = await ApiService.jadwalKerjaTanggal(_tanggalApi);
      final mappedSlots = rawSlots
          .map((item) => Map<String, dynamic>.from(item))
          .where((slot) {
        final locId = int.tryParse(slot['location_id']?.toString() ?? '');
        return locId == _locationId;
      }).toList();

      if (!mounted) return;
      setState(() {
        _slots = mappedSlots;
        _loading = false;
      });
      widget.onJadwalChanged();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _message(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _hapusSlot(Map<String, dynamic> slot) async {
    final attendance = slot['absensi'];
    if (attendance is List && attendance.isNotEmpty) {
      _message('Slot tidak dapat dihapus karena absensi sudah tercatat.');
      return;
    }
    final user = slot['User'] is Map ? slot['User']['nama'] : 'karyawan';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jadwal kerja?'),
        content: Text(
          'Jadwal untuk $user di $_locationName pada ${_formatTanggal(widget.tanggal)} akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await ApiService.hapusJadwalKerja(int.parse(slot['id'].toString()));
      await _muatJadwal();
      _message('Jadwal $user berhasil dihapus.');
    } catch (e) {
      _message('Gagal menghapus jadwal: $e');
    }
  }

  Future<void> _editSlot(Map<String, dynamic> slot) async {
    final attendance = slot['absensi'];
    if (attendance is List && attendance.isNotEmpty) {
      _message('Slot tidak dapat diubah karena absensi sudah tercatat.');
      return;
    }

    final userId = int.tryParse(slot['user_id']?.toString() ?? '');
    final startRaw = slot['jam_mulai']?.toString();
    final endRaw = slot['jam_selesai']?.toString();

    TimeOfDay parseTime(String? raw, TimeOfDay fallback) {
      if (raw == null || raw.length < 5) return fallback;
      final parts = raw.substring(0, 5).split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return fallback;
      return TimeOfDay(hour: h, minute: m);
    }

    int? selectedUserId = userId;
    TimeOfDay startTime = parseTime(startRaw, const TimeOfDay(hour: 8, minute: 0));
    TimeOfDay endTime = parseTime(endRaw, const TimeOfDay(hour: 17, minute: 0));

    final updated = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          String timeStr(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            title: const Text('Ubah Jadwal Karyawan'),
            content: SizedBox(
              width: 400,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lokasi: $_locationName',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF4338CA)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: selectedUserId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Pilih Karyawan',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.allEmployees
                        .map((emp) => DropdownMenuItem<int>(
                              value: int.tryParse(emp['id'].toString()),
                              child: Text(emp['nama']?.toString() ?? '-'),
                            ))
                        .toList(),
                    onChanged: (val) => setDialogState(() => selectedUserId = val),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pick = await showTimePicker(
                              context: context,
                              initialTime: startTime,
                              builder: (context, child) => MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              ),
                            );
                            if (pick != null) {
                              setDialogState(() => startTime = pick);
                            }
                          },
                          icon: const Icon(Icons.login_rounded, size: 18),
                          label: Text('Mulai ${timeStr(startTime)}'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final pick = await showTimePicker(
                              context: context,
                              initialTime: endTime,
                              builder: (context, child) => MediaQuery(
                                data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                child: child!,
                              ),
                            );
                            if (pick != null) {
                              setDialogState(() => endTime = pick);
                            }
                          },
                          icon: const Icon(Icons.logout_rounded, size: 18),
                          label: Text('Selesai ${timeStr(endTime)}'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: selectedUserId == null
                    ? null
                    : () async {
                        final s = timeStr(startTime);
                        final e = timeStr(endTime);
                        if (s.compareTo(e) >= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jam selesai harus setelah jam mulai.'),
                            ),
                          );
                          return;
                        }
                        try {
                          await ApiService.simpanJadwalKerja(
                            id: int.parse(slot['id'].toString()),
                            userId: selectedUserId!,
                            locationId: _locationId,
                            tanggal: _tanggalApi,
                            jamMulai: s,
                            jamSelesai: e,
                          );
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                        } catch (err) {
                          if (dialogCtx.mounted) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan: $err')),
                            );
                          }
                        }
                      },
                child: const Text('Simpan Perubahan'),
              ),
            ],
          );
        },
      ),
    );

    if (updated == true) {
      await _muatJadwal();
      _message('Jadwal kerja berhasil diperbarui.');
    }
  }

  Future<void> _tambahJadwal() async {
    final Set<int> selectedUserIds = {};
    TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay endTime = const TimeOfDay(hour: 17, minute: 0);

    final result = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setDialogState) {
          String timeStr(TimeOfDay t) =>
              '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

          return AlertDialog(
            title: Text('Tambah Jadwal di $_locationName'),
            content: SizedBox(
              width: 580,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal: ${_formatTanggal(widget.tanggal)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF4338CA),
                      ),
                    ),
                    const SizedBox(height: 12),
                    KaryawanMultiPicker(
                      employees: widget.allEmployees,
                      selectedIds: selectedUserIds,
                      onChanged: (updated) {
                        setDialogState(() {
                          selectedUserIds
                            ..clear()
                            ..addAll(updated);
                        });
                      },
                      maxHeight: 220,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Jam Kerja:',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pick = await showTimePicker(
                                context: context,
                                initialTime: startTime,
                                builder: (context, child) => MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                              if (pick != null) {
                                setDialogState(() => startTime = pick);
                              }
                            },
                            icon: const Icon(Icons.login_rounded, size: 18),
                            label: Text('Mulai ${timeStr(startTime)}'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final pick = await showTimePicker(
                                context: context,
                                initialTime: endTime,
                                builder: (context, child) => MediaQuery(
                                  data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
                                  child: child!,
                                ),
                              );
                              if (pick != null) {
                                setDialogState(() => endTime = pick);
                              }
                            },
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: Text('Selesai ${timeStr(endTime)}'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: selectedUserIds.isEmpty
                    ? null
                    : () async {
                        final s = timeStr(startTime);
                        final e = timeStr(endTime);
                        if (s.compareTo(e) >= 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Jam selesai harus setelah jam mulai.'),
                            ),
                          );
                          return;
                        }
                        try {
                          await ApiService.simpanJadwalKerjaUntukBanyakKaryawan(
                            userIds: selectedUserIds.toList(),
                            locationId: _locationId,
                            tanggal: _tanggalApi,
                            jamMulai: s,
                            jamSelesai: e,
                          );
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
                        } catch (err) {
                          if (dialogCtx.mounted) {
                            ScaffoldMessenger.of(dialogCtx).showSnackBar(
                              SnackBar(content: Text('Gagal menyimpan: $err')),
                            );
                          }
                        }
                      },
                child: Text('Simpan (${selectedUserIds.length} Karyawan)'),
              ),
            ],
          );
        },
      ),
    );

    if (result == true) {
      await _muatJadwal();
      _message('Jadwal baru di $_locationName berhasil ditambahkan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredSlots = _slots.where((slot) {
      if (_searchQuery.trim().isEmpty) return true;
      final user = slot['User'] is Map ? slot['User'] as Map : const {};
      final name = (user['nama']?.toString() ?? '').toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1F2937)),
          tooltip: 'Kembali ke jadwal',
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jadwal Karyawan • $_locationName',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1F2937),
              ),
            ),
            Text(
              _formatTanggal(widget.tanggal),
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Segarkan data',
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF4B5563)),
            onPressed: _muatJadwal,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16, left: 8),
            child: FilledButton.icon(
              onPressed: _tambahJadwal,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Tambah Jadwal di Sini'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF4338CA),
              ),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFE5E7EB)),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muatJadwal,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            children: [
              // Banner info lokasi
              _buildLocationBanner(),
              const SizedBox(height: 18),

              // Search bar jika data lebih dari 2
              if (_slots.length > 2) ...[
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama karyawan di lokasi ini...',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
                const SizedBox(height: 18),
              ],

              // Content List
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _buildError()
              else if (_slots.isEmpty)
                _buildEmpty()
              else if (filteredSlots.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Tidak ada karyawan dengan nama "$_searchQuery" di lokasi ini.',
                      style: const TextStyle(color: Color(0xFF6B7280)),
                    ),
                  ),
                )
              else
                ...filteredSlots.map(_buildSlotCard).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationBanner() {
    final lat = widget.location['latitude'];
    final lng = widget.location['longitude'];
    final hasGps = lat != null && lng != null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            offset: Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Color(0xFF4338CA),
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _locationName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: _slots.isNotEmpty
                            ? const Color(0xFFE0E7FF)
                            : const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${_slots.length} Karyawan Terjadwal',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _slots.isNotEmpty
                              ? const Color(0xFF4338CA)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasGps
                      ? 'GPS Aktif • Batas radius absen: ${_formatRadiusKm(widget.location['radius_meters'])} ($lat, $lng)'
                      : 'Titik koordinat GPS belum diatur untuk lokasi ini',
                  style: TextStyle(
                    fontSize: 13,
                    color: hasGps ? const Color(0xFF4B5563) : const Color(0xFFDC2626),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlotCard(Map<String, dynamic> slot) {
    final user = slot['User'] is Map ? slot['User'] as Map : const {};
    final attendance = slot['absensi'];
    final locked = attendance is List && attendance.isNotEmpty;
    final start = slot['jam_mulai']?.toString() ?? '--:--';
    final end = slot['jam_selesai']?.toString() ?? '--:--';
    final nama = user['nama']?.toString() ?? 'Karyawan';
    final email = user['email']?.toString() ?? '';

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(
                nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF4338CA),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_rounded,
                        size: 15,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${start.substring(0, 5)} - ${end.substring(0, 5)} WIB',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF374151),
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(width: 10),
                        Text(
                          '• $email',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status Absensi
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: locked ? const Color(0xFFDCFCE7) : const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    locked ? Icons.check_circle_rounded : Icons.pending_rounded,
                    size: 14,
                    color: locked ? const Color(0xFF15803D) : const Color(0xFFB45309),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    locked ? 'Absensi Tercatat' : 'Belum Absen',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: locked ? const Color(0xFF15803D) : const Color(0xFFB45309),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Actions
            IconButton(
              tooltip: locked ? 'Absensi sudah tercatat' : 'Ubah jam/karyawan',
              onPressed: locked ? null : () => _editSlot(slot),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              tooltip: locked ? 'Absensi sudah tercatat' : 'Hapus jadwal',
              onPressed: locked ? null : () => _hapusSlot(slot),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Color(0xFFF3F4F6),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.event_busy_rounded,
                  size: 48,
                  color: Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Belum Ada Jadwal di $_locationName',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF374151),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Karyawan belum memiliki penugasan jam kerja di lokasi ini untuk ${_formatTanggal(widget.tanggal)}.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 13),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _tambahJadwal,
                icon: const Icon(Icons.add_rounded),
                label: Text('Jadwalkan Karyawan di $_locationName'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF4338CA),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );

  Widget _buildError() => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: Color(0xFFDC2626)),
            const SizedBox(height: 10),
            const Text(
              'Gagal memuat jadwal lokasi.',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _muatJadwal, child: const Text('Coba lagi')),
          ],
        ),
      );
}
