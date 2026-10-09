import 'package:flutter/material.dart';
import '../../core/api_service.dart';

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
      final result = await ApiService.jenisKegiatanAdmin();
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
          isActive: item['is_active'] == true || item['is_active'] == 1,
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

  void _pesan(String value) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(value)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving ? null : () => _edit(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah jenis'),
      ),
      body: RefreshIndicator(
        onRefresh: _muat,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 160),
                      Center(child: Text('Gagal memuat data: $_error')),
                      Center(
                        child: TextButton(
                          onPressed: _muat,
                          child: const Text('Coba lagi'),
                        ),
                      ),
                    ],
                  )
                : _items.isEmpty
                    ? const Center(child: Text('Belum ada jenis kegiatan.'))
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                        itemCount: _items.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final active = item['is_active'] == true ||
                              item['is_active'] == 1 ||
                              item['is_active'] == '1';
                          return Card(
                            child: ListTile(
                              title: Text(item['nama'].toString()),
                              subtitle:
                                  Text(active ? 'Aktif' : 'Tidak aktif'),
                              leading: Icon(
                                active
                                    ? Icons.task_alt
                                    : Icons.pause_circle_outline,
                                color: active ? Colors.green : Colors.grey,
                              ),
                              trailing: Wrap(
                                children: [
                                  IconButton(
                                    tooltip: 'Ubah nama',
                                    onPressed:
                                        _saving ? null : () => _edit(item),
                                    icon: const Icon(Icons.edit_outlined),
                                  ),
                                  Switch(
                                    value: active,
                                    onChanged: (value) =>
                                        _ubahStatus(item, value),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
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
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Nama jenis kegiatan'),
          onSubmitted: (value) => Navigator.pop(context, value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, _controller.text.trim()),
            child: const Text('Simpan'),
          ),
        ],
      );
}
