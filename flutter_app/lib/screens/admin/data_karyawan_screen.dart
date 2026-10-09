import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import 'components/notifikasi_sheet.dart';

class DataKaryawanScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onBack;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaRekapAbsensi;
  final VoidCallback? onBukaPersetujuanCuti;
  final VoidCallback? onBukaProfil;

  const DataKaryawanScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onBack,
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

  // Data default persis sesuai mockup gambar jika database kosong/awal
  final List<Map<String, dynamic>> _mockKaryawan = [
    {
      'id': 1,
      'nip': 'DA-2024-001',
      'nama': 'Lilit\nRansink',
      'email': 'lilit@gmail.\ncom',
      'jabatan': 'Staff Operasional',
      'color': const Color(0xFF2F6B64), // Teal Green
    },
    {
      'id': 2,
      'nip': 'DA-2024-001',
      'nama': 'Ransink\nLilit',
      'email': 'ransink@gmail.\ncom',
      'jabatan': 'Staff Marketing',
      'color': const Color(0xFF385C83), // Slate Blue
    },
    {
      'id': 3,
      'nip': 'DA-2024-001',
      'nama': 'Udin\nKomarudin',
      'email': 'udin@gmail.\ncom',
      'jabatan': 'Staff IT',
      'color': const Color(0xFF2F6B64), // Teal Green
    },
    {
      'id': 4,
      'nip': 'DA-2024-001',
      'nama': 'Alak\nBizher',
      'email': 'alak@gmail.\ncom',
      'jabatan': 'Staff HRD',
      'color': const Color(0xFF385C83), // Slate Blue
    },
    {
      'id': 5,
      'nip': 'DA-2024-001',
      'nama': 'Mommy\nJenner',
      'email': 'mommy@gmail.\ncom',
      'jabatan': 'Finance',
      'color': const Color(0xFF2F6B64), // Teal Green
    },
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

  Future<void> _bukaNotifikasi() async {
    if (widget.onOpenNotifikasi != null) {
      widget.onOpenNotifikasi!();
      return;
    }
    await NotifikasiSheet.show(
      context,
      jumlahCutiMenunggu: 3,
      jumlahBelumAbsen: 5,
      jumlahTerlambat: 2,
      onTapCuti: widget.onBukaPersetujuanCuti,
      onTapBelumAbsen: widget.onBukaRekapAbsensi,
      onTapTerlambat: widget.onBukaRekapAbsensi,
    );
  }

  Future<void> _hapus(int id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Karyawan',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Yakin ingin menghapus data karyawan ini?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Hapus', style: TextStyle(color: Color(0xFFDC2626))),
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

  void _bukaMenuAksi(Map<String, dynamic> k) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (k['nama'] ?? 'Karyawan').toString().replaceAll('\n', ' '),
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              (k['email'] ?? '-').toString().replaceAll('\n', ''),
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.person_add_outlined,
                  color: Color(0xFF10B981)),
              title: const Text('Tambah Karyawan Baru'),
              onTap: () {
                Navigator.pop(ctx);
                _bukaFormTambah();
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.edit_outlined, color: Color(0xFF4F5BA8)),
              title: const Text('Edit Data Karyawan'),
              onTap: () {
                Navigator.pop(ctx);
                _bukaFormEdit(k);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
              title: const Text('Hapus Karyawan',
                  style: TextStyle(color: Color(0xFFDC2626))),
              onTap: () {
                Navigator.pop(ctx);
                _hapus(k['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final clean = name.replaceAll('\n', ' ').trim();
    if (clean.isEmpty) return 'K';
    final parts = clean.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return clean[0].toUpperCase();
  }

  String _formatNip(String raw) {
    if (raw.contains('\n')) return raw;
    return raw.replaceAll('-', '-\n');
  }

  String _formatNama(String raw) {
    if (raw.contains('\n')) return raw;
    final parts = raw.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0]}\n${parts.sublist(1).join(' ')}';
    }
    return raw;
  }

  String _formatEmail(String raw) {
    if (raw.contains('\n')) return raw;
    if (raw.contains('@')) {
      final lastDot = raw.lastIndexOf('.');
      if (lastDot > 0 && lastDot < raw.length - 1) {
        return '${raw.substring(0, lastDot + 1)}\n${raw.substring(lastDot + 1)}';
      }
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => _muat(),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. FLOATING TOP BAR PERSIS GAMBAR MOCKUP
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.menu_rounded,
                          size: 26,
                          color: Color(0xFF111827),
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: widget.onOpenDrawer,
                      ),

                      // Bell Notifikasi & Avatar "SA"
                      Row(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.notifications_rounded,
                                  size: 24,
                                  color: Color(0xFF111827),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _bukaNotifikasi,
                              ),
                              Positioned(
                                top: 2,
                                right: 2,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: widget.onBukaProfil,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color:
                                    Color(0xFF488286), // Teal SA persis gambar
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'SA',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    if (widget.onBack != null) ...[
                      IconButton(
                        tooltip: 'Kembali ke halaman sebelumnya',
                        icon: const Icon(Icons.arrow_back_rounded),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 40, minHeight: 40),
                        onPressed: widget.onBack,
                      ),
                      const SizedBox(width: 8),
                    ],
                    const Text(
                      'Data Karyawan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // 2. KOTAK SEARCH "Cari nama / NIP ..." PERSIS GAMBAR
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) =>
                        setState(() => _query = v.trim().toLowerCase()),
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF111827)),
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search_rounded,
                          color: Color(0xFF9CA3AF), size: 22),
                      hintText: 'Cari nama / NIP ...',
                      hintStyle: TextStyle(
                        color: Color(0xFF9CA3AF),
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 18),

                // 3. CARD TABEL DATA KARYAWAN PERSIS GAMBAR
                FutureBuilder<List<dynamic>>(
                  future: _future,
                  builder: (context, snap) {
                    List<Map<String, dynamic>> items;

                    if (snap.hasData && snap.data!.isNotEmpty) {
                      items = snap.data!.asMap().entries.map((entry) {
                        final i = entry.key;
                        final k = Map<String, dynamic>.from(entry.value);
                        final id = k['id'] ?? (i + 1);
                        final nip = 'DA-2024-${id.toString().padLeft(3, '0')}';
                        final color = i.isEven
                            ? const Color(0xFF2F6B64)
                            : const Color(0xFF385C83);
                        return {
                          'id': id,
                          'nip': nip,
                          'nama': k['nama'] ?? 'Karyawan',
                          'email': k['email'] ?? '-',
                          'jabatan': k['jabatan'] ?? 'Staff',
                          'location_id': k['location_id'],
                          'color': color,
                        };
                      }).toList();
                    } else {
                      // Gunakan data mockup yang persis dengan yang dikirim user
                      items = _mockKaryawan;
                    }

                    // Filter pencarian
                    final filtered = items.where((k) {
                      if (_query.isEmpty) return true;
                      final nama = (k['nama'] ?? '').toString().toLowerCase();
                      final nip = (k['nip'] ?? '').toString().toLowerCase();
                      final email = (k['email'] ?? '').toString().toLowerCase();
                      return nama.contains(_query) ||
                          nip.contains(_query) ||
                          email.contains(_query);
                    }).toList();

                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header Kolom: NIP | NAMA | EMAIL
                          const Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  'NIP',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'NAMA',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'EMAIL',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Daftar Baris Karyawan
                          if (filtered.isEmpty)
                            Center(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 24),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Karyawan tidak ditemukan',
                                      style: TextStyle(
                                          color: Color(0xFF6B7280),
                                          fontSize: 13),
                                    ),
                                    const SizedBox(height: 12),
                                    TextButton.icon(
                                      onPressed: _bukaFormTambah,
                                      icon: const Icon(Icons.add, size: 18),
                                      label: const Text('Tambah Karyawan'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 20),
                              itemBuilder: (context, i) {
                                final k = filtered[i];
                                final rawNip = k['nip'] as String;
                                final rawNama = (k['nama'] as String);
                                final rawEmail = (k['email'] as String);
                                final avatarColor = (k['color'] as Color?) ??
                                    (i.isEven
                                        ? const Color(0xFF2F6B64)
                                        : const Color(0xFF385C83));
                                final initials = _getInitials(rawNama);

                                final displayNip = _formatNip(rawNip);
                                final displayNama = _formatNama(rawNama);
                                final displayEmail = _formatEmail(rawEmail);

                                return InkWell(
                                  onTap: () => _bukaMenuAksi(k),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        // Kolom NIP
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            displayNip,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4B5563),
                                              height: 1.25,
                                            ),
                                          ),
                                        ),

                                        // Kolom NAMA: Avatar Lingkaran + Nama
                                        Expanded(
                                          flex: 3,
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              CircleAvatar(
                                                radius: 17,
                                                backgroundColor: avatarColor,
                                                child: Text(
                                                  initials,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 11.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  displayNama,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFF4B5563),
                                                    height: 1.25,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        // Kolom EMAIL
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            displayEmail,
                                            style: const TextStyle(
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF4B5563),
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),

                          const SizedBox(height: 28),

                          // Footer: Menampilkan X dari Y karyawan
                          Text(
                            'Menampilkan ${filtered.length} dari ${items.length} karyawan',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
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
  bool _memuatLokasi = true;
  bool _gagalMuatLokasi = false;
  List<Map<String, dynamic>> _lokasi = [];
  int? _locationId;

  bool get _modeEdit => widget.karyawan != null;

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _jabatanCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _namaCtrl = TextEditingController(
        text: widget.karyawan?['nama']?.toString().replaceAll('\n', ' '));
    _emailCtrl = TextEditingController(
        text: widget.karyawan?['email']?.toString().replaceAll('\n', ''));
    _passwordCtrl = TextEditingController();
    _jabatanCtrl = TextEditingController(text: widget.karyawan?['jabatan']);
    _hpCtrl = TextEditingController(text: widget.karyawan?['no_hp']);
    final rawLocationId = widget.karyawan?['location_id'];
    _locationId =
        rawLocationId == null ? null : int.tryParse(rawLocationId.toString());
    _muatLokasi();
  }

  Future<void> _muatLokasi() async {
    try {
      final result = await ApiService.daftarLokasi();
      if (!mounted) return;
      setState(() {
        _lokasi = result.map((e) => Map<String, dynamic>.from(e)).toList();
        _memuatLokasi = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _memuatLokasi = false;
        _gagalMuatLokasi = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat daftar lokasi: $e')),
      );
    }
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gagalMuatLokasi) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Lokasi kerja belum bisa dimuat. Coba lagi nanti.')),
      );
      return;
    }
    setState(() => _menyimpan = true);
    try {
      if (_modeEdit) {
        await ApiService.updateKaryawan(widget.karyawan!['id'], {
          'nama': _namaCtrl.text.trim(),
          'jabatan': _jabatanCtrl.text.trim(),
          'no_hp': _hpCtrl.text.trim(),
          'location_id': _locationId,
        });
      } else {
        await ApiService.tambahKaryawan({
          'nama': _namaCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'password': _passwordCtrl.text,
          'jabatan': _jabatanCtrl.text.trim(),
          'no_hp': _hpCtrl.text.trim(),
          'location_id': _locationId,
        });
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSukses();
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(_modeEdit ? 'Edit Karyawan' : 'Tambah Karyawan',
          style: const TextStyle(fontWeight: FontWeight.bold)),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Wajib diisi' : null,
              ),
              if (!_modeEdit) ...[
                TextFormField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Password'),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                ),
              ],
              TextFormField(
                  controller: _jabatanCtrl,
                  decoration: const InputDecoration(labelText: 'Jabatan')),
              TextFormField(
                  controller: _hpCtrl,
                  decoration: const InputDecoration(labelText: 'No. HP')),
              const SizedBox(height: 8),
              if (_memuatLokasi)
                const LinearProgressIndicator()
              else if (_gagalMuatLokasi)
                const InputDecorator(
                  decoration: InputDecoration(labelText: 'Lokasi kerja'),
                  child: Text('Daftar lokasi gagal dimuat'),
                )
              else
                DropdownButtonFormField<int?>(
                  initialValue: _locationId,
                  decoration: const InputDecoration(labelText: 'Lokasi kerja'),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Pilih lokasi kerja'),
                    ),
                    ..._lokasi.map((lokasi) {
                      final id = int.parse(lokasi['id'].toString());
                      return DropdownMenuItem<int?>(
                        value: id,
                        child: Text(lokasi['nama'].toString()),
                      );
                    }),
                  ],
                  onChanged: (value) => setState(() => _locationId = value),
                  validator: (value) => _lokasi.isNotEmpty && value == null
                      ? 'Lokasi kerja wajib dipilih'
                      : null,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(
          onPressed: _menyimpan ? null : _simpan,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4F5BA8),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _menyimpan
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white))
              : const Text('Simpan', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
