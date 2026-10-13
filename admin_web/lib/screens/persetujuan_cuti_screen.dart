import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import 'components/alasan_penolakan_dialog.dart';

class PersetujuanCutiScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaRekapAbsensi;
  final VoidCallback? onBukaProfil;

  const PersetujuanCutiScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaRekapAbsensi,
    this.onBukaProfil,
  });

  @override
  State<PersetujuanCutiScreen> createState() => _PersetujuanCutiScreenState();
}

class _PersetujuanCutiScreenState extends State<PersetujuanCutiScreen> {
  late Future<List<dynamic>> _future;
  String _activeFilter = 'semua'; // 'semua', 'menunggu', 'disetujui', 'ditolak'
  final TextEditingController _searchCtrl = TextEditingController();
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
      _future = ApiService.daftarPengajuanCuti();
    });
  }

  Future<void> _proses(int id, String status, {String? catatan}) async {
    try {
      await ApiService.prosesCuti(id, status, catatan: catatan);
      _muat();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(status == 'diterima'
                ? 'Pengajuan cuti disetujui'
                : 'Pengajuan cuti ditolak'),
            backgroundColor: status == 'diterima'
                ? const Color(0xFF16A34A)
                : const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }
  }

  Future<void> _tolakCutiDialog(Map<String, dynamic> item) async {
    final user = item['User'] ?? {};
    final nama = user['nama'] ?? 'Karyawan';
    final jenis = item['jenis_cuti'] ?? 'Cuti';

    final alasan = await AlasanPenolakanDialog.show(
      context,
      namaKaryawan: nama,
      jenisCuti: jenis,
    );

    if (alasan != null) {
      await _proses(item['id'], 'ditolak', catatan: alasan);
    }
  }

  Widget _buildSummaryCard(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _activeFilter = value),
      selectedColor: AppConstants.primaryColor,
      backgroundColor: Colors.white,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        fontSize: 13,
      ),
      side: BorderSide(
        color: isSelected ? AppConstants.primaryColor : const Color(0xFFCBD5E1),
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
                      'Persetujuan & Manajemen Cuti Karyawan',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kelola persetujuan atau penolakan pengajuan cuti secara real-time.',
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

            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                final rawList = snap.data ?? [];

                int totalCount = rawList.length;
                int menungguCount = 0;
                int disetujuiCount = 0;
                int ditolakCount = 0;

                for (final item in rawList) {
                  final status = (item['status'] ?? '').toString().toLowerCase();
                  if (status == 'menunggu' || status == 'pending') {
                    menungguCount++;
                  } else if (status == 'diterima' || status == 'disetujui') {
                    disetujuiCount++;
                  } else if (status == 'ditolak') {
                    ditolakCount++;
                  }
                }

                final filteredList = rawList.where((item) {
                  final status = (item['status'] ?? '').toString().toLowerCase();
                  if (_activeFilter == 'menunggu' && status != 'menunggu' && status != 'pending') return false;
                  if (_activeFilter == 'disetujui' && status != 'diterima' && status != 'disetujui') return false;
                  if (_activeFilter == 'ditolak' && status != 'ditolak') return false;

                  if (_query.isNotEmpty) {
                    final user = item['User'] is Map ? item['User'] as Map : const {};
                    final nama = (user['nama'] ?? 'Karyawan').toString().toLowerCase();
                    final jenis = (item['jenis_cuti'] ?? '').toString().toLowerCase();
                    final alasan = (item['alasan'] ?? '').toString().toLowerCase();
                    return nama.contains(_query) || jenis.contains(_query) || alasan.contains(_query);
                  }
                  return true;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Metric Summary Cards
                    Row(
                      children: [
                        _buildSummaryCard('Total Pengajuan', totalCount, const Color(0xFF3B82F6), Icons.assignment_outlined),
                        const SizedBox(width: 14),
                        _buildSummaryCard('Menunggu', menungguCount, const Color(0xFFF59E0B), Icons.hourglass_top_rounded),
                        const SizedBox(width: 14),
                        _buildSummaryCard('Disetujui', disetujuiCount, const Color(0xFF10B981), Icons.check_circle_outline),
                        const SizedBox(width: 14),
                        _buildSummaryCard('Ditolak', ditolakCount, const Color(0xFFEF4444), Icons.cancel_outlined),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Filter Chips & Search Bar
                    Row(
                      children: [
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildFilterChip('Semua ($totalCount)', 'semua'),
                            _buildFilterChip('Menunggu ($menungguCount)', 'menunggu'),
                            _buildFilterChip('Disetujui ($disetujuiCount)', 'disetujui'),
                            _buildFilterChip('Ditolak ($ditolakCount)', 'ditolak'),
                          ],
                        ),
                        const Spacer(),
                        SizedBox(
                          width: 320,
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Cari karyawan / alasan...',
                              prefixIcon: const Icon(Icons.search, size: 18),
                              suffixIcon: _query.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear, size: 16),
                                      onPressed: () {
                                        _searchCtrl.clear();
                                        setState(() => _query = '');
                                      },
                                    )
                                  : null,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            onChanged: (val) => setState(() => _query = val.trim().toLowerCase()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Table Container
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
                                flex: 3,
                                child: Text('KARYAWAN',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('JENIS CUTI',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('PERIODE TANGGAL',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text('ALASAN & CATATAN',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('AKSI & STATUS',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          if (filteredList.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(36),
                              child: Center(
                                child: Text(
                                  'Tidak ada pengajuan cuti yang sesuai filter.',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredList.length,
                              separatorBuilder: (_, __) => const Divider(height: 1),
                              itemBuilder: (context, i) {
                                final item = filteredList[i];
                                final user = item['User'] is Map ? item['User'] as Map : const {};
                                final nama = (user['nama'] ?? 'Karyawan').toString();
                                final jenis = (item['jenis_cuti'] ?? '-').toString();
                                final tglMulai = (item['tanggal_mulai'] ?? '-').toString();
                                final tglSelesai = (item['tanggal_selesai'] ?? '-').toString();
                                final alasan = (item['alasan'] ?? '-').toString();
                                final catatan = item['catatan']?.toString();
                                final status = (item['status'] ?? 'menunggu').toString().toLowerCase();

                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 3,
                                        child: Row(
                                          children: [
                                            CircleAvatar(
                                              radius: 16,
                                              backgroundColor: AppConstants.primaryColor,
                                              child: Text(
                                                nama.isNotEmpty ? nama[0].toUpperCase() : 'K',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                nama,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0F172A),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          jenis,
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Text(
                                          '$tglMulai s/d $tglSelesai',
                                          style: const TextStyle(color: Color(0xFF475569)),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 3,
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              alasan,
                                              style: const TextStyle(color: Color(0xFF1F2937)),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (catatan != null && catatan.isNotEmpty)
                                              Padding(
                                                padding: const EdgeInsets.only(top: 2),
                                                child: Text(
                                                  'Alasan penolakan: $catatan',
                                                  style: const TextStyle(
                                                    color: Color(0xFFDC2626),
                                                    fontSize: 11.5,
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: (status == 'menunggu' || status == 'pending')
                                              ? Row(
                                                  mainAxisAlignment: MainAxisAlignment.end,
                                                  children: [
                                                    FilledButton.icon(
                                                      icon: const Icon(Icons.check, size: 14),
                                                      label: const Text('Setujui', style: TextStyle(fontSize: 12)),
                                                      style: FilledButton.styleFrom(
                                                        backgroundColor: const Color(0xFF16A34A),
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      ),
                                                      onPressed: () => _proses(item['id'], 'diterima'),
                                                    ),
                                                    const SizedBox(width: 6),
                                                    OutlinedButton.icon(
                                                      icon: const Icon(Icons.close, size: 14, color: Color(0xFFDC2626)),
                                                      label: const Text('Tolak', style: TextStyle(fontSize: 12, color: Color(0xFFDC2626))),
                                                      style: OutlinedButton.styleFrom(
                                                        side: const BorderSide(color: Color(0xFFDC2626)),
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                      ),
                                                      onPressed: () => _tolakCutiDialog(item),
                                                    ),
                                                  ],
                                                )
                                              : Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: (status == 'diterima' || status == 'disetujui')
                                                        ? const Color(0xFFDCFCE7)
                                                        : const Color(0xFFFEE2E2),
                                                    borderRadius: BorderRadius.circular(10),
                                                  ),
                                                  child: Text(
                                                    (status == 'diterima' || status == 'disetujui')
                                                        ? 'Disetujui'
                                                        : 'Ditolak',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                      color: (status == 'diterima' || status == 'disetujui')
                                                          ? const Color(0xFF16A34A)
                                                          : const Color(0xFFDC2626),
                                                    ),
                                                  ),
                                                ),
                                        ),
                                      ),
                                    ],
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
