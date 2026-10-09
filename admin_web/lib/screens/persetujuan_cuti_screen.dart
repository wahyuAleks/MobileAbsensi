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

  @override
  void initState() {
    super.initState();
    _muat();
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
            content: Text(status == 'diterima' ? 'Pengajuan cuti disetujui' : 'Pengajuan cuti ditolak'),
            backgroundColor: status == 'diterima' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
          ),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
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
                const Text(
                  'Persetujuan & Manajemen Cuti Karyawan',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
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
            const SizedBox(height: 24),

            FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snap) {
                final list = snap.data ?? [];

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8, offset: const Offset(0, 2)),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Expanded(flex: 3, child: Text('KARYAWAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('JENIS CUTI', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 3, child: Text('PERIODE TANGGAL', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 3, child: Text('ALASAN / CATATAN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                          Expanded(flex: 2, child: Text('AKSI & STATUS', textAlign: TextAlign.right, style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12))),
                        ],
                      ),
                      const Divider(height: 24),
                      if (list.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(36),
                          child: Center(child: Text('Tidak ada pengajuan cuti saat ini.', style: TextStyle(color: Colors.grey))),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final item = list[i];
                            final user = item['User'] ?? {};
                            final nama = (user['nama'] ?? 'Karyawan').toString();
                            final jenis = (item['jenis_cuti'] ?? '-').toString();
                            final tglMulai = (item['tanggal_mulai'] ?? '-').toString();
                            final tglSelesai = (item['tanggal_selesai'] ?? '-').toString();
                            final alasan = (item['alasan'] ?? '-').toString();
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
                                          child: Text(nama.isNotEmpty ? nama[0].toUpperCase() : 'K', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                        const SizedBox(width: 10),
                                        Text(nama, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                  Expanded(flex: 2, child: Text(jenis, style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
                                  Expanded(flex: 3, child: Text('$tglMulai s/d $tglSelesai', style: const TextStyle(color: Color(0xFF475569)))),
                                  Expanded(flex: 3, child: Text(alasan, style: const TextStyle(color: Color(0xFF64748B)), maxLines: 2, overflow: TextOverflow.ellipsis)),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: status == 'menunggu'
                                          ? Row(
                                              mainAxisAlignment: MainAxisAlignment.end,
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
                                                  onPressed: () => _proses(item['id'], 'diterima'),
                                                  tooltip: 'Setujui Cuti',
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 24),
                                                  onPressed: () => _tolakCutiDialog(item),
                                                  tooltip: 'Tolak Cuti',
                                                ),
                                              ],
                                            )
                                          : Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: status == 'diterima' ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Text(
                                                status == 'diterima' ? 'Disetujui' : 'Ditolak',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: status == 'diterima' ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
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
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
