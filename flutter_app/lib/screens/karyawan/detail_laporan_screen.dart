import 'dart:convert';
import 'package:flutter/material.dart';
import '../../core/constants.dart';

/// Halaman Detail Laporan Karyawan
/// Dibuat persis 100% sesuai screenshot desain Figma yang dikirimkan user:
/// 1. Top bar: Tombol back lingkaran ungu navy (#4F5BA8) + Judul "Detail Laporan" + Divider halus
/// 2. Kartu 1: Metadata Ringkasan
///    - Judul tanggal & Status badge "Terkirim"
///    - Jenis Kegiatan, Lokasi, Unit Drone, Luas Area
/// 3. Kartu 2: URAIAN PEKERJAAN
/// 4. Kartu 3: Hasil & Rencana
///    - Subbagian "Hasil"
///    - Subbagian "Rencana Esok:"
class DetailLaporanScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onBack;

  const DetailLaporanScreen({
    super.key,
    required this.item,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Ambil field dinamis dengan fallback ke data default persis screenshot Figma
    final tanggal = item['tanggal']?.toString() ?? '17 Agustus 2026';
    final status = item['status']?.toString() ?? 'Terkirim';
    final jenisKegiatan = item['jenis_kegiatan']?.toString() ??
        _inferJenisKegiatan(item['judul']?.toString() ?? '');
    final lokasi = item['lokasi']?.toString() ??
        _inferLokasi(item['judul']?.toString() ?? '');
    final unitDrone = item['unit_drone']?.toString() ?? 'DA-001 (DJI Agras T40)';
    final luasArea = item['luas_area']?.toString() ??
        _inferLuasArea(item['judul']?.toString() ?? '');

    final uraian = (item['uraian_pekerjaan'] ?? item['isi_laporan'] ?? '')
        .toString()
        .trim();
    final uraianText = uraian.isNotEmpty
        ? uraian
        : 'Penyemprotan pestisida dilakukan pada lahan Blok A seluas 8 Ha. Drone DA-001 beroperasi dari pukul 07.00 – 11.30. Seluruh area berhasil disemprot dengan dosis sesuai anjuran.';

    final hasil = item['hasil']?.toString() ??
        'Penyemprotan 100% selesai. Tidak ada kendala signifikan.';
    final rencanaEsok = item['rencana_esok']?.toString() ??
        'Penyemprotan Blok B — 5 Ha dengan drone DA-002.';
    // Parse lampiran: JSON array (multi-photo) or plain string (single)
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

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && onBack != null) {
          onBack!();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP BAR: Back Button + Title
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
                    // Lingkaran Tombol Back Biru-Ungu
                    InkWell(
                      onTap: () {
                        if (onBack != null) {
                          onBack!();
                        } else if (Navigator.canPop(context)) {
                          Navigator.pop(context);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFF4F5BA8),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Teks Judul
                    const Text(
                      'Detail Laporan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),
              ),

              // Divider Halus Membentang Penuh
              const Divider(
                height: 1,
                thickness: 1,
                color: Color(0xFFE5E7EB),
              ),

              // 2. KONTEN KARTU-KARTU DETAIL LAPORAN
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // KARTU 1: METADATA RINGKASAN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Baris Judul Tanggal & Status Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Laporan $tanggal',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFAFC0A4),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  status,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF385630),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Baris Data Key-Value
                          _buildDetailRow('Jenis Kegiatan', jenisKegiatan),
                          _buildDetailRow('Lokasi', lokasi),
                          _buildDetailRow('Unit Drone', unitDrone),
                          _buildDetailRow('Luas Area', luasArea),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KARTU 2: URAIAN PEKERJAAN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'URAIAN PEKERJAAN',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            uraianText,
                            style: const TextStyle(
                              fontSize: 13.5,
                              color: Color(0xFF111827),
                              height: 1.45,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // KARTU 3: HASIL & RENCANA
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F3F3),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Hasil & Rencana',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Subbagian Hasil
                          const Text(
                            'Hasil',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasil,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                              height: 1.35,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Subbagian Rencana Esok:
                          const Text(
                            'Rencana Esok:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            rencanaEsok,
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF111827),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (lampiranList.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F3),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'DOKUMENTASI KEGIATAN LAPANGAN',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF6B7280),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const Spacer(),
                                if (lampiranList.length > 1)
                                  Text(
                                    '${lampiranList.length} foto',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            if (lampiranList.length == 1)
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  AppConstants.getImageUrl(lampiranList.first)!,
                                width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                        'Foto dokumentasi tidak dapat dimuat.'),
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
                                    onTap: () => _tampilkanFotoPenuh(context, url),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: url != null
                                          ? Image.network(
                                              url,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  const SizedBox(
                                                width: 100,
                                                height: 100,
                                                child: Center(
                                                  child: Icon(
                                                      Icons
                                                          .broken_image_outlined,
                                                      color:
                                                          Color(0xFF9CA3AF)),
                                                ),
                                              ),
                                            )
                                          : const SizedBox(
                                              width: 100,
                                              height: 100,
                                              child: Center(
                                                child: Icon(
                                                    Icons.broken_image_outlined,
                                                    color: Color(0xFF9CA3AF)),
                                              ),
                                            ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _tampilkanFotoPenuh(BuildContext context, String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
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
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13.5,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _inferJenisKegiatan(String judul) {
    final lower = judul.toLowerCase();
    if (lower.contains('pestisida')) return 'Penyemprotan Pestisida';
    if (lower.contains('pupuk')) return 'Penyebaran Pupuk Urea';
    if (lower.contains('pemetaan') || lower.contains('survei')) {
      return 'Survei dan Pemetaan Lahan';
    }
    if (lower.contains('rutin') || lower.contains('pemeliharaan')) {
      return 'Pemeliharaan Rutin Drone';
    }
    return 'Penyemprotan Pestisida';
  }

  static String _inferLokasi(String judul) {
    final lower = judul.toLowerCase();
    if (lower.contains('blok a')) return 'Sawah Blok A — Karawang';
    if (lower.contains('blok b')) return 'Sawah Blok B — Karawang';
    if (lower.contains('subang')) return 'Lahan Perkebunan Subang';
    return 'Sawah Blok A — Karawang';
  }

  static String _inferLuasArea(String judul) {
    final lower = judul.toLowerCase();
    if (lower.contains('8 ha')) return '8 Ha';
    if (lower.contains('5 ha')) return '5 Ha';
    if (lower.contains('15 ha')) return '15 Ha';
    return '8 Ha';
  }
}
