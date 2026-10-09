import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/session.dart';
import 'dashboard_web_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController(text: 'admin@mail.com');
  final _passCtrl = TextEditingController(text: 'admin123');
  final _serverUrlCtrl = TextEditingController();

  bool _loading = false;
  bool _hidePass = true;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _initUrl();
  }

  Future<void> _initUrl() async {
    await AppConstants.initBaseUrl();
    _serverUrlCtrl.text = AppConstants.baseUrl;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _serverUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;

      if (email.isEmpty || pass.isEmpty) {
        throw ApiException('Email dan password harus diisi.');
      }

      final res = await ApiService.login(email, pass);
      final token = res['token']?.toString() ?? '';
      final user = res['user'] ?? {};
      final role = user['role']?.toString() ?? 'admin';
      final nama = user['nama']?.toString() ?? 'Admin';

      if (role != 'admin') {
        throw ApiException('Akses ditolak. Halaman ini khusus untuk Admin.');
      }

      await Session.simpanLogin(token: token, role: role, nama: nama);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardWebScreen()),
      );
    } catch (e) {
      setState(() => _errorMsg = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showServerSettings() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pengaturan URL Server API'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _serverUrlCtrl,
                decoration: const InputDecoration(
                  labelText: 'Base URL API',
                  border: OutlineInputBorder(),
                  hintText: 'http://localhost:3000/api',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  ActionChip(
                    label: const Text('localhost:3000'),
                    onPressed: () =>
                        _serverUrlCtrl.text = AppConstants.urlLocalhost,
                  ),
                  ActionChip(
                    label: const Text('127.0.0.1:3000'),
                    onPressed: () =>
                        _serverUrlCtrl.text = AppConstants.urlIpLocal,
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AppConstants.setBaseUrl(_serverUrlCtrl.text);
              if (mounted) Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('URL Server disimpan: ${AppConstants.baseUrl}')),
              );
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            width: 440,
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
              border: Border.all(color: const Color(0xFFE1E4E8)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header Brand Logo
                Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: AppConstants.primaryColor,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppConstants.primaryColor.withValues(alpha: 0.5),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white, size: 36),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Admin Web Portal',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF111827),
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Aplikasi Absensi & Manajemen Karyawan',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280), fontSize: 13),
                ),
                const SizedBox(height: 28),

                if (_errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFDC2626), size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(_errorMsg!,
                              style: const TextStyle(
                                  color: Color(0xFF991B1B), fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Form Email
                const Text('Email Admin',
                    style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _emailCtrl,
                  style: const TextStyle(color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: Color(0xFF6B7280)),
                    hintText: 'admin@mail.com',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Form Password
                const Text('Password',
                    style: TextStyle(
                        color: Color(0xFF374151),
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _passCtrl,
                  obscureText: _hidePass,
                  style: const TextStyle(color: Color(0xFF111827)),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: Color(0xFF6B7280)),
                    suffixIcon: IconButton(
                      icon: Icon(
                          _hidePass ? Icons.visibility_off : Icons.visibility,
                          color: const Color(0xFF6B7280)),
                      onPressed: () => setState(() => _hidePass = !_hidePass),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFF9FAFB),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                ElevatedButton(
                  onPressed: _loading ? null : _doLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Masuk Dashboard Admin',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 20),

                // Server URL Settings Button
                Center(
                  child: TextButton.icon(
                    onPressed: _showServerSettings,
                    icon: const Icon(Icons.dns_rounded,
                        size: 18, color: Color(0xFF6B7280)),
                    label: const Text('Pengaturan Server URL',
                        style:
                            TextStyle(color: Color(0xFF6B7280), fontSize: 13)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
