import 'package:flutter/material.dart';
import '../core/api_service.dart';

class JenisKegiatanScreen extends StatefulWidget {
  const JenisKegiatanScreen({super.key});

  @override
  State<JenisKegiatanScreen> createState() => _JenisKegiatanScreenState();
}

class _JenisKegiatanScreenState extends State<JenisKegiatanScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

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
      final result = await ApiService.jenisKegiatan();
      if (!mounted) return;
      setState(() {
        _items = result.map((item) => Map<String, dynamic>.from(item)).toList();
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

  Future<void> _edit([Map<String, dynamic>? item]) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NamaJenisDialog(initialName: item?['nama']?.toString()),
    );
    if (name == null || name.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      if (item == null) {
        await ApiService.tambahJenisKegiatan(name.trim());
      } else {
        await ApiService.perbaruiJenisKegiatan(
          int.parse(item['id'].toString()),
          nama: name.trim(),
          isActive: _isActive(item),
        );
      }
      await _muat();
      if (mounted) _pesan('Jenis kegiatan berhasil disimpan.');
    } catch (e) {
      if (mounted) _pesan('Gagal menyimpan jenis kegiatan: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _ubahStatus(Map<String, dynamic> item, bool aktif) async {
    try {
      await ApiService.perbaruiJenisKegiatan(
        int.parse(item['id'].toString()),
        isActive: aktif,
      );
      await _muat();
    } catch (e) {
      if (mounted) _pesan('Gagal mengubah status jenis kegiatan: $e');
    }
  }

  bool _isActive(Map<String, dynamic> item) =>
      item['is_active'] == true ||
      item['is_active'] == 1 ||
      item['is_active'] == '1';

  void _pesan(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _muat,
            child: ListView(
              padding: const EdgeInsets.all(28),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Master Jenis Kegiatan',
                        style: TextStyle(
                            fontSize: 25, fontWeight: FontWeight.w800),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _saving ? null : () => _edit(),
                      icon: const Icon(Icons.add),
                      label: const Text('Tambah jenis'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kelola pilihan jenis kegiatan yang digunakan karyawan saat membuat laporan. Jenis yang dinonaktifkan tetap tersimpan pada laporan lama.',
                  style:
                      TextStyle(color: Color(0xFF6B7280), height: 1.4),
                ),
                const SizedBox(height: 20),
                if (_loading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (_error != null)
                  Column(
                    children: [
                      Text('Gagal memuat jenis kegiatan: $_error'),
                      TextButton(
                          onPressed: _muat, child: const Text('Coba lagi')),
                    ],
                  )
                else if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('Belum ada jenis kegiatan.')),
                  )
                else
                  for (final item in _items)
                    Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      child: ListTile(
                        title: Text(
                          item['nama'].toString(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(_isActive(item) ? 'Aktif' : 'Tidak aktif'),
                        leading: Icon(
                          _isActive(item)
                              ? Icons.task_alt
                              : Icons.pause_circle_outline,
                          color: _isActive(item)
                              ? const Color(0xFF15803D)
                              : const Color(0xFF6B7280),
                        ),
                        trailing: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            IconButton(
                              tooltip: 'Ubah nama',
                              onPressed:
                                  _saving ? null : () => _edit(item),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            Switch(
                              value: _isActive(item),
                              onChanged: (value) => _ubahStatus(item, value),
                            ),
                          ],
                        ),
                      ),
                    ),
              ],
            ),
          ),
        ),
      );
}

class _NamaJenisDialog extends StatefulWidget {
  final String? initialName;

  const _NamaJenisDialog({this.initialName});

  @override
  State<_NamaJenisDialog> createState() => _NamaJenisDialogState();
}

class _NamaJenisDialogState extends State<_NamaJenisDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.initialName == null
            ? 'Tambah jenis kegiatan'
            : 'Ubah jenis kegiatan'),
        content: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Nama jenis kegiatan'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      );
}
