import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';

class JadwalKaryawanScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onBack;

  const JadwalKaryawanScreen({
    super.key,
    required this.onOpenDrawer,
    required this.onBack,
  });

  @override
  State<JadwalKaryawanScreen> createState() => _JadwalKaryawanScreenState();
}

class _JadwalKaryawanScreenState extends State<JadwalKaryawanScreen> {
  DateTime _tanggal = DateTime.now();
  List<Map<String, dynamic>> _slots = [];
  List<Map<String, dynamic>> _employees = [];
  List<Map<String, dynamic>> _locations = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  String get _tanggalApi => DateFormat('yyyy-MM-dd').format(_tanggal);

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
    final selected = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal kerja',
    );
    if (selected == null) return;
    setState(() => _tanggal = selected);
    await _muat();
  }

  Future<void> _tambahSlot() async => _editSlot();

  Future<void> _editSlot([Map<String, dynamic>? slot]) async {
    if (_employees.isEmpty || _locations.isEmpty) {
      _beriPesan(_employees.isEmpty
          ? 'Belum ada karyawan aktif yang dapat dijadwalkan.'
          : 'Tambahkan lokasi kerja terlebih dahulu.');
      return;
    }
    final values = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _JadwalDialog(
        employees: _employees,
        locations: _locations,
        tanggal: _tanggalApi,
        slot: slot,
      ),
    );
    if (values == null) return;
    setState(() => _saving = true);
    try {
      final userIds = List<int>.from(values['user_ids'] as List);
      if (slot == null) {
        await ApiService.simpanJadwalKerjaUntukBanyakKaryawan(
          userIds: userIds,
          locationId: values['location_id'] as int,
          tanggal: values['tanggal'] as String,
          jamMulai: values['jam_mulai'] as String,
          jamSelesai: values['jam_selesai'] as String,
        );
      } else {
        await ApiService.simpanJadwalKerja(
          id: int.parse(slot['id'].toString()),
          userId: userIds.single,
          locationId: values['location_id'] as int,
          tanggal: values['tanggal'] as String,
          jamMulai: values['jam_mulai'] as String,
          jamSelesai: values['jam_selesai'] as String,
        );
      }
      await _muat();
      if (mounted) {
        _beriPesan(slot == null
            ? 'Jadwal berhasil disimpan untuk ${userIds.length} karyawan.'
            : 'Jadwal kerja berhasil diperbarui.');
      }
    } catch (e) {
      if (mounted) _beriPesan('Gagal menyimpan jadwal: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _hapusSlot(Map<String, dynamic> slot) async {
    final employee = slot['User'] is Map ? slot['User']['nama'] : 'karyawan';
    final location =
        slot['Location'] is Map ? slot['Location']['nama'] : 'lokasi';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus jadwal kerja?'),
        content: Text('Jadwal $employee di $location akan dihapus.'),
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
    if (confirm != true) return;
    try {
      await ApiService.hapusJadwalKerja(int.parse(slot['id'].toString()));
      await _muat();
      if (mounted) _beriPesan('Jadwal kerja berhasil dihapus.');
    } catch (e) {
      if (mounted) _beriPesan('Gagal menghapus jadwal: $e');
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
      if (mounted) _beriPesan('Lokasi GPS berhasil disimpan.');
    } catch (e) {
      if (mounted) _beriPesan('Gagal menyimpan lokasi: $e');
    }
  }

  Future<void> _kelolaLokasi() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kelola lokasi kerja'),
          content: SizedBox(
            width: 420,
            height: 360,
            child: _locations.isEmpty
                ? const Center(child: Text('Belum ada lokasi kerja.'))
                : ListView.separated(
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
                              ? 'GPS aktif • radius ${location['radius_meters']} m'
                              : 'GPS belum diatur',
                        ),
                        trailing: Wrap(
                          children: [
                            IconButton(
                              tooltip: 'Atur GPS $name',
                              icon:
                                  const Icon(Icons.edit_location_alt_outlined),
                              onPressed: () async {
                                await _simpanLokasi(location);
                                if (mounted) setDialogState(() {});
                              },
                            ),
                            IconButton(
                              tooltip: 'Hapus $name',
                              icon: const Icon(Icons.delete_outline,
                                  color: Color(0xFFDC2626)),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Hapus lokasi?'),
                                    content: Text(
                                      'Pastikan tidak ada karyawan atau slot jadwal yang masih memakai "$name".',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Batal'),
                                      ),
                                      FilledButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Hapus'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm != true) return;
                                try {
                                  await ApiService.hapusLokasi(id);
                                  await _muat();
                                  if (mounted) {
                                    setDialogState(() {});
                                    _beriPesan(
                                        'Lokasi "$name" berhasil dihapus.');
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _beriPesan('Gagal menghapus lokasi: $e');
                                  }
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

  void _beriPesan(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _muat,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Buka menu',
                    onPressed: widget.onOpenDrawer,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali ke halaman sebelumnya',
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Jadwal Karyawan',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Atur lokasi dan jam kerja karyawan.',
                  style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _kelolaLokasi,
                icon: const Icon(Icons.location_on_outlined),
                label: const Text('Kelola lokasi'),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Tanggal kerja'),
                  subtitle: Text(_formatTanggal(_tanggal)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pilihTanggal,
                ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _buildError()
              else if (_slots.isEmpty)
                _buildEmpty()
              else ...[
                for (final slot in _slots) ...[
                  _buildSlot(slot),
                  const SizedBox(height: 10),
                ],
              ],
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _tambahSlot,
                icon: _saving
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.add),
                label: const Text('Tambah slot kerja'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSlot(Map<String, dynamic> slot) {
    final user = slot['User'] is Map ? slot['User'] as Map : const {};
    final location =
        slot['Location'] is Map ? slot['Location'] as Map : const {};
    final start = slot['jam_mulai']?.toString() ?? '--:--';
    final end = slot['jam_selesai']?.toString() ?? '--:--';
    final attendance = slot['absensi'];
    final hasAttendance = attendance is List && attendance.isNotEmpty;
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE9EAFE),
          child: Icon(Icons.schedule_rounded, color: Color(0xFF4F5BA8)),
        ),
        title: Text(
          user['nama']?.toString() ?? 'Karyawan',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${location['nama'] ?? 'Lokasi'}\n${start.substring(0, 5)}–${end.substring(0, 5)}'
            '${hasAttendance ? '\nAbsensi sudah tercatat' : ''}',
            style: const TextStyle(height: 1.45),
          ),
        ),
        isThreeLine: true,
        trailing: Wrap(
          spacing: 0,
          children: [
            IconButton(
              tooltip: hasAttendance
                  ? 'Tidak dapat diubah setelah absensi'
                  : 'Ubah slot',
              onPressed: hasAttendance ? null : () => _editSlot(slot),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: hasAttendance
                  ? 'Tidak dapat dihapus setelah absensi'
                  : 'Hapus slot',
              onPressed: hasAttendance ? null : () => _hapusSlot(slot),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Column(
          children: [
            Icon(Icons.event_available_outlined,
                size: 42, color: Color(0xFF9CA3AF)),
            SizedBox(height: 8),
            Text('Belum ada jadwal untuk tanggal ini.'),
          ],
        ),
      );

  Widget _buildError() => Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 40, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 8),
          const Text('Gagal memuat data jadwal, karyawan, atau lokasi.'),
          Text(_error!, textAlign: TextAlign.center),
          TextButton(onPressed: _muat, child: const Text('Coba lagi')),
        ],
      );
}

class _JadwalDialog extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final List<Map<String, dynamic>> locations;
  final String tanggal;
  final Map<String, dynamic>? slot;

  const _JadwalDialog({
    required this.employees,
    required this.locations,
    required this.tanggal,
    this.slot,
  });

  @override
  State<_JadwalDialog> createState() => _JadwalDialogState();
}

class _JadwalDialogState extends State<_JadwalDialog> {
  int? _userId;
  final Set<int> _selectedUserIds = {};
  int? _locationId;
  late TimeOfDay _start;
  late TimeOfDay _end;

  @override
  void initState() {
    super.initState();
    final slot = widget.slot;
    _userId = int.tryParse(
        (slot?['user_id'] ?? widget.employees.first['id']).toString());
    if (slot == null) {
      _selectedUserIds.clear();
    } else if (_userId != null) {
      _selectedUserIds.add(_userId!);
    }
    _locationId = int.tryParse(
        (slot?['location_id'] ?? widget.locations.first['id']).toString());
    _start = _parseTime(slot?['jam_mulai']?.toString()) ??
        const TimeOfDay(hour: 8, minute: 0);
    _end = _parseTime(slot?['jam_selesai']?.toString()) ??
        const TimeOfDay(hour: 17, minute: 0);
  }

  TimeOfDay? _parseTime(String? raw) {
    if (raw == null || raw.length < 5) return null;
    final parts = raw.substring(0, 5).split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool start) async {
    final value = await showTimePicker(
      context: context,
      initialTime: start ? _start : _end,
    );
    if (value == null) return;
    setState(() {
      if (start) {
        _start = value;
      } else {
        _end = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.slot == null ? 'Tambah slot kerja' : 'Ubah slot kerja'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.slot == null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Pilih karyawan (${_selectedUserIds.length} dipilih)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 210),
                  child: ListView(
                    shrinkWrap: true,
                    children: widget.employees.map((employee) {
                      final id = int.parse(employee['id'].toString());
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: _selectedUserIds.contains(id),
                        title: Text(employee['nama'].toString()),
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (selected) => setState(() {
                          if (selected == true) {
                            _selectedUserIds.add(id);
                          } else {
                            _selectedUserIds.remove(id);
                          }
                        }),
                      );
                    }).toList(),
                  ),
                ),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Setiap karyawan terpilih mendapat jadwal dan notifikasi di akunnya.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
                ),
              ] else
                DropdownButtonFormField<int>(
                  initialValue: _userId,
                  decoration: const InputDecoration(labelText: 'Karyawan'),
                  items: widget.employees
                      .map((item) => DropdownMenuItem<int>(
                            value: int.parse(item['id'].toString()),
                            child: Text(item['nama'].toString()),
                          ))
                      .toList(),
                  onChanged: (value) => setState(() => _userId = value),
                ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                initialValue: _locationId,
                decoration: const InputDecoration(labelText: 'Lokasi kerja'),
                items: widget.locations
                    .map((item) => DropdownMenuItem<int>(
                          value: int.parse(item['id'].toString()),
                          child: Text(item['nama'].toString()),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _locationId = value),
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jam mulai'),
                trailing: TextButton(
                  onPressed: () => _pickTime(true),
                  child: Text(_formatTime(_start)),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Jam selesai'),
                trailing: TextButton(
                  onPressed: () => _pickTime(false),
                  child: Text(_formatTime(_end)),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: (widget.slot == null
                      ? _selectedUserIds.isEmpty
                      : _userId == null) ||
                  _locationId == null
              ? null
              : () {
                  final start = _formatTime(_start);
                  final end = _formatTime(_end);
                  if (start.compareTo(end) >= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Jam selesai harus setelah jam mulai.'),
                      ),
                    );
                    return;
                  }
                  Navigator.pop(context, {
                    'user_ids': widget.slot == null
                        ? _selectedUserIds.toList()
                        : [_userId!],
                    'location_id': _locationId,
                    'tanggal': widget.tanggal,
                    'jam_mulai': start,
                    'jam_selesai': end,
                  });
                },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
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
    _radiusController = TextEditingController(
      text: location?['radius_meters']?.toString() ?? '250',
    );
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
                    textCapitalization: TextCapitalization.words,
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
                  ),
                  TextFormField(
                    controller: _longitudeController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(labelText: 'Longitude'),
                    validator: (value) => _validateCoordinate(value, -180, 180),
                  ),
                  TextFormField(
                    controller: _radiusController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Radius (meter)'),
                    validator: (value) {
                      final radius = int.tryParse(value?.trim() ?? '');
                      return radius == null || radius < 1 || radius > 10000
                          ? 'Radius harus 1–10000 meter'
                          : null;
                    },
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Gunakan koordinat titik lokasi kerja, bukan lokasi admin.',
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
                'radius_meters': int.parse(_radiusController.text.trim()),
              });
            },
            child: const Text('Simpan'),
          ),
        ],
      );
}
