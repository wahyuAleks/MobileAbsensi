import 'dart:convert';
import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

class RekapLaporanScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaProfil;

  const RekapLaporanScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaProfil,
  });

  @override
  State<RekapLaporanScreen> createState() => _RekapLaporanScreenState();
}

class _RekapLaporanScreenState extends State<RekapLaporanScreen> {
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
      _future = ApiService.rekapLaporan();
    });
  }

  Future<void> _bukaEditLaporan(Map<String, dynamic> item) async {
    final edited = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _EditLaporanDialog(laporan: item),
    );
    if (edited == null || !mounted) return;

    try {
      await ApiService.editLaporanAdmin(
        int.parse(item['id'].toString()),
        tanggal: edited['tanggal']!,
        judul: edited['judul']!,
        isiLaporan: edited['isi_laporan']!,
        jenisKegiatan: edited['jenis_kegiatan'],
        lokasi: edited['lokasi'],
        unitDrone: edited['unit_drone'],
        luasArea: edited['luas_area'],
        uraianPekerjaan: edited['uraian_pekerjaan'],
        hasil: edited['hasil'],
        rencanaEsok: edited['rencana_esok'],
      );
      if (!mounted) return;
      _muat();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil diperbarui oleh Admin.'),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengedit laporan: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  Future<void> _lihatDetailLaporan(Map<String, dynamic> item) async {
    final lampiranRaw = item['lampiran']?.toString();
    final List<String> lampiranList = [];
    if (lampiranRaw != null && lampiranRaw.isNotEmpty) {
      if (lampiranRaw.startsWith('[')) {
        try {
          final decoded = jsonDecode(lampiranRaw) as List;
          lampiranList.addAll(decoded.map((e) => e.toString()));
        } catch (_) {
          lampiranList.add(lampiranRaw);
        }
      } else {
        lampiranList.add(lampiranRaw);
      }
    }
    final user = item['User'] is Map ? item['User'] as Map : const {};
    final nama = (user['nama'] ?? item['nama'] ?? 'Karyawan').toString();
    final tgl = (item['tanggal'] ?? '-').toString();
    final judul = (item['judul'] ?? 'Laporan').toString();
    final isi = (item['isi_laporan'] ?? item['uraian_pekerjaan'] ?? '-').toString();
    final jenis = item['jenis_kegiatan']?.toString();
    final lokasi = item['lokasi']?.toString();
    final unitDrone = item['unit_drone']?.toString();
    final luasArea = item['luas_area']?.toString();
    final hasil = item['hasil']?.toString();
    final rencanaEsok = item['rencana_esok']?.toString();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.description_outlined, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                judul,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 580,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Color(0xFF4F5BA8)),
                    const SizedBox(width: 6),
                    Text(
                      nama,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      tgl,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (jenis != null && jenis.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.category_outlined, size: 14),
                        label: Text(jenis, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                    if (lokasi != null && lokasi.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.location_on_outlined, size: 14),
                        label: Text(lokasi, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                    if (unitDrone != null && unitDrone.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.flight_outlined, size: 14),
                        label: Text('Drone: $unitDrone', style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                    if (luasArea != null && luasArea.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.crop_square_outlined, size: 14),
                        label: Text('Luas: $luasArea', style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                const Text(
                  'Uraian Pekerjaan / Isi Laporan:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Text(
                    isi,
                    style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF1F2937)),
                  ),
                ),
                if (hasil != null && hasil.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Hasil Pekerjaan:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 6),
                  Text(hasil, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                ],
                if (rencanaEsok != null && rencanaEsok.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Rencana Esok:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 6),
                  Text(rencanaEsok, style: const TextStyle(fontSize: 13, color: Color(0xFF4B5563))),
                ],
                if (lampiranList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Dokumentasi Kegiatan Lapangan:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF374151)),
                      ),
                      const Spacer(),
                      if (lampiranList.length > 1)
                        Text(
                          '${lampiranList.length} foto',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (lampiranList.length == 1)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        AppConstants.getImageUrl(lampiranList.first)!,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          height: 100,
                          color: const Color(0xFFF3F4F6),
                          alignment: Alignment.center,
                          child: const Text('Foto dokumentasi tidak dapat dimuat.'),
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: lampiranList.map((path) {
                        final url = AppConstants.getImageUrl(path);
                        return GestureDetector(
                          onTap: url == null ? null : () => _tampilkanFotoPenuh(ctx, url),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: url != null
                                ? Image.network(
                                    url,
                                    width: 120,
                                    height: 120,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 120,
                                      height: 120,
                                      color: const Color(0xFFF3F4F6),
                                      child: const Center(
                                          child: Icon(Icons.broken_image_outlined,
                                              color: Color(0xFF9CA3AF))),
                                    ),
                                  )
                                : Container(
                                    width: 120,
                                    height: 120,
                                    color: const Color(0xFFF3F4F6),
                                    child: const Center(
                                        child: Icon(Icons.broken_image_outlined,
                                            color: Color(0xFF9CA3AF))),
                                  ),
                          ),
                        );
                      }).toList(),
                    ),
                ],

              ],
            ),
          ),
        ),
        actions: [
          FilledButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _bukaEditLaporan(item);
            },
            style: FilledButton.styleFrom(backgroundColor: AppConstants.primaryColor),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Edit Laporan'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
  }

  void _tampilkanFotoPenuh(BuildContext ctx, String url) {
    showDialog(
      context: ctx,
      builder: (fCtx) => GestureDetector(
        onTap: () => Navigator.pop(fCtx),
        child: Dialog(
          backgroundColor: Colors.black87,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Center(
                child: InteractiveViewer(
                  child: Image.network(
                    url,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Text(
                        'Foto tidak dapat dimuat.',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 40,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(fCtx),
                ),
              ),
            ],
          ),
        ),
      ),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Rekapitulasi Laporan Harian Karyawan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Pantau dokumentasi dan edit laporan karyawan secara terpusat di Web Admin.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: _muat,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Cari berdasarkan nama karyawan, judul, atau isi laporan...',
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
              ),
            ),
            const SizedBox(height: 16),

            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                final rawList = snap.data ?? [];
                final list = rawList.where((item) {
                  if (_query.isEmpty) return true;
                  final user = item['User'] is Map ? item['User'] as Map : const {};
                  final nama = (user['nama'] ?? item['nama'] ?? '').toString().toLowerCase();
                  final judul = (item['judul'] ?? '').toString().toLowerCase();
                  final isi = (item['isi_laporan'] ?? item['uraian_pekerjaan'] ?? '').toString().toLowerCase();
                  return nama.contains(_query) || judul.contains(_query) || isi.contains(_query);
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
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'TANGGAL',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'KARYAWAN',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(
                              'JUDUL LAPORAN',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              'RINGKASAN ISI',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'AKSI',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(
                            child: Text(
                              'Belum ada laporan harian yang sesuai filter.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = list[i];
                            final user = item['User'] is Map ? item['User'] as Map : const {};
                            final nama = (user['nama'] ?? item['nama'] ?? 'Karyawan').toString();
                            final tgl = (item['tanggal'] ?? '-').toString();
                            final judul = (item['judul'] ?? '-').toString();
                            final isi = (item['isi_laporan'] ?? item['uraian_pekerjaan'] ?? '-').toString();
                            final hasLampiran = item['lampiran'] != null && item['lampiran'].toString().isNotEmpty;

                            return InkWell(
                              onTap: () => _lihatDetailLaporan(item),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        tgl,
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: const Color(0xFFE0E7FF),
                                            child: Text(
                                              nama.isNotEmpty ? nama[0].toUpperCase() : 'K',
                                              style: const TextStyle(
                                                color: Color(0xFF4338CA),
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              nama,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              judul,
                                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryColor),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if (hasLampiran)
                                            const Padding(
                                              padding: EdgeInsets.only(left: 4),
                                              child: Icon(Icons.image_outlined, size: 16, color: Color(0xFF10B981)),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        isi,
                                        style: const TextStyle(color: Color(0xFF64748B)),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          IconButton(
                                            tooltip: 'Lihat Detail Laporan',
                                            icon: const Icon(Icons.visibility_outlined, size: 20, color: Color(0xFF4F5BA8)),
                                            onPressed: () => _lihatDetailLaporan(item),
                                          ),
                                          IconButton(
                                            tooltip: 'Edit Laporan (Admin Web)',
                                            icon: const Icon(Icons.edit_outlined, size: 20, color: Color(0xFF16A34A)),
                                            onPressed: () => _bukaEditLaporan(item),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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

class _EditLaporanDialog extends StatefulWidget {
  final Map<String, dynamic> laporan;

  const _EditLaporanDialog({required this.laporan});

  @override
  State<_EditLaporanDialog> createState() => _EditLaporanDialogState();
}

class _EditLaporanDialogState extends State<_EditLaporanDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tanggalCtrl;
  late final TextEditingController _judulCtrl;
  late final TextEditingController _jenisCtrl;
  late final TextEditingController _lokasiCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _luasCtrl;
  late final TextEditingController _uraianCtrl;
  late final TextEditingController _hasilCtrl;
  late final TextEditingController _rencanaCtrl;

  @override
  void initState() {
    super.initState();
    final l = widget.laporan;
    _tanggalCtrl = TextEditingController(text: l['tanggal']?.toString() ?? '');
    _judulCtrl = TextEditingController(text: l['judul']?.toString() ?? '');
    _jenisCtrl = TextEditingController(text: l['jenis_kegiatan']?.toString() ?? '');
    _lokasiCtrl = TextEditingController(text: l['lokasi']?.toString() ?? '');
    _unitCtrl = TextEditingController(text: l['unit_drone']?.toString() ?? '');
    _luasCtrl = TextEditingController(text: l['luas_area']?.toString() ?? '');
    _uraianCtrl = TextEditingController(text: (l['isi_laporan'] ?? l['uraian_pekerjaan'])?.toString() ?? '');
    _hasilCtrl = TextEditingController(text: l['hasil']?.toString() ?? '');
    _rencanaCtrl = TextEditingController(text: l['rencana_esok']?.toString() ?? '');
  }

  @override
  void dispose() {
    _tanggalCtrl.dispose();
    _judulCtrl.dispose();
    _jenisCtrl.dispose();
    _lokasiCtrl.dispose();
    _unitCtrl.dispose();
    _luasCtrl.dispose();
    _uraianCtrl.dispose();
    _hasilCtrl.dispose();
    _rencanaCtrl.dispose();
    super.dispose();
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    int maxLines = 1,
    bool required = false,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null
            : null,
      ),
    );
  }

  void _simpan() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, {
      'tanggal': _tanggalCtrl.text.trim(),
      'judul': _judulCtrl.text.trim(),
      'jenis_kegiatan': _jenisCtrl.text.trim(),
      'lokasi': _lokasiCtrl.text.trim(),
      'unit_drone': _unitCtrl.text.trim(),
      'luas_area': _luasCtrl.text.trim(),
      'isi_laporan': _uraianCtrl.text.trim(),
      'uraian_pekerjaan': _uraianCtrl.text.trim(),
      'hasil': _hasilCtrl.text.trim(),
      'rencana_esok': _rencanaCtrl.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Laporan (Admin Web)'),
      content: SizedBox(
        width: 520,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _field('Tanggal (YYYY-MM-DD)', _tanggalCtrl, required: true),
                _field('Judul laporan', _judulCtrl, required: true),
                _field('Jenis kegiatan', _jenisCtrl),
                _field('Lokasi / area', _lokasiCtrl),
                _field('Unit drone', _unitCtrl),
                _field('Luas area', _luasCtrl, hint: 'Contoh: 8 Ha'),
                _field('Uraian pekerjaan / isi laporan', _uraianCtrl, maxLines: 4, required: true),
                _field('Hasil pekerjaan', _hasilCtrl, maxLines: 3),
                _field('Rencana esok', _rencanaCtrl, maxLines: 3),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Foto dokumentasi yang sudah diunggah tetap dipertahankan.',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                  ),
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
          onPressed: _simpan,
          style: FilledButton.styleFrom(backgroundColor: AppConstants.primaryColor),
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}
