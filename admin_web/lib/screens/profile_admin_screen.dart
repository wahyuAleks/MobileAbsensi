import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/session.dart';

class ProfileAdminScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onBukaRekapAbsensi;

  const ProfileAdminScreen({
    super.key,
    this.showAppBar = false,
    this.onBukaRekapAbsensi,
  });

  @override
  State<ProfileAdminScreen> createState() => _ProfileAdminScreenState();
}

class _ProfileAdminScreenState extends State<ProfileAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaCtrl = TextEditingController(text: 'Super Admin');
  final _emailCtrl = TextEditingController(text: 'admin@mail.com');
  final _hpCtrl = TextEditingController(text: '081234567890');
  final _jabatanCtrl = TextEditingController(text: 'Administrator');

  final _passLamaCtrl = TextEditingController();
  final _passBaruCtrl = TextEditingController();

  bool _loading = false;
  bool _loadingPass = false;

  @override
  void initState() {
    super.initState();
    _muatProfil();
  }

  Future<void> _muatProfil() async {
    try {
      final prof = await ApiService.getProfile();
      if (mounted) {
        setState(() {
          _namaCtrl.text = prof['nama'] ?? 'Super Admin';
          _emailCtrl.text = prof['email'] ?? 'admin@mail.com';
          _hpCtrl.text = prof['no_hp'] ?? '081234567890';
          _jabatanCtrl.text = prof['jabatan'] ?? 'Administrator';
        });
      }
    } catch (_) {}
  }

  Future<void> _simpanProfil() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await ApiService.updateProfile(
        nama: _namaCtrl.text.trim(),
        noHp: _hpCtrl.text.trim(),
        jabatan: _jabatanCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      await Session.setNama(_namaCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Profil admin berhasil diperbarui'),
              backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _ubahPassword() async {
    if (_passLamaCtrl.text.isEmpty || _passBaruCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password lama dan baru harus diisi')));
      return;
    }
    setState(() => _loadingPass = true);
    try {
      await ApiService.ubahPassword(
        passwordLama: _passLamaCtrl.text,
        passwordBaru: _passBaruCtrl.text,
      );
      _passLamaCtrl.clear();
      _passBaruCtrl.clear();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Password berhasil diubah'),
              backgroundColor: Color(0xFF16A34A)),
        );
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loadingPass = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Profile Card
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          CircleAvatar(
                            radius: 32,
                            backgroundColor: AppConstants.primaryColor,
                            child: Text('SA',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold)),
                          ),
                          SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Super Admin',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F172A))),
                              Text('Administrator System',
                                  style: TextStyle(
                                      fontSize: 13, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _namaCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _emailCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Email Admin',
                            border: OutlineInputBorder()),
                        validator: (v) => v!.isEmpty ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jabatanCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Jabatan / Peran',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _hpCtrl,
                        decoration: const InputDecoration(
                            labelText: 'Nomor WhatsApp / HP',
                            border: OutlineInputBorder()),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _simpanProfil,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: _loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text('Simpan Perubahan Profil',
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 24),

            // Right Security Card
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02), blurRadius: 8)
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.shield_outlined,
                            color: AppConstants.primaryColor),
                        SizedBox(width: 10),
                        Text('Keamanan Akun',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Ubah Password Admin:',
                        style:
                            TextStyle(fontSize: 13, color: Color(0xFF64748B))),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passLamaCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password Saat Ini',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passBaruCtrl,
                      obscureText: true,
                      decoration: const InputDecoration(
                          labelText: 'Password Baru',
                          border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _loadingPass ? null : _ubahPassword,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F172A),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        child: _loadingPass
                            ? const CircularProgressIndicator(
                                color: Colors.white)
                            : const Text('Ubah Password',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
