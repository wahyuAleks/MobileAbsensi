import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

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
      _future = ApiService.daftarAkun();
    });
  }

  Future<void> _hapus(int id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin menghapus akun ini dari database?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626)),
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
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
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
      builder: (context) =>
          _FormKaryawanDialog(karyawan: karyawan, onSukses: _muat),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Karyawan',
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827)),
            ),
            const SizedBox(height: 3),
            const Text(
              'Kelola data akun admin dan karyawan.',
              style: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),
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
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      decoration: const InputDecoration(
                        icon: Icon(Icons.search, color: Color(0xFF64748B)),
                        hintText: 'Cari berdasarkan nama, email, atau role...',
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data Table Container
            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Daftar akun gagal dimuat',
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFB91C1C)),
                        ),
                        const SizedBox(height: 12),
                        Text(snap.error.toString(),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: _muat,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                List<Map<String, dynamic>> items;
                items = snap.data!.asMap().entries.map((entry) {
                  final i = entry.key;
                  final k = Map<String, dynamic>.from(entry.value);
                  final id = k['id'] ?? (i + 1);
                  return {
                    'id': id,
                    'nama': k['nama'] ?? 'Karyawan',
                    'email': k['email'] ?? '-',
                    'role': k['role'] ?? 'karyawan',
                    'jabatan': k['jabatan'] ?? 'Staff',
                    'no_hp': k['no_hp'] ?? '-',
                  };
                }).toList();

                final filtered = items.where((k) {
                  if (_query.isEmpty) return true;
                  final nama = (k['nama'] ?? '').toString().toLowerCase();
                  final email = (k['email'] ?? '').toString().toLowerCase();
                  final role = (k['role'] ?? '').toString().toLowerCase();
                  return nama.contains(_query) ||
                      email.contains(_query) ||
                      role.contains(_query);
                }).toList();

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Expanded(
                              flex: 4,
                              child: Text('NAMA LENGKAP',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      fontSize: 12))),
                          Expanded(
                              flex: 4,
                              child: Text('EMAIL',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      fontSize: 12))),
                          Expanded(
                              flex: 2,
                              child: Text('ROLE',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      fontSize: 12))),
                          Expanded(
                              flex: 2,
                              child: Text('AKSI',
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF64748B),
                                      fontSize: 12))),
                        ],
                      ),
                      const Divider(height: 24),
                      if (filtered.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                              child: Text('Data akun tidak ditemukan',
                                  style: TextStyle(color: Colors.grey))),
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
                                  Expanded(
                                    flex: 4,
                                    child: Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 16,
                                          backgroundColor: i.isEven
                                              ? const Color(0xFF2F6B64)
                                              : const Color(0xFF385C83),
                                          child: Text(
                                            k['nama'].toString().isNotEmpty
                                                ? k['nama']
                                                    .toString()[0]
                                                    .toUpperCase()
                                                : 'K',
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(k['nama'] ?? '-',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                      flex: 4,
                                      child: Text(k['email'] ?? '-',
                                          style: const TextStyle(
                                              color: Color(0xFF475569)))),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: k['role'] == 'admin'
                                              ? const Color(0xFFEDE9FE)
                                              : const Color(0xFFDCFCE7),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          k['role'] == 'admin'
                                              ? 'Admin'
                                              : 'Karyawan',
                                          style: TextStyle(
                                            color: k['role'] == 'admin'
                                                ? const Color(0xFF6D28D9)
                                                : const Color(0xFF15803D),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined,
                                              color: AppConstants.primaryColor,
                                              size: 20),
                                          onPressed: () => _bukaFormEdit(k),
                                          tooltip: 'Edit Data',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline,
                                              color: Color(0xFFDC2626),
                                              size: 20),
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
                        'Menampilkan ${filtered.length} dari ${items.length} total akun',
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                            fontWeight: FontWeight.w500),
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
  String _role = 'karyawan';
  bool _menyimpan = false;
  bool _passwordTampil = false;

  bool get _modeEdit => widget.karyawan != null;

  @override
  void initState() {
    super.initState();
    _namaCtrl =
        TextEditingController(text: widget.karyawan?['nama']?.toString());
    _emailCtrl =
        TextEditingController(text: widget.karyawan?['email']?.toString());
    _passwordCtrl = TextEditingController();
    _jabatanCtrl = TextEditingController(text: widget.karyawan?['jabatan']);
    _hpCtrl = TextEditingController(text: widget.karyawan?['no_hp']);
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _jabatanCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
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
          'role': _role,
        });
      }
      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      Navigator.pop(context);
      widget.onSukses();
      messenger.showSnackBar(
        SnackBar(
          content: Text(_modeEdit
              ? 'Data akun berhasil diperbarui'
              : 'Akun ${_role == 'admin' ? 'Admin' : 'Karyawan'} berhasil ditambahkan'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _menyimpan = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF9FAFB),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      title: Row(
        children: [
          InkWell(
            onTap: _menyimpan ? null : () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  color: AppConstants.primaryColor, shape: BoxShape.circle),
              alignment: Alignment.center,
              child:
                  const Icon(Icons.arrow_back, color: Colors.white, size: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              _modeEdit ? 'Edit Data Akun' : 'Tambah Karyawan Baru',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF111827)),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'INFORMASI AKUN',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF6B7280),
                        letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _namaCtrl,
                    label: 'Nama Lengkap',
                    hint: 'Masukkan nama lengkap',
                    icon: Icons.person_outline_rounded,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Nama lengkap wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  if (!_modeEdit) ...[
                    DropdownButtonFormField<String>(
                      initialValue: _role,
                      decoration: _inputDecoration(
                          label: 'Role',
                          hint: 'Pilih role akun',
                          icon: Icons.badge_outlined),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'karyawan', child: Text('Karyawan')),
                      ],
                      onChanged: _menyimpan
                          ? null
                          : (value) =>
                              setState(() => _role = value ?? 'karyawan'),
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _emailCtrl,
                      label: 'Email',
                      hint: 'nama@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        final email = value?.trim() ?? '';
                        if (email.isEmpty) return 'Email wajib diisi';
                        if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                            .hasMatch(email))
                          return 'Masukkan alamat email yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordCtrl,
                      label: 'Password',
                      hint: 'Buat password akun',
                      icon: Icons.lock_outline_rounded,
                      obscureText: !_passwordTampil,
                      suffixIcon: IconButton(
                        tooltip: _passwordTampil
                            ? 'Sembunyikan password'
                            : 'Tampilkan password',
                        onPressed: () =>
                            setState(() => _passwordTampil = !_passwordTampil),
                        icon: Icon(_passwordTampil
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                      ),
                      validator: (v) => v == null || v.isEmpty
                          ? 'Password wajib diisi'
                          : null,
                    ),
                  ] else ...[
                    _buildTextField(
                      controller: _jabatanCtrl,
                      label: 'Jabatan / Posisi',
                      hint: 'Masukkan jabatan',
                      icon: Icons.work_outline_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _hpCtrl,
                      label: 'Nomor HP / WhatsApp',
                      hint: 'Masukkan nomor telepon',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _menyimpan ? null : () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF4B5563),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _menyimpan ? null : _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _menyimpan
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : Text(_modeEdit ? 'Simpan Perubahan' : 'Simpan Akun'),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
      prefixIcon: Icon(icon, color: const Color(0xFF6B7280), size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB))),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: AppConstants.primaryColor, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      decoration: _inputDecoration(
          label: label, hint: hint, icon: icon, suffixIcon: suffixIcon),
    );
  }
}
