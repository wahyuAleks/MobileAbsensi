import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/file_download_helper.dart';

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

  // Filter state
  String _selectedProject = 'Semua Project';
  String _selectedLokasi = 'Semua Lokasi';
  List<String> _masterProjects = [];
  List<String> _masterLocations = [];

  @override
  void initState() {
    super.initState();
    _muat();
    _muatFilterMasters();
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

  Future<void> _muatFilterMasters() async {
    try {
      final results = await Future.wait([
        ApiService.jenisKegiatan(),
        ApiService.daftarLokasi(),
      ]);
      final rawProjects = results[0];
      final rawLocations = results[1];

      final projects = rawProjects
          .whereType<Map>()
          .map((m) => (m['nama'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final locations = rawLocations
          .whereType<Map>()
          .map((m) => (m['nama'] ?? '').toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();

      if (mounted) {
        setState(() {
          _masterProjects = projects;
          _masterLocations = locations;
        });
      }
    } catch (_) {}
  }

  void _resetFilter() {
    setState(() {
      _searchCtrl.clear();
      _query = '';
      _selectedProject = 'Semua Project';
      _selectedLokasi = 'Semua Lokasi';
    });
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  void _exportExcel(List<dynamic> items) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada data laporan untuk diekspor.'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('<html xmlns:o="urn:schemas-microsoft-com:office:office" '
        'xmlns:x="urn:schemas-microsoft-com:office:excel" '
        'xmlns="http://www.w3.org/TR/REC-html40">');
    buffer.writeln('<head>');
    buffer.writeln(
        '<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />');
    buffer.writeln('<!--[if gte mso 9]><xml><x:ExcelWorkbook><x:ExcelWorksheets>'
        '<x:ExcelWorksheet><x:Name>Rekap Laporan</x:Name>'
        '<x:WorksheetOptions><x:DisplayGridlines/></x:WorksheetOptions>'
        '</x:ExcelWorksheet></x:ExcelWorksheets></x:ExcelWorkbook></xml><![endif]-->');
    buffer.writeln('<style>');
    buffer.writeln(
        'body { font-family: Calibri, Arial, sans-serif; font-size: 11pt; }');
    buffer.writeln(
        '.title { font-size: 16pt; font-weight: bold; color: #1E3A8A; margin-bottom: 4px; }');
    buffer.writeln(
        '.meta { font-size: 10pt; color: #475569; margin-bottom: 12px; }');
    buffer.writeln('table { border-collapse: collapse; width: 100%; }');
    buffer.writeln(
        'th { background-color: #2563EB; color: #FFFFFF; font-weight: bold; border: 1px solid #1E40AF; padding: 10px 8px; text-align: center; }');
    buffer.writeln(
        'td { border: 1px solid #CBD5E1; padding: 6px 8px; vertical-align: top; }');
    buffer.writeln('.center { text-align: center; }');
    buffer.writeln('tr:nth-child(even) { background-color: #F8FAFC; }');
    buffer.writeln('</style>');
    buffer.writeln('</head>');
    buffer.writeln('<body>');
    buffer.writeln(
        '<div class="title">REKAPITULASI LAPORAN HARIAN KARYAWAN</div>');

    final filterInfo = [
      if (_selectedProject != 'Semua Project') 'Project: $_selectedProject',
      if (_selectedLokasi != 'Semua Lokasi') 'Lokasi: $_selectedLokasi',
    ].join(' | ');

    buffer.writeln(
        '<div class="meta">Waktu Export: ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())} WIB '
        '| Total: ${items.length} Laporan ${filterInfo.isNotEmpty ? "($filterInfo)" : ""}</div>');
    buffer.writeln('<table>');
    buffer.writeln('<thead>');
    buffer.writeln('<tr>');
    buffer.writeln('<th>No</th>');
    buffer.writeln('<th>Tanggal</th>');
    buffer.writeln('<th>Nama Karyawan</th>');
    buffer.writeln('<th>Jabatan</th>');
    buffer.writeln('<th>Project / Jenis Kegiatan</th>');
    buffer.writeln('<th>Lokasi</th>');
    buffer.writeln('<th>Unit Drone</th>');
    buffer.writeln('<th>Luas Area</th>');
    buffer.writeln('<th>Judul Laporan</th>');
    buffer.writeln('<th>Ringkasan / Uraian Pekerjaan</th>');
    buffer.writeln('<th>Hasil Pekerjaan</th>');
    buffer.writeln('<th>Rencana Esok</th>');
    buffer.writeln('<th>Status</th>');
    buffer.writeln('<th>Dokumentasi Foto</th>');
    buffer.writeln('</tr>');
    buffer.writeln('</thead>');
    buffer.writeln('<tbody>');

    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final user = item['User'] is Map ? item['User'] as Map : const {};
      final nama =
          _escapeXml((user['nama'] ?? item['nama'] ?? 'Karyawan').toString());
      final jabatan = _escapeXml((user['jabatan'] ?? '-').toString());
      final tgl = _escapeXml((item['tanggal'] ?? '-').toString());
      final project = _escapeXml((item['jenis_kegiatan'] ?? '-').toString());
      final lokasi = _escapeXml((item['lokasi'] ?? '-').toString());
      final unitDrone = _escapeXml((item['unit_drone'] ?? '-').toString());
      final luasArea = _escapeXml((item['luas_area'] ?? '-').toString());
      final judul = _escapeXml((item['judul'] ?? '-').toString());
      final isi = _escapeXml(
          (item['isi_laporan'] ?? item['uraian_pekerjaan'] ?? '-').toString());
      final hasil = _escapeXml((item['hasil'] ?? '-').toString());
      final rencanaEsok = _escapeXml((item['rencana_esok'] ?? '-').toString());
      final status = _escapeXml((item['status'] ?? 'Terkirim').toString());

      String fotoInfo = '-';
      final lampiranRaw = item['lampiran']?.toString();
      if (lampiranRaw != null && lampiranRaw.isNotEmpty) {
        if (lampiranRaw.startsWith('[')) {
          try {
            final decoded = jsonDecode(lampiranRaw) as List;
            fotoInfo = '${decoded.length} foto';
          } catch (_) {
            fotoInfo = '1 foto';
          }
        } else {
          fotoInfo = '1 foto';
        }
      }

      buffer.writeln('<tr>');
      buffer.writeln('<td class="center">${i + 1}</td>');
      buffer.writeln('<td class="center">$tgl</td>');
      buffer.writeln('<td>$nama</td>');
      buffer.writeln('<td>$jabatan</td>');
      buffer.writeln('<td>$project</td>');
      buffer.writeln('<td>$lokasi</td>');
      buffer.writeln('<td>$unitDrone</td>');
      buffer.writeln('<td class="center">$luasArea</td>');
      buffer.writeln('<td><b>$judul</b></td>');
      buffer.writeln('<td>$isi</td>');
      buffer.writeln('<td>$hasil</td>');
      buffer.writeln('<td>$rencanaEsok</td>');
      buffer.writeln('<td class="center">$status</td>');
      buffer.writeln('<td class="center">$fotoInfo</td>');
      buffer.writeln('</tr>');
    }

    buffer.writeln('</tbody>');
    buffer.writeln('</table>');
    buffer.writeln('</body>');
    buffer.writeln('</html>');

    final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'Rekap_Laporan_$nowStr.xls';
    FileDownloadHelper.downloadString(
      content: buffer.toString(),
      fileName: fileName,
      mimeType: 'application/vnd.ms-excel;charset=utf-8',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Berhasil mengekspor ${items.length} laporan ke file $fileName'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF107C41),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _exportCsv(List<dynamic> items) {
    if (items.isEmpty) return;
    final buffer = StringBuffer();
    // UTF-8 BOM
    buffer.write('\uFEFF');
    buffer.writeln(
        'No,Tanggal,Nama Karyawan,Jabatan,Project / Jenis Kegiatan,Lokasi,Unit Drone,Luas Area,Judul Laporan,Uraian Pekerjaan,Hasil Pekerjaan,Rencana Esok,Status,Dokumentasi Foto');
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      final user = item['User'] is Map ? item['User'] as Map : const {};
      final row = [
        '${i + 1}',
        (item['tanggal'] ?? '-').toString(),
        (user['nama'] ?? item['nama'] ?? 'Karyawan').toString(),
        (user['jabatan'] ?? '-').toString(),
        (item['jenis_kegiatan'] ?? '-').toString(),
        (item['lokasi'] ?? '-').toString(),
        (item['unit_drone'] ?? '-').toString(),
        (item['luas_area'] ?? '-').toString(),
        (item['judul'] ?? '-').toString(),
        (item['isi_laporan'] ?? item['uraian_pekerjaan'] ?? '-')
            .toString()
            .replaceAll('\n', ' '),
        (item['hasil'] ?? '-').toString().replaceAll('\n', ' '),
        (item['rencana_esok'] ?? '-').toString().replaceAll('\n', ' '),
        (item['status'] ?? 'Terkirim').toString(),
        item['lampiran'] != null ? 'Ada' : 'Tidak Ada',
      ].map((cell) => '"${cell.replaceAll('"', '""')}"').join(',');
      buffer.writeln(row);
    }
    final nowStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final fileName = 'Rekap_Laporan_$nowStr.csv';
    FileDownloadHelper.downloadString(
      content: buffer.toString(),
      fileName: fileName,
      mimeType: 'text/csv;charset=utf-8',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Berhasil mengekspor ${items.length} laporan ke file $fileName'),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF107C41),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengedit laporan: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
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
    final isi =
        (item['isi_laporan'] ?? item['uraian_pekerjaan'] ?? '-').toString();
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
            const Icon(Icons.description_outlined,
                color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                judul,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
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
                    const Icon(Icons.person_outline,
                        size: 16, color: Color(0xFF4F5BA8)),
                    const SizedBox(width: 6),
                    Text(
                      nama,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined,
                        size: 16, color: Color(0xFF6B7280)),
                    const SizedBox(width: 6),
                    Text(
                      tgl,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF6B7280)),
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
                        label:
                            Text(jenis, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                    if (lokasi != null && lokasi.isNotEmpty)
                      Chip(
                        avatar:
                            const Icon(Icons.location_on_outlined, size: 14),
                        label:
                            Text(lokasi, style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                    if (unitDrone != null && unitDrone.isNotEmpty)
                      Chip(
                        avatar: const Icon(Icons.flight_outlined, size: 14),
                        label: Text('Drone: $unitDrone',
                            style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                    if (luasArea != null && luasArea.isNotEmpty)
                      Chip(
                        avatar:
                            const Icon(Icons.crop_square_outlined, size: 14),
                        label: Text('Luas: $luasArea',
                            style: const TextStyle(fontSize: 12)),
                        padding: EdgeInsets.zero,
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(height: 1),
                const SizedBox(height: 14),
                const Text(
                  'Uraian Pekerjaan / Isi Laporan:',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF374151)),
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
                    style: const TextStyle(
                        fontSize: 13, height: 1.5, color: Color(0xFF1F2937)),
                  ),
                ),
                if (hasil != null && hasil.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Hasil Pekerjaan:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 6),
                  Text(hasil,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4B5563))),
                ],
                if (rencanaEsok != null && rencanaEsok.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Rencana Esok:',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF374151)),
                  ),
                  const SizedBox(height: 6),
                  Text(rencanaEsok,
                      style: const TextStyle(
                          fontSize: 13, color: Color(0xFF4B5563))),
                ],
                if (lampiranList.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text(
                        'Dokumentasi Kegiatan Lapangan:',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF374151)),
                      ),
                      const Spacer(),
                      if (lampiranList.length > 1)
                        Text(
                          '${lampiranList.length} foto',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF9CA3AF)),
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
                          child:
                              const Text('Foto dokumentasi tidak dapat dimuat.'),
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
                          onTap: url == null
                              ? null
                              : () => _tampilkanFotoPenuh(ctx, url),
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
                                          child: Icon(
                                              Icons.broken_image_outlined,
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
            style: FilledButton.styleFrom(
                backgroundColor: AppConstants.primaryColor),
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

  Widget _buildFilterDropdown({
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required Color iconColor,
    required String hintText,
  }) {
    final bool isFiltered = value != items.first;
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isFiltered ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFiltered ? const Color(0xFF16A34A) : const Color(0xFFCBD5E1),
          width: isFiltered ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: items.contains(value) ? value : items.first,
          isDense: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B), size: 20),
          items: items.map((opt) {
            final isDefault = opt == items.first;
            return DropdownMenuItem<String>(
              value: opt,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isDefault ? Icons.filter_list_rounded : icon,
                    size: 16,
                    color: isDefault ? const Color(0xFF94A3B8) : iconColor,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      opt,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight:
                            isDefault ? FontWeight.normal : FontWeight.w600,
                        color: isDefault
                            ? const Color(0xFF475569)
                            : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          onChanged: onChanged,
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
            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                final rawList = snap.data ?? [];

                // Master project list (from DB + reports)
                final Set<String> projectSet = {'Semua Project'};
                projectSet.addAll(_masterProjects);
                for (final item in rawList) {
                  final p = (item['jenis_kegiatan'] ?? '').toString().trim();
                  if (p.isNotEmpty) projectSet.add(p);
                }
                final projectList = projectSet.toList();

                // Master lokasi list (from DB + reports)
                final Set<String> lokasiSet = {'Semua Lokasi'};
                lokasiSet.addAll(_masterLocations);
                for (final item in rawList) {
                  final l = (item['lokasi'] ?? '').toString().trim();
                  if (l.isNotEmpty) lokasiSet.add(l);
                }
                final lokasiList = lokasiSet.toList();

                // Filtered list
                final list = rawList.where((item) {
                  // 1. Filter Project
                  if (_selectedProject != 'Semua Project') {
                    final jk = (item['jenis_kegiatan'] ?? '')
                        .toString()
                        .trim()
                        .toLowerCase();
                    final target = _selectedProject.trim().toLowerCase();
                    if (!jk.contains(target) && !target.contains(jk)) {
                      return false;
                    }
                  }

                  // 2. Filter Lokasi
                  if (_selectedLokasi != 'Semua Lokasi') {
                    final lok =
                        (item['lokasi'] ?? '').toString().trim().toLowerCase();
                    final target = _selectedLokasi.trim().toLowerCase();
                    if (!lok.contains(target) && !target.contains(lok)) {
                      return false;
                    }
                  }

                  // 3. Search Query
                  if (_query.isNotEmpty) {
                    final user =
                        item['User'] is Map ? item['User'] as Map : const {};
                    final nama = (user['nama'] ?? item['nama'] ?? '')
                        .toString()
                        .toLowerCase();
                    final judul = (item['judul'] ?? '').toString().toLowerCase();
                    final isi =
                        (item['isi_laporan'] ?? item['uraian_pekerjaan'] ?? '')
                            .toString()
                            .toLowerCase();
                    final lok =
                        (item['lokasi'] ?? '').toString().toLowerCase();
                    final jk =
                        (item['jenis_kegiatan'] ?? '').toString().toLowerCase();
                    final match = nama.contains(_query) ||
                        judul.contains(_query) ||
                        isi.contains(_query) ||
                        lok.contains(_query) ||
                        jk.contains(_query);
                    if (!match) return false;
                  }

                  return true;
                }).toList();

                final bool isAnyFilterActive = _selectedProject != 'Semua Project' ||
                    _selectedLokasi != 'Semua Lokasi' ||
                    _query.isNotEmpty;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Header & Action Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                              'Pantau dokumentasi, filter per project & lokasi, serta ekspor rekap ke Excel.',
                              style: TextStyle(
                                  fontSize: 13, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _muat,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Refresh Data'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppConstants.primaryColor,
                                side: const BorderSide(
                                    color: AppConstants.primaryColor),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                            // Menu Export Excel & CSV
                            PopupMenuButton<String>(
                              tooltip: 'Pilih format ekspor data laporan',
                              onSelected: (val) {
                                if (val == 'excel') {
                                  _exportExcel(list);
                                } else if (val == 'csv') {
                                  _exportCsv(list);
                                }
                              },
                              itemBuilder: (ctx) => [
                                const PopupMenuItem(
                                  value: 'excel',
                                  child: Row(
                                    children: [
                                      Icon(Icons.table_view_rounded,
                                          color: Color(0xFF107C41), size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Ekspor ke Excel (.xls)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'csv',
                                  child: Row(
                                    children: [
                                      Icon(Icons.insert_drive_file_outlined,
                                          color: Color(0xFF2563EB), size: 20),
                                      SizedBox(width: 10),
                                      Text(
                                        'Ekspor ke CSV (.csv)',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 11),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF107C41),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF107C41)
                                          .withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.file_download_rounded,
                                        color: Colors.white, size: 18),
                                    SizedBox(width: 8),
                                    Text(
                                      'Export ke Excel',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(Icons.arrow_drop_down,
                                        color: Colors.white, size: 20),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Filter Bar: Search + 2 Filter Dropdowns (Per Project & Per Lokasi)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // 1. Search Bar
                              Expanded(
                                flex: 3,
                                child: Container(
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xFFCBD5E1)),
                                  ),
                                  child: TextField(
                                    controller: _searchCtrl,
                                    decoration: InputDecoration(
                                      hintText:
                                          'Cari karyawan, judul, atau kegiatan...',
                                      hintStyle: const TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFF94A3B8)),
                                      prefixIcon: const Icon(Icons.search,
                                          color: Color(0xFF94A3B8), size: 20),
                                      suffixIcon: _query.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(
                                                  Icons.clear_rounded,
                                                  size: 18),
                                              onPressed: () {
                                                _searchCtrl.clear();
                                                setState(() => _query = '');
                                              },
                                            )
                                          : null,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                    ),
                                    onChanged: (val) => setState(
                                        () => _query = val.trim().toLowerCase()),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 2. Filter Per Project Dropdown
                              _buildFilterDropdown(
                                value: _selectedProject,
                                items: projectList,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedProject = val);
                                  }
                                },
                                icon: Icons.work_outline_rounded,
                                iconColor: AppConstants.primaryColor,
                                hintText: 'Pilih Project',
                              ),
                              const SizedBox(width: 12),

                              // 3. Filter Per Lokasi Dropdown
                              _buildFilterDropdown(
                                value: _selectedLokasi,
                                items: lokasiList,
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _selectedLokasi = val);
                                  }
                                },
                                icon: Icons.location_on_rounded,
                                iconColor: const Color(0xFFEA580C),
                                hintText: 'Pilih Lokasi',
                              ),

                              if (isAnyFilterActive) ...[
                                const SizedBox(width: 12),
                                OutlinedButton.icon(
                                  onPressed: _resetFilter,
                                  icon: const Icon(Icons.filter_alt_off_rounded,
                                      size: 16),
                                  label: const Text('Reset'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFFDC2626),
                                    side: const BorderSide(
                                        color: Color(0xFFFCA5A5)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 11),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                ),
                              ],
                            ],
                          ),

                          // Active Filter Badges & Count
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                'Menampilkan ${list.length} dari ${rawList.length} laporan',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF475569),
                                ),
                              ),
                              if (isAnyFilterActive) ...[
                                const SizedBox(width: 12),
                                if (_selectedProject != 'Semua Project') ...[
                                  Chip(
                                    avatar: const Icon(
                                        Icons.work_outline_rounded,
                                        size: 14,
                                        color: AppConstants.primaryColor),
                                    label: Text('Project: $_selectedProject',
                                        style: const TextStyle(fontSize: 11)),
                                    onDeleted: () => setState(() =>
                                        _selectedProject = 'Semua Project'),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (_selectedLokasi != 'Semua Lokasi') ...[
                                  Chip(
                                    avatar: const Icon(Icons.location_on_rounded,
                                        size: 14,
                                        color: Color(0xFFEA580C)),
                                    label: Text('Lokasi: $_selectedLokasi',
                                        style: const TextStyle(fontSize: 11)),
                                    onDeleted: () => setState(() =>
                                        _selectedLokasi = 'Semua Lokasi'),
                                    padding: EdgeInsets.zero,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  const SizedBox(width: 6),
                                ],
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Table Container
                    if (snap.connectionState == ConnectionState.waiting)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      Container(
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
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                        fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'KARYAWAN',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                        fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'PROJECT / LOKASI',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                        fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'JUDUL LAPORAN',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                        fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'RINGKASAN ISI',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                        fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    'AKSI',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF64748B),
                                        fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            if (list.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(36),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Icon(Icons.search_off_rounded,
                                          size: 40, color: Color(0xFF94A3B8)),
                                      const SizedBox(height: 10),
                                      const Text(
                                        'Belum ada laporan harian yang sesuai filter.',
                                        style: TextStyle(
                                            color: Color(0xFF64748B),
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      if (isAnyFilterActive) ...[
                                        const SizedBox(height: 8),
                                        TextButton(
                                          onPressed: _resetFilter,
                                          child: const Text('Reset Filter'),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: list.length,
                                separatorBuilder: (_, __) =>
                                    const Divider(height: 1),
                                itemBuilder: (context, i) {
                                  final item = list[i];
                                  final user = item['User'] is Map
                                      ? item['User'] as Map
                                      : const {};
                                  final nama = (user['nama'] ??
                                          item['nama'] ??
                                          'Karyawan')
                                      .toString();
                                  final tgl =
                                      (item['tanggal'] ?? '-').toString();
                                  final judul =
                                      (item['judul'] ?? '-').toString();
                                  final project =
                                      (item['jenis_kegiatan'] ?? '-').toString();
                                  final lokasi =
                                      (item['lokasi'] ?? '-').toString();
                                  final isi = (item['isi_laporan'] ??
                                          item['uraian_pekerjaan'] ??
                                          '-')
                                      .toString();
                                  final hasLampiran = item['lampiran'] != null &&
                                      item['lampiran'].toString().isNotEmpty;

                                  return InkWell(
                                    onTap: () => _lihatDetailLaporan(item),
                                    borderRadius: BorderRadius.circular(8),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 10, horizontal: 4),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: Text(
                                              tgl,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF475569)),
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 14,
                                                  backgroundColor:
                                                      const Color(0xFFE0E7FF),
                                                  child: Text(
                                                    nama.isNotEmpty
                                                        ? nama[0].toUpperCase()
                                                        : 'K',
                                                    style: const TextStyle(
                                                      color: Color(0xFF4338CA),
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    nama,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Color(0xFF0F172A)),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  project,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                    color: Color(0xFF1E293B),
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                const SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .location_on_rounded,
                                                        size: 11,
                                                        color:
                                                            Color(0xFFEA580C)),
                                                    const SizedBox(width: 3),
                                                    Expanded(
                                                      child: Text(
                                                        lokasi,
                                                        style: const TextStyle(
                                                            fontSize: 11,
                                                            color: Color(
                                                                0xFF64748B)),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                      ),
                                                    ),
                                                  ],
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
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: AppConstants
                                                            .primaryColor),
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                                if (hasLampiran)
                                                  const Padding(
                                                    padding: EdgeInsets.only(
                                                        left: 4),
                                                    child: Icon(
                                                        Icons.image_outlined,
                                                        size: 16,
                                                        color:
                                                            Color(0xFF10B981)),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          Expanded(
                                            flex: 3,
                                            child: Text(
                                              isi,
                                              style: const TextStyle(
                                                  color: Color(0xFF64748B)),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          Expanded(
                                            flex: 2,
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  tooltip:
                                                      'Lihat Detail Laporan',
                                                  icon: const Icon(
                                                      Icons.visibility_outlined,
                                                      size: 20,
                                                      color: Color(0xFF4F5BA8)),
                                                  onPressed: () =>
                                                      _lihatDetailLaporan(item),
                                                ),
                                                IconButton(
                                                  tooltip:
                                                      'Edit Laporan (Admin Web)',
                                                  icon: const Icon(
                                                      Icons.edit_outlined,
                                                      size: 20,
                                                      color: Color(0xFF16A34A)),
                                                  onPressed: () =>
                                                      _bukaEditLaporan(item),
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
                      ),
                  ],
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
    _jenisCtrl =
        TextEditingController(text: l['jenis_kegiatan']?.toString() ?? '');
    _lokasiCtrl = TextEditingController(text: l['lokasi']?.toString() ?? '');
    _unitCtrl = TextEditingController(text: l['unit_drone']?.toString() ?? '');
    _luasCtrl = TextEditingController(text: l['luas_area']?.toString() ?? '');
    _uraianCtrl = TextEditingController(
        text: (l['isi_laporan'] ?? l['uraian_pekerjaan'])?.toString() ?? '');
    _hasilCtrl = TextEditingController(text: l['hasil']?.toString() ?? '');
    _rencanaCtrl =
        TextEditingController(text: l['rencana_esok']?.toString() ?? '');
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
            ? (value) =>
                value == null || value.trim().isEmpty ? 'Wajib diisi' : null
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
                _field('Uraian pekerjaan / isi laporan', _uraianCtrl,
                    maxLines: 4, required: true),
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
          style:
              FilledButton.styleFrom(backgroundColor: AppConstants.primaryColor),
          child: const Text('Simpan Perubahan'),
        ),
      ],
    );
  }
}
