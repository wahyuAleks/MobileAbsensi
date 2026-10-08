import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import 'components/notifikasi_sheet.dart';

class DataKaryawanScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaRekapAbsensi;
  final VoidCallback? onBukaPersetujuanCuti;
  final VoidCallback? onBukaProfil;

  const DataKaryawanScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaRekapAbsensi,
    this.onBukaPersetujuanCuti,
    this.onBukaProfil,
  });

  @override
  State<DataKaryawanScreen> createState() => _DataKaryawanScreenState();
}

class _DataKaryawanScreenState extends State<DataKaryawanScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  late Future<List<dynamic>> _future;
  String _query = '';

  final List<Map<String, dynamic>> _mockKaryawan = [
    {'id': 1, 'nip': 'DA-2024-001', 'nama': 'Lilit Ransink', 'email': 'lilit@gmail.com', 'jabatan': 'Staff Operasional', 'no_hp': '081234567891'},
    {'id': 2, 'nip': 'DA-2024-002', 'nama': 'Ransink Lilit', 'email': 'ransink@gmail.com', 'jabatan': 'Staff Marketing', 'no_hp': '081234567892'},
    {'id': 3, 'nip': 'DA-2024-003', 'nama': 'Udin Komarudin', 'email': 'udin@gmail.com', 'jabatan': 'Staff IT', 'no_hp': '081234567893'},
    {'id': 4, 'nip': 'DA-2024-004', 'nama': 'Alak Bizher', 'email': 'alak@gmail.com', 'jabatan': 'Staff HRD', 'no_hp': '081234567894'},
    {'id': 5, 'nip': 'DA-2024-005', 'nama': 'Mommy Jenner', 'email': 'mommy@gmail.com', 'jabatan': 'Finance', 'no_hp': '081234567895'},
  ];

  @override
  void initState() {
    super.initState();
    _muat();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _muat() {
    setState(() {
      _future = ApiService.daftarKaryawan();
    });
  }

  Future<void> _hapus(int id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Karyawan', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin menghapus data karyawan ini dari database?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    try {
      await ApiService.hapusKaryawan(id);
      _muat();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  void _bukaFormTambah() {
    showDialog(
      context: context,
      builder: (context) => _FormKaryawanDialog(onSukses: _muat),
    );
  }

  void _bukaFormEdit(Map<String, dynamic> karyawan) {
    showDialog(
      context: context,
      builder: (context) => _FormKaryawanDialog(karyawan: karyawan, onSukses: _muat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Toolbar: Search + Tambah Karyawan Button
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Color(0xFF64748B)),
                        hintText: 'Cari berdasarkan nama, email, NIP, atau jabatan...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _bukaFormTambah,
                  icon: const Icon(Icons.person_add_rounded, size: 20),
                  label: const Text('Tambah Karyawan Baru'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data Table Container
            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                List<Map<String, dynamic>> items;
                if (snap.hasData && snap.data!.isNotEmpty) {
                  items = snap.data!.asMap().entries.map((entry) {
                    final i = entry.key;
                    final k = Map<String, dynamic>.from(entry.value);
                    final id = k['id'] ?? (i + 1);
                    return {
                      'id': id,
                      'nip': 'DA-2024-${id.toString().padLeft(3, '0')}',
                      'nama': k['nama'] ?? 'Karyawan',
                      'email': k['email'] ?? '-',
                      'jabatan': k['jabatan'] ?? 'Staff',
                      'no_hp': k['no_hp'] ?? '-',
                    };
                  }).toList();
                } else {
                  items = _mockKaryawan;
                }

                final filtered = items.where((k) {
                  if (_query.isEmpty) return true;
                  final nama = (k['nama'] ?? '').toString().toLowerCase();
                  final nip = (k['nip'] ?? '').toString().toLowerCase();
                  final email = (k['email'] ?? '').toString().toLowerCase();
                  final jabatan = (k['jabatan'] ?? '').toString().toLowerCase();
                  return nama.contains(_query) || nip.contains(_query) || email.contains(_query) || jabatan.contains(_query);
                }).toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(flex: 2, child: Text('NIP', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 3, child: Text('NAMA KARYAWAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 3, child: Text('EMAIL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('JABATAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('AKSI', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                        ],
                      ),
                      const Divider(height: 24),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(child: Text('Data karyawan tidak ditemukan', style: TextStyle(color: Colors.grey))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final k = filtered[i];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(k['nip'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Expanded(
                                    flex: 3,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: i.isEven ? const Color(0xFF2F6B64) : const Color(0xFF385C83),
                                          child: Text(
                                            k['nama'].toString().isNotEmpty ? k['nama'].toString()[0].toUpperCase() : 'K',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(k['nama'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 3, child: Text(k['email'] ?? '-', style: const TextStyle(color: Color(0xFF475569)))),
                                  Expanded(flex: 2, child: Text(k['jabatan'] ?? '-', style: const TextStyle(color: Color(0xFF475569)))),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, color: AppConstants.primaryColor, size: 20),
                                          onPressed: () => _bukaFormEdit(k),
                                          tooltip: 'Edit Data',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                                          onPressed: () => _hapus(k['id']),
                                          tooltip: 'Hapus Data',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: 16),
                      Text(
                        'Menampilkan ${filtered.length} dari ${items.length} total karyawan',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FormKaryawanDialog extends StatefulWidget {
  final Map<String, dynamic>? karyawan;
  final VoidCallback onSukses;
  const _FormKaryawanDialog({this.karyawan, required this.onSukses});

  @override
  State<_FormKaryawanDialog> createState() => _FormKaryawanDialogState();
}

class _FormKaryawanDialogState extends State<_FormKaryawanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _namaCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _jabatanCtrl;
  late final TextEditingController _hpCtrl;
  bool _menyimpan = false;

  bool get _modeEdit => widget.karyawan != null;

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(text: widget.karyawan?['nama']?.toString());
    _emailCtrl = TextEditingController(text: widget.karyawan?['email']?.toString());
    _passwordCtrl = TextEditingController();
    _jabatanCtrl = TextEditingController(text: widget.karyawan?['jabatan']);
    _hpCtrl = TextEditingController(text: widget.karyawan?['no_hp']);
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _menyimpan = true);
    try {
      if (_modeEdit) {
        await ApiService.updateKaryawan(widget.karyawan!['id'], {
          'nama': _namaCtrl.text.trim(),
          'jabatan': _jabatanCtrl.text.trim(),
          'no_hp': _hpCtrl.text.trim(),
        });
      } else {
        await ApiService.tambahKaryawan({
          'nama': _namaCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'jabatan': _jabatanCtrl.text.trim(),
          'no_hp': _hpCtrl.text.trim(),
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSukses();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_modeEdit ? 'Edit Data Karyawan' : 'Tambah Karyawan Baru', style: const TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaCtrl,
                  decoration: const InputDecoration(labelText: 'Nama Lengkap', border: OutlineInputBorder()),
                  validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                if (!_modeEdit) ...[
                  TextFormField(
                    controller: _emailCtrl,
                    decoration: const InputDecoration(labelText: 'Email Karyawan', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password Akun', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _jabatanCtrl,
                  decoration: const InputDecoration(labelText: 'Jabatan / Posisi', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _hpCtrl,
                  decoration: const InputDecoration(labelText: 'Nomor HP / WhatsApp', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
        ElevatedButton(
          onPressed: _menyimpan ? null : _simpan,
          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.primaryColor),
          child: _menyimpan
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Simpan Data', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
