import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/session.dart';
import '../login_screen.dart';
import 'edit_profile_screen.dart';
import 'ubah_password_screen.dart';
import 'kebijakan_privasi_screen.dart';
import 'components/notifikasi_karyawan_popup.dart';
import '../../core/notifikasi_service.dart';
import '../../core/app_events.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onBack;

  const ProfileScreen({super.key, this.onBack});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _muat();
    AppEvents.profileUpdated.addListener(_muat);
  }

  @override
  void dispose() {
    AppEvents.profileUpdated.removeListener(_muat);
    super.dispose();
  }

  Future<void> _muat() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.getProfile();
      if (mounted) setState(() => _user = data);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _getInitials(String name) {
    if (name.trim().isEmpty) return 'AF';
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  Future<void> _logout() async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Keluar dari Akun'),
        content: const Text(
            'Apakah Anda yakin ingin keluar dari aplikasi Absensiku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;

    await Session.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _dialogNotifikasi() {
    NotifikasiKaryawanPopup.show(context);
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = AppConstants.primaryColor;

    final nama = _user?['nama'] ?? 'Ahmad Fauzi';
    final jabatan = _user?['jabatan'] ?? 'Teknisi Drone Senior';
    final email = _user?['email'] ?? 'ahmad.f@drone.id';
    final nip = _user?['nip'] ?? 'DA-2024-0012';
    final divisi = _user?['divisi'] ?? 'Drone Agriculture';
    final status = _user?['is_active'] == false ? 'Nonaktif' : 'Aktif';

    final fotoUrl = AppConstants.getImageUrl(_user?['foto_profil']);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _muat,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 1. Judul Profil di Atas
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                        child: Row(
                          children: [
                            if (widget.onBack != null ||
                                Navigator.canPop(context)) ...[
                              IconButton(
                                tooltip: 'Kembali ke halaman sebelumnya',
                                onPressed: widget.onBack ??
                                    () => Navigator.of(context).maybePop(),
                                icon: const Icon(Icons.arrow_back_rounded),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(
                                    minWidth: 40, minHeight: 40),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Text(
                              'Profil',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF111827),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Banner Biru Profil Pengguna
                      Container(
                        width: double.infinity,
                        color: primaryColor,
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Column(
                          children: [
                            // Avatar Squircle dengan Badge Centang Hijau
                            GestureDetector(
                              onTap: () async {
                                final sukses =
                                    await Navigator.of(context).push<bool>(
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          EditProfileScreen(user: _user ?? {})),
                                );
                                if (sukses == true) _muat();
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFCBD5E1),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: fotoUrl != null
                                          ? Image.network(
                                              fotoUrl,
                                              width: 76,
                                              height: 76,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Container(
                                                color: const Color(0xFFCBD5E1),
                                                alignment: Alignment.center,
                                                child: Text(
                                                  _getInitials(nama),
                                                  style: const TextStyle(
                                                    fontSize: 26,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            )
                                          : Container(
                                              color: const Color(0xFFCBD5E1),
                                              alignment: Alignment.center,
                                              child: Text(
                                                _getInitials(nama),
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: -2,
                                    right: -2,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF22C55E),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: primaryColor, width: 2),
                                      ),
                                      child: const Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                        weight: 900,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Nama Pengguna
                            Text(
                              nama,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),

                            // Jabatan / Subtitle
                            Text(
                              jabatan,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.88),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 3. Kartu Info 2x2 (NIP, Divisi, Email, Status)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(child: _buildInfoBox('NIP', nip)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildInfoBox('Divisi', divisi)),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                      child: _buildInfoBox('Email', email)),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: _buildInfoBox('Status', status)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 4. Kartu Pengaturan Menu (Edit Profil, Ubah Password, Notifikasi, Kebijakan Privasi)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildMenuItem(
                                icon: Icons.person,
                                iconBg: const Color(0xFFE0F2FE),
                                iconColor: const Color(0xFF0284C7),
                                title: 'Edit Profil',
                                onTap: () async {
                                  final sukses =
                                      await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                        builder: (_) => EditProfileScreen(
                                            user: _user ?? {})),
                                  );
                                  if (sukses == true) _muat();
                                },
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  endIndent: 16,
                                  color: Color(0xFFF3F4F6)),
                              _buildMenuItem(
                                icon: Icons.shield_outlined,
                                iconBg: const Color(0xFFDCFCE7),
                                iconColor: const Color(0xFF16A34A),
                                title: 'Ubah Password',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const UbahPasswordScreen()),
                                  );
                                },
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  endIndent: 16,
                                  color: Color(0xFFF3F4F6)),
                              _buildMenuItem(
                                icon: Icons.notifications,
                                iconBg: const Color(0xFFFEF3C7),
                                iconColor: const Color(0xFFD97706),
                                title: 'Notifikasi',
                                onTap: _dialogNotifikasi,
                                trailing: ValueListenableBuilder<int>(
                                  valueListenable:
                                      NotifikasiService.unreadCountNotifier,
                                  builder: (context, unreadCount, _) {
                                    if (unreadCount <= 0)
                                      return const SizedBox.shrink();
                                    return Container(
                                      margin: const EdgeInsets.only(right: 8),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF4444),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '$unreadCount baru',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const Divider(
                                  height: 1,
                                  indent: 64,
                                  endIndent: 16,
                                  color: Color(0xFFF3F4F6)),
                              _buildMenuItem(
                                icon: Icons.description,
                                iconBg: const Color(0xFFEDE9FE),
                                iconColor: const Color(0xFF7C3AED),
                                title: 'Kebijakan Privasi',
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const KebijakanPrivasiScreen()),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 5. Kartu Keluar Akun
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB), width: 1.2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: _logout,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFEE2E2),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.meeting_room_outlined,
                                        color: Color(0xFFEF4444),
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    const Text(
                                      'Keluar',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEF4444),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer Versi Aplikasi
                      const Center(
                        child: Text(
                          'Absensiku V1.0.0 • Drone Agriculture Div.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInfoBox(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
              if (trailing != null) trailing,
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9CA3AF),
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
