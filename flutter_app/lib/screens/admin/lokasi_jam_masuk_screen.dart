import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/api_service.dart';

class LokasiJamMasukScreen extends StatefulWidget {
  final VoidCallback onOpenDrawer;
  final VoidCallback onBack;

  const LokasiJamMasukScreen({
    super.key,
    required this.onOpenDrawer,
    required this.onBack,
  });

  @override
  State<LokasiJamMasukScreen> createState() => _LokasiJamMasukScreenState();
}

String _formatTanggal(DateTime tanggal) {
  const hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
  const bulan = [
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
  return '${hari[tanggal.weekday - 1]}, ${tanggal.day} ${bulan[tanggal.month - 1]} ${tanggal.year}';
}

class _LokasiJamMasukScreenState extends State<LokasiJamMasukScreen> {
  static const List<String> _namaLokasiTersedia = [
    'Dhoho I',
    'Dhoho II',
    'Lumajang I',
    'Lumajang II',
    'Mumbul I',
    'Mumbul II',
    'Kalitelepak',
    'Banyuwangi',
    'CIMA I',
    'CIMA II',
    'Bungamayang',
  ];

  DateTime _tanggal = DateTime.now();
  List<Map<String, dynamic>> _lokasi = [];
  int? _lokasiTerpilihId;
  String? _jamMasuk;
  bool _memuat = true;
  bool _memuatJadwal = false;
  bool _menyimpanJadwal = false;
  String? _error;

  String get _tanggalApi => DateFormat('yyyy-MM-dd').format(_tanggal);

  @override
  void initState() {
    super.initState();
    _muat();
  }

  Future<void> _muat() async {
    setState(() {
      _memuat = true;
      _error = null;
    });
    try {
      final results = await ApiService.daftarLokasi();
      final lokasi = results.map((e) => Map<String, dynamic>.from(e)).toList()
        ..sort((a, b) {
          final aIndex = _namaLokasiTersedia.indexOf(a['nama'].toString());
          final bIndex = _namaLokasiTersedia.indexOf(b['nama'].toString());
          if (aIndex >= 0 && bIndex >= 0) return aIndex.compareTo(bIndex);
          if (aIndex >= 0) return -1;
          if (bIndex >= 0) return 1;
          return a['nama']
              .toString()
              .toLowerCase()
              .compareTo(b['nama'].toString().toLowerCase());
        });
      if (!mounted) return;
      setState(() {
        _lokasi = lokasi;
        if (!_lokasi.any((item) =>
            int.tryParse(item['id'].toString()) == _lokasiTerpilihId)) {
          _lokasiTerpilihId = null;
          _jamMasuk = null;
        }
        _memuat = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memuat = false;
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
      helpText: 'Pilih tanggal jadwal',
    );
    if (selected == null) return;
    setState(() => _tanggal = selected);
    await _muatJadwalLokasiTerpilih();
  }

  Future<void> _kelolaLokasi() async {
    var lokasiDialog = List<Map<String, dynamic>>.of(_lokasi);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Kelola Lokasi'),
          content: SizedBox(
            width: 420,
            height: 360,
            child: lokasiDialog.isEmpty
                ? const Center(child: Text('Belum ada lokasi.'))
                : ListView.separated(
                    itemCount: lokasiDialog.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final lokasi = lokasiDialog[index];
                      final id = int.tryParse(lokasi['id'].toString());
                      final nama = lokasi['nama'].toString();
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(nama),
                        trailing: IconButton(
                          tooltip: 'Hapus $nama',
                          onPressed: id == null
                              ? null
                              : () async {
                                  final berhasil = await _hapusLokasi(id, nama);
                                  if (berhasil) {
                                    setDialogState(() {
                                      lokasiDialog =
                                          List<Map<String, dynamic>>.of(
                                              _lokasi);
                                    });
                                  }
                                },
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await _tambahLokasi();
                if (mounted) {
                  setDialogState(() {
                    lokasiDialog = List<Map<String, dynamic>>.of(_lokasi);
                  });
                }
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

  Future<void> _tambahLokasi() async {
    final nama = await showDialog<String>(
      context: context,
      builder: (_) => const _TambahLokasiDialog(),
    );
    if (nama == null) return;
    final namaBersih = nama.trim();
    if (namaBersih.isEmpty) {
      _beriPesan('Nama lokasi wajib diisi.');
      return;
    }

    try {
      final response = await ApiService.simpanLokasi(namaBersih);
      final data = response['data'];
      await _muat();
      if (!mounted) return;
      final lokasiId = data is Map ? int.tryParse(data['id'].toString()) : null;
      if (lokasiId != null &&
          _lokasi
              .any((item) => int.tryParse(item['id'].toString()) == lokasiId)) {
        await _pilihLokasi(lokasiId);
      }
      _beriPesan('Lokasi "$namaBersih" berhasil ditambahkan.');
    } catch (e) {
      _beriPesan('Gagal menambahkan lokasi: $e');
    }
  }

  Future<bool> _hapusLokasi(int id, String nama) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Lokasi'),
        content: Text(
          'Yakin ingin menghapus lokasi "$nama"? Jadwal masuk lokasi ini juga akan dihapus.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return false;

    try {
      await ApiService.hapusLokasi(id);
      if (!mounted) return false;
      setState(() {
        _lokasi.removeWhere(
          (lokasi) => int.tryParse(lokasi['id'].toString()) == id,
        );
        if (_lokasiTerpilihId == id) {
          _lokasiTerpilihId = null;
          _jamMasuk = null;
          _memuatJadwal = false;
        }
        _error = null;
      });
      _beriPesan('Lokasi "$nama" berhasil dihapus.');
      return true;
    } catch (e) {
      _beriPesan('Gagal menghapus lokasi "$nama": $e');
      return false;
    }
  }

  Future<void> _pilihLokasi(int? id) async {
    setState(() {
      _lokasiTerpilihId = id;
      _jamMasuk = null;
    });
    await _muatJadwalLokasiTerpilih();
  }

  Future<void> _muatJadwalLokasiTerpilih() async {
    final id = _lokasiTerpilihId;
    if (id == null) return;
    final tanggal = _tanggalApi;
    setState(() {
      _memuatJadwal = true;
      _error = null;
    });
    try {
      final jadwal = await ApiService.jadwalLokasi(id, tanggal);
      if (!mounted || id != _lokasiTerpilihId || tanggal != _tanggalApi) return;
      setState(() {
        final rawJam = jadwal['jam_masuk']?.toString();
        _jamMasuk =
            rawJam == null || rawJam.isEmpty ? null : rawJam.substring(0, 5);
        _memuatJadwal = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (id != _lokasiTerpilihId || tanggal != _tanggalApi) return;
      setState(() {
        _memuatJadwal = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _aturJamMasuk() async {
    final id = _lokasiTerpilihId;
    if (id == null) return;
    final current = _jamMasuk ?? '08:00';
    final parts = current.split(':');
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      ),
      helpText: 'Jam masuk untuk ${_namaLokasiTerpilih}',
    );
    if (selected == null) return;
    final value =
        '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
    final tanggal = _tanggalApi;
    final namaLokasi = _namaLokasiTerpilih;
    setState(() => _menyimpanJadwal = true);
    try {
      await ApiService.simpanJadwalLokasi(
        id: id,
        tanggal: tanggal,
        jamMasuk: value,
      );
      if (!mounted) return;
      if (id == _lokasiTerpilihId && tanggal == _tanggalApi) {
        setState(() => _jamMasuk = value);
      }
      _beriPesan(
          'Jam masuk $namaLokasi disimpan untuk ${_formatTanggal(DateTime.parse(tanggal))}.');
    } catch (e) {
      _beriPesan(e.toString());
    } finally {
      if (mounted) setState(() => _menyimpanJadwal = false);
    }
  }

  String get _namaLokasiTerpilih => _lokasi
      .where((lokasi) =>
          int.tryParse(lokasi['id'].toString()) == _lokasiTerpilihId)
      .map((lokasi) => lokasi['nama'].toString())
      .firstWhere((_) => true, orElse: () => '');

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
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
            children: [
              Row(
                children: [
                  IconButton(
                    tooltip: 'Kembali ke dashboard',
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  IconButton(
                    tooltip: 'Buka menu',
                    onPressed: widget.onOpenDrawer,
                    icon: const Icon(Icons.menu_rounded),
                  ),
                  const Expanded(
                    child: Text(
                      'Lokasi & Jam Masuk',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Atur batas waktu masuk untuk setiap lokasi pada tanggal yang dipilih. '
                'Karyawan mengikuti jadwal sesuai lokasi penugasannya.',
                style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _kelolaLokasi,
                  icon: const Icon(Icons.location_on_outlined),
                  label: const Text('Kelola lokasi'),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Tanggal jadwal'),
                  subtitle: Text(_formatTanggal(_tanggal)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pilihTanggal,
                ),
              ),
              const SizedBox(height: 12),
              if (_memuat)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null && _lokasi.isEmpty)
                _buildError()
              else if (_lokasi.isEmpty)
                _buildKosong()
              else ...[
                DropdownButtonFormField<int?>(
                  initialValue: _lokasiTerpilihId,
                  decoration: const InputDecoration(
                    labelText: 'Lokasi kerja',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  hint: const Text('Pilih lokasi'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Pilih lokasi'),
                    ),
                    ..._lokasi.map((lokasi) {
                      final id = int.parse(lokasi['id'].toString());
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(lokasi['nama'].toString()),
                      );
                    }),
                  ],
                  onChanged: _memuat ? null : _pilihLokasi,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFDC2626)),
                  ),
                  TextButton(
                    onPressed: _muatJadwalLokasiTerpilih,
                    child: const Text('Coba lagi'),
                  ),
                ],
                if (_lokasiTerpilihId != null) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Atur Jam Masuk',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$_namaLokasiTerpilih • ${_formatTanggal(_tanggal)}',
                            style: const TextStyle(color: Color(0xFF6B7280)),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF4F5BA8),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _memuatJadwal
                                      ? 'Memuat jam masuk...'
                                      : 'Batas jam masuk: ${_jamMasuk ?? '08:00 (default)'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              FilledButton.icon(
                                onPressed: _memuatJadwal || _menyimpanJadwal
                                    ? null
                                    : _aturJamMasuk,
                                icon: _menyimpanJadwal
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.edit_calendar_outlined),
                                label: Text(
                                  _menyimpanJadwal ? 'Menyimpan' : 'Atur',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() => Column(
        children: [
          const Icon(Icons.cloud_off_outlined,
              size: 40, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 8),
          const Text(
            'Gagal terhubung ke server untuk memuat daftar lokasi.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(_error!, textAlign: TextAlign.center),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              TextButton(onPressed: _muat, child: const Text('Coba lagi')),
            ],
          ),
        ],
      );

  Widget _buildKosong() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Icon(Icons.location_off_outlined,
                size: 42, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 8),
            const Text('Daftar lokasi belum tersedia.'),
          ],
        ),
      );
}

class _TambahLokasiDialog extends StatefulWidget {
  const _TambahLokasiDialog();

  @override
  State<_TambahLokasiDialog> createState() => _TambahLokasiDialogState();
}

class _TambahLokasiDialogState extends State<_TambahLokasiDialog> {
  late final TextEditingController _namaController;

  @override
  void initState() {
    super.initState();
    _namaController = TextEditingController();
  }

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Tambah Lokasi'),
      content: TextField(
        controller: _namaController,
        autofocus: true,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(
          labelText: 'Nama lokasi',
          hintText: 'Contoh: Kantor Surabaya',
        ),
        onSubmitted: (value) => Navigator.pop(context, value.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _namaController.text.trim()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
