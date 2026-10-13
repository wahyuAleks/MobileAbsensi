import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_dragmarker/flutter_map_dragmarker.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/api_service.dart';

String _formatRadiusKm(Object? radiusMeters) {
  final meters = double.tryParse(radiusMeters?.toString() ?? '');
  if (meters == null || !meters.isFinite) return '0 km';
  final km = (meters / 1000).toStringAsFixed(3);
  return '${km.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '')} km';
}

class JadwalKaryawanScreen extends StatefulWidget {
  const JadwalKaryawanScreen({super.key});

  @override
  State<JadwalKaryawanScreen> createState() => _JadwalKaryawanScreenState();
}

class _JadwalKaryawanScreenState extends State<JadwalKaryawanScreen> {
  DateTime _tanggal = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _locations = [];
  int? _employeeId;
  final Set<int> _selectedEmployeeIds = {};
  int? _locationId;
  int? _editingId;
  TimeOfDay _start = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _tanggalApi => _tanggal.toIso8601String().substring(0, 10);

  Map<String, dynamic>? get _selectedLocation {
    for (final location in _locations) {
      if (int.tryParse(location['id'].toString()) == _locationId) {
        return location;
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ApiService.jadwalKerjaTanggal(_tanggalApi),
        ApiService.daftarKaryawan(),
        ApiService.daftarLokasi(),
      ]);
      if (!mounted) return;
      setState(() {
        _slots =
            results[0].map((item) => Map<String, dynamic>.from(item)).toList();
        _employees = results[1]
            .map((item) => Map<String, dynamic>.from(item))
            .where((item) =>
                item['is_active'] == true ||
                item['is_active'] == 1 ||
                item['is_active'] == '1')
            .toList();
        _locations =
            results[2].map((item) => Map<String, dynamic>.from(item)).toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pilihTanggal() async {
    final chosen = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal kerja',
    );
    if (chosen == null) return;
    setState(() {
      _tanggal = chosen;
      _resetForm();
    });
    await _muat();
  }

  void _resetForm() {
    _editingId = null;
    _employeeId = null;
    _selectedEmployeeIds.clear();
    _locationId = null;
    _start = const TimeOfDay(hour: 8, minute: 0);
    _end = const TimeOfDay(hour: 17, minute: 0);
  }

  void _edit(Map<String, dynamic> slot) {
    final attendance = slot['absensi'];
    if (attendance is List && attendance.isNotEmpty) {
      _message('Slot tidak bisa diubah setelah absensi tercatat.');
      return;
    }
    setState(() {
      _editingId = int.tryParse(slot['id'].toString());
      _employeeId = int.tryParse(slot['user_id'].toString());
      _selectedEmployeeIds.clear();
      if (_employeeId != null) _selectedEmployeeIds.add(_employeeId!);
      _locationId = int.tryParse(slot['location_id'].toString());
      _start = _parseTime(slot['jam_mulai']?.toString()) ?? _start;
      _end = _parseTime(slot['jam_selesai']?.toString()) ?? _end;
    });
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.length < 5) return null;
    final parts = raw.substring(0, 5).split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _timeString(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool start) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _start = selected;
      } else {
        _end = selected;
      }
    });
  }

  Future<void> _simpan() async {
    if (_locationId == null) {
      _message('Pilih lokasi kerja terlebih dahulu.');
      return;
    }
    if (_editingId == null && _selectedEmployeeIds.isEmpty) {
      _message('Pilih minimal 1 karyawan untuk dijadwalkan.');
      return;
    }
    if (_editingId != null && _employeeId == null) {
      _message('Pilih karyawan terlebih dahulu.');
      return;
    }
    final start = _timeString(_start);
    final end = _timeString(_end);
    if (start.compareTo(end) >= 0) {
      _message('Jam selesai harus setelah jam mulai.');
      return;
    }
    setState(() => _saving = true);
    try {
      if (_editingId == null) {
        await ApiService.simpanJadwalKerjaUntukBanyakKaryawan(
          userIds: _selectedEmployeeIds.toList(),
          locationId: _locationId!,
          tanggal: _tanggalApi,
          jamMulai: start,
          jamSelesai: end,
        );
        final count = _selectedEmployeeIds.length;
        _resetForm();
        await _muat();
        if (mounted) _message('Jadwal kerja berhasil disimpan untuk $count karyawan.');
      } else {
        await ApiService.simpanJadwalKerja(
          id: _editingId,
          userId: _employeeId!,
          locationId: _locationId!,
          tanggal: _tanggalApi,
          jamMulai: start,
          jamSelesai: end,
        );
        _resetForm();
        await _muat();
        if (mounted) _message('Jadwal kerja berhasil diperbarui.');
      }
    } catch (e) {
      if (mounted) _message('Gagal menyimpan jadwal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hapus(Map<String, dynamic> slot) async {
    final attendance = slot['absensi'];
    if (attendance is List && attendance.isNotEmpty) {
      _message('Slot tidak bisa dihapus setelah absensi tercatat.');
      return;
    }
    final user = slot['User'] is Map ? slot['User']['nama'] : 'karyawan';
    final location =
        slot['Location'] is Map ? slot['Location']['nama'] : 'lokasi';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jadwal kerja?'),
        content: Text('Jadwal $user di $location akan dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ApiService.hapusJadwalKerja(int.parse(slot['id'].toString()));
      await _muat();
      if (mounted) _message('Jadwal kerja berhasil dihapus.');
    } catch (e) {
      if (mounted) _message('Gagal menghapus jadwal: $e');
    }
  }

  Future<void> _simpanLokasi([Map<String, dynamic>? location]) async {
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _LokasiDialog(location: location),
    );
    if (values == null) return;
    try {
      await ApiService.simpanLokasi(
        values['nama'] as String,
        id: location == null ? null : int.parse(location['id'].toString()),
        latitude: values['latitude'] as double,
        longitude: values['longitude'] as double,
        radiusMeters: values['radius_meters'] as int,
      );
      await _muat();
      if (mounted) _message('Lokasi GPS berhasil disimpan.');
    } catch (e) {
      if (mounted) _message('Gagal menyimpan lokasi: $e');
    }
  }

  Future<void> _kelolaLokasi() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kelola lokasi kerja'),
          content: SizedBox(
            width: 430,
            height: 360,
            child: ListView.separated(
              itemCount: _locations.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final location = _locations[index];
                final id = int.parse(location['id'].toString());
                final name = location['nama'].toString();
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  subtitle: Text(
                    location['latitude'] != null &&
                            location['longitude'] != null
                        ? 'GPS aktif • batas absen ${_formatRadiusKm(location['radius_meters'])}'
                        : 'GPS belum diatur',
                  ),
                  trailing: Wrap(
                    children: [
                      IconButton(
                        tooltip: 'Atur GPS $name',
                        icon: const Icon(Icons.edit_location_alt_outlined),
                        onPressed: () async {
                          await _simpanLokasi(location);
                          if (mounted) setDialogState(() {});
                        },
                      ),
                      IconButton(
                        tooltip: 'Hapus $name',
                        icon:
                            const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () async {
                          try {
                            await ApiService.hapusLokasi(id);
                            await _muat();
                            if (mounted) setDialogState(() {});
                          } catch (e) {
                            if (mounted) _message('Gagal menghapus lokasi: $e');
                          }
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await _simpanLokasi();
                if (mounted) setDialogState(() {});
              },
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Tambah lokasi'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Tutup'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTanggal() {
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
    return '${days[_tanggal.weekday - 1]}, ${_tanggal.day} ${months[_tanggal.month - 1]} ${_tanggal.year}';
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  List<Widget> _buildLocationGroups() {
    final Map<int, List<Map<String, dynamic>>> grouped = {};
    for (final slot in _slots) {
      final locationId = int.tryParse(slot['location_id']?.toString() ?? '');
      final key = locationId ?? -1;
      grouped.putIfAbsent(key, () => []).add(slot);
    }

    final orderedIds = <int>{
      ..._locations.map((location) => int.tryParse(location['id']?.toString() ?? '') ?? -1),
      ...grouped.keys,
    }.toList();

    orderedIds.sort((a, b) {
      if (a == -1) return 1;
      if (b == -1) return -1;
      return a.compareTo(b);
    });

    final locationWidgets = <Widget>[];
    for (final locationId in orderedIds) {
      final location = _locations.firstWhere(
        (item) => int.tryParse(item['id']?.toString() ?? '') == locationId,
        orElse: () => {'id': locationId, 'nama': 'Lokasi tidak diketahui'},
      );

      final slotList = grouped[locationId] ?? const <Map<String, dynamic>>[];
      final title = location['nama']?.toString() ?? 'Lokasi tidak diketahui';

      locationWidgets.add(
        Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, color: Color(0xFF4F5BA8)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE9EAFE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${slotList.length} karyawan',
                        style: const TextStyle(
                          color: Color(0xFF4338CA),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (slotList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 2),
                    child: Text(
                      'Belum ada karyawan yang dijadwalkan di lokasi ini.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                else
                  ...slotList.map(_buildSlot).toList(),
              ],
            ),
          ),
        ),
      );
    }

    return locationWidgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muat,
          child: ListView(
            padding: const EdgeInsets.all(28),
            children: [
              const Text(
                'Jadwal Karyawan',
                style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Atur penugasan lokasi dan jam kerja karyawan per tanggal. Satu karyawan dapat memiliki beberapa slot yang tidak saling bertabrakan.',
                style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pilihTanggal,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_formatTanggal()),
                  ),
                  OutlinedButton.icon(
                    onPressed: _kelolaLokasi,
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Kelola lokasi'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildForm(),
              const SizedBox(height: 20),
              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _buildError()
              else if (_slots.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(28),
                  child: Center(
                      child: Text('Belum ada jadwal untuk tanggal ini.')),
                )
              else
                ..._buildLocationGroups(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() => Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editingId == null ? 'Tambah slot kerja' : 'Ubah slot kerja',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              const SizedBox(height: 14),
              if (_editingId == null) ...[
                Row(
                  children: [
                    Text(
                      'Pilih Karyawan (${_selectedEmployeeIds.length} dipilih)',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedEmployeeIds.clear();
                          for (final e in _employees) {
                            final id = int.tryParse(e['id'].toString());
                            if (id != null) _selectedEmployeeIds.add(id);
                          }
                        });
                      },
                      icon: const Icon(Icons.select_all_rounded, size: 16),
                      label: const Text('Pilih Semua'),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedEmployeeIds.isNotEmpty)
                      TextButton.icon(
                        onPressed: () {
                          setState(() => _selectedEmployeeIds.clear());
                        },
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text('Batal Semua'),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: SingleChildScrollView(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _employees.map((employee) {
                        final id = int.tryParse(employee['id'].toString());
                        if (id == null) return const SizedBox.shrink();
                        final isSelected = _selectedEmployeeIds.contains(id);
                        final nama = (employee['nama'] ?? 'Karyawan').toString();
                        return FilterChip(
                          selected: isSelected,
                          showCheckmark: true,
                          label: Text(nama),
                          selectedColor: const Color(0xFFE0E7FF),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF4338CA) : const Color(0xFF374151),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedEmployeeIds.add(id);
                              } else {
                                _selectedEmployeeIds.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  if (_editingId != null)
                    SizedBox(
                      width: 290,
                      child: DropdownButtonFormField<int>(
                        initialValue: _employeeId,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Karyawan',
                          border: OutlineInputBorder(),
                        ),
                        items: _employees
                            .map((employee) => DropdownMenuItem<int>(
                                  value: int.parse(employee['id'].toString()),
                                  child: Text(employee['nama'].toString()),
                                ))
                            .toList(),
                        onChanged: (id) => setState(() => _employeeId = id),
                      ),
                    ),
                  SizedBox(
                    width: 290,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: _locationId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Lokasi kerja',
                            border: OutlineInputBorder(),
                          ),
                          items: _locations
                              .map((location) => DropdownMenuItem<int>(
                                    value: int.parse(location['id'].toString()),
                                    child: Text(location['nama'].toString()),
                                  ))
                              .toList(),
                          onChanged: (id) => setState(() => _locationId = id),
                        ),
                        if (_selectedLocation != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Batas absen: ${_formatRadiusKm(_selectedLocation!['radius_meters'])} dari titik GPS lokasi. Atur melalui Kelola lokasi.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickTime(true),
                    icon: const Icon(Icons.login),
                    label: Text('Mulai ${_timeString(_start)}'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _pickTime(false),
                    icon: const Icon(Icons.logout),
                    label: Text('Selesai ${_timeString(_end)}'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                children: [
                  FilledButton.icon(
                    onPressed: _saving ? null : _simpan,
                    icon: const Icon(Icons.save_outlined),
                    label: Text(_saving
                        ? 'Menyimpan...'
                        : (_editingId == null
                            ? 'Simpan jadwal (${_selectedEmployeeIds.length} karyawan)'
                            : 'Perbarui jadwal')),
                  ),
                  if (_editingId != null)
                    TextButton(
                      onPressed: () => setState(_resetForm),
                      child: const Text('Batal ubah'),
                    ),
                ],
              ),
            ],
          ),
        ),
      );

  Widget _buildSlot(Map<String, dynamic> slot) {
    final user = slot['User'] is Map ? slot['User'] as Map : const {};
    final location =
        slot['Location'] is Map ? slot['Location'] as Map : const {};
    final attendance = slot['absensi'];
    final locked = attendance is List && attendance.isNotEmpty;
    final start = slot['jam_mulai']?.toString() ?? '--:--';
    final end = slot['jam_selesai']?.toString() ?? '--:--';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE9EAFE),
          child: Icon(Icons.schedule_rounded, color: Color(0xFF4F5BA8)),
        ),
        title: Text(
          user['nama']?.toString() ?? 'Karyawan',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          '${location['nama'] ?? 'Lokasi'} • ${start.substring(0, 5)}–${end.substring(0, 5)}'
          '${locked ? ' • Absensi tercatat' : ''}',
        ),
        trailing: Wrap(
          children: [
            IconButton(
              tooltip: locked ? 'Absensi sudah tercatat' : 'Ubah',
              onPressed: locked ? null : () => _edit(slot),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: locked ? 'Absensi sudah tercatat' : 'Hapus',
              onPressed: locked ? null : () => _hapus(slot),
              icon: const Icon(Icons.delete_outline, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() => Column(
        children: [
          const Text('Gagal memuat data jadwal, karyawan, atau lokasi.'),
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _muat, child: const Text('Coba lagi')),
        ],
      );
}

class _LokasiDialog extends StatefulWidget {
  final Map<String, dynamic>? location;

  const _LokasiDialog({this.location});

  @override
  State<_LokasiDialog> createState() => _LokasiDialogState();
}

class _LokasiDialogState extends State<_LokasiDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _latitudeController;
  late final TextEditingController _longitudeController;
  late final TextEditingController _radiusController;
  final MapController _mapController = MapController();
  LatLng? _selectedPoint;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    final location = widget.location;
    _nameController =
        TextEditingController(text: location?['nama']?.toString());
    _latitudeController =
        TextEditingController(text: location?['latitude']?.toString() ?? '');
    _longitudeController =
        TextEditingController(text: location?['longitude']?.toString() ?? '');
    final radiusMeters = double.tryParse(
          location?['radius_meters']?.toString() ?? '',
        ) ??
        250;
    _radiusController = TextEditingController(
      text: (radiusMeters / 1000)
          .toStringAsFixed(3)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), ''),
    );
    _selectedPoint = _parsePoint();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  String? _validateCoordinate(String? value, double min, double max) {
    final coordinate = double.tryParse(value?.trim() ?? '');
    if (coordinate == null ||
        !coordinate.isFinite ||
        coordinate < min ||
        coordinate > max) {
      return 'Koordinat tidak valid';
    }
    return null;
  }

  LatLng? _parsePoint() {
    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      return null;
    }
    return LatLng(latitude, longitude);
  }

  void _syncPointFromFields() {
    final point = _parsePoint();
    if (point == null) return;
    setState(() => _selectedPoint = point);
    if (_mapReady) _mapController.move(point, _mapController.camera.zoom);
  }

  void _setPoint(LatLng point) {
    _latitudeController.text = point.latitude.toStringAsFixed(7);
    _longitudeController.text = point.longitude.toStringAsFixed(7);
    setState(() => _selectedPoint = point);
  }

  void _syncPointFromMapTap(TapPosition _, LatLng point) => _setPoint(point);

  double? get _radiusMeters {
    final km = double.tryParse(
      _radiusController.text.trim().replaceAll(',', '.'),
    );
    if (km == null || !km.isFinite || km <= 0 || km > 10) return null;
    final meters = (km * 1000).round();
    return meters > 0 ? meters.toDouble() : null;
  }

  String? _validateRadiusKm(String? value) {
    final km = double.tryParse((value ?? '').trim().replaceAll(',', '.'));
    if (km == null || !km.isFinite || km <= 0 || km > 10) {
      return 'Radius harus lebih dari 0 sampai 10 km';
    }
    if (km < 0.001) return 'Radius minimal 0,001 km';
    return null;
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title:
            Text(widget.location == null ? 'Tambah lokasi' : 'Atur GPS lokasi'),
        content: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    decoration: const InputDecoration(labelText: 'Nama lokasi'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama lokasi wajib diisi'
                        : null,
                  ),
                  TextFormField(
                    controller: _latitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Latitude'),
                    validator: (value) => _validateCoordinate(value, -90, 90),
                    onChanged: (_) => _syncPointFromFields(),
                  ),
                  TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    validator: (value) => _validateCoordinate(value, -180, 180),
                    onChanged: (_) => _syncPointFromFields(),
                  ),
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Titik lokasi kerja',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 260,
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter:
                              _selectedPoint ?? const LatLng(-2.5, 118),
                          initialZoom: _selectedPoint == null ? 4 : 15,
                          minZoom: 3,
                          maxZoom: 19,
                          onMapReady: () => _mapReady = true,
                          onTap: _syncPointFromMapTap,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'admin_web',
                          ),
                          if (_selectedPoint != null && _radiusMeters != null)
                            CircleLayer(
                              circles: [
                                CircleMarker(
                                  point: _selectedPoint!,
                                  radius: _radiusMeters!,
                                  useRadiusInMeter: true,
                                  color: const Color(0x334F46E5),
                                  borderColor: const Color(0xFF4F46E5),
                                  borderStrokeWidth: 2,
                                ),
                              ],
                            ),
                          if (_selectedPoint != null)
                            DragMarkers(
                              markers: [
                                DragMarker(
                                  point: _selectedPoint!,
                                  size: const Size(46, 46),
                                  alignment: Alignment.bottomCenter,
                                  builder: (_, __, isDragging) => Icon(
                                    Icons.location_on,
                                    size: 42,
                                    color: isDragging
                                        ? const Color(0xFFDC2626)
                                        : const Color(0xFF4F46E5),
                                  ),
                                  onDragEnd: (_, point) => _setPoint(point),
                                ),
                              ],
                            ),
                          RichAttributionWidget(
                            alignment: AttributionAlignment.bottomRight,
                            attributions: [
                              TextSourceAttribution(
                                '© OpenStreetMap contributors',
                                onTap: () {
                                  launchUrl(
                                    Uri.parse(
                                      'https://www.openstreetmap.org/copyright',
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Klik peta atau tarik pin untuk menentukan titik GPS.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _radiusController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Batas radius absen (km)',
                      hintText: 'Contoh: 0,25',
                    ),
                    onChanged: (_) => setState(() {}),
                    validator: _validateRadiusKm,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Absen hanya diterima dalam radius ini dari koordinat titik lokasi kerja.',
                    style: TextStyle(fontSize: 12, color: Colors.black54),
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
            onPressed: () {
              if (!_formKey.currentState!.validate()) return;
              Navigator.pop(context, <String, dynamic>{
                'nama': _nameController.text.trim(),
                'latitude': double.parse(_latitudeController.text.trim()),
                'longitude': double.parse(_longitudeController.text.trim()),
                'radius_meters': _radiusMeters!.toInt(),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      );
}
