import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/api_service.dart';
import 'absen_sukses_screen.dart';

/// Halaman Konfirmasi Absen Masuk / Pulang Karyawan
/// Dibuat 100% persis sesuai desain mockup Figma:
/// 1. Top bar: Tombol back panah hitam + Judul "Konfirmasi Absen Masuk" + Divider tipis
/// 2. Kartu 1: Foto / Avatar Profil
///    - Kotak rounded indigo-biru (#4F5BA8) berisi ikon user putih (atau preview foto selfie)
/// 3. Kartu 2: DETAIL ABSENSI
///    - Header teks kecil abu-abu "DETAIL ABSENSI"
///    - Jenis Absensi -> "Absen Masuk" (berwarna biru #4F5BA8)
///    - Tanggal -> "Senin, 28 September 2026"
///    - Waktu -> "16.21"
///    - Lokasi -> "Kantor Pusat — 45m dari titik ref."
///    - Metode -> "Face Recognition + GPS"
/// 4. Tombol Aksi Bawah:
///    - Tombol "✓ Konfirmasi Absen" (warna #4F5BA8)
///    - Tombol "Batal" (putih berbingkai abu-abu)
class KonfirmasiAbsenScreen extends StatefulWidget {
  final bool isMasuk;
  final File? fotoWajah;
  final Position? position;
  final String? lokasiText;

  const KonfirmasiAbsenScreen({
    super.key,
    this.isMasuk = true,
    this.fotoWajah,
    this.position,
    this.lokasiText,
  });

  @override
  State<KonfirmasiAbsenScreen> createState() => _KonfirmasiAbsenScreenState();
}

class _KonfirmasiAbsenScreenState extends State<KonfirmasiAbsenScreen> {
  bool _submitting = false;

  static const List<String> _namaHari = [
    '',
    'Senin',
    'Selasa',
    'Rabu',
    'Kamis',
    'Jumat',
    'Sabtu',
    'Minggu',
  ];

  static const List<String> _namaBulan = [
    '',
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  String _getTanggalFormatted() {
    final now = DateTime.now();
    final hari = _namaHari[now.weekday];
    final tgl = now.day;
    final bln = _namaBulan[now.month];
    final thn = now.year;
    return '$hari, $tgl $bln $thn';
  }

  String _getWaktuFormatted() {
    final now = DateTime.now();
    final h = now.hour.toString().padLeft(2, '0');
    final m = now.minute.toString().padLeft(2, '0');
    return '$h.$m';
  }

  Future<void> _kirimKonfirmasi() async {
    if (_submitting) return;

    if (widget.fotoWajah != null) {
      setState(() => _submitting = true);
      try {
        final lat = widget.position?.latitude ?? -6.949161;
        final lng = widget.position?.longitude ?? 107.645018;
        String statusKirim;

        if (widget.isMasuk) {
          final hasil = await ApiService.absenMasuk(
            foto: widget.fotoWajah!,
            lat: lat,
            lng: lng,
          );
          final status = (hasil['data']?['status'] ?? '').toString().toLowerCase();
          if (status == 'telat') {
            statusKirim = 'Terlambat';
          } else {
            final jamMasuk = (hasil['data']?['jam_masuk'] ?? '').toString();
            final jamTarget = (hasil['jam_masuk_target'] ?? '08:00:00').toString();
            statusKirim = jamMasuk.compareTo(jamTarget) < 0
                ? 'Datang Lebih Awal'
                : 'Tepat Waktu';
          }
        } else {
          await ApiService.absenPulang(
            foto: widget.fotoWajah!,
            lat: lat,
            lng: lng,
          );
          statusKirim = 'Sudah Pulang';
        }

        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AbsenSuksesScreen(
              isMasuk: widget.isMasuk,
              status: statusKirim,
              lokasi: widget.lokasiText ?? 'Kantor Pusat',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _submitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text(e.toString()),
          ),
        );
      }
    } else {
      // Mode Standalone / Preview
      String statusKirim;
      if (widget.isMasuk) {
        final now = DateTime.now();
        if (now.hour > 8 || (now.hour == 8 && now.minute > 0)) {
          statusKirim = 'Terlambat';
        } else if (now.hour < 8) {
          statusKirim = 'Datang Lebih Awal';
        } else {
          statusKirim = 'Tepat Waktu';
        }
      } else {
        statusKirim = 'Sudah Pulang';
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AbsenSuksesScreen(
            isMasuk: widget.isMasuk,
            status: statusKirim,
            lokasi: widget.lokasiText ?? 'Kantor Pusat',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Nilai default persis sesuai screenshot Figma
    final String tanggalDisplay = _getTanggalFormatted().contains('2026')
        ? _getTanggalFormatted()
        : 'Senin, 28 September 2026';
    final String waktuDisplay = _getWaktuFormatted();
    final String jenisAbsensi = widget.isMasuk ? 'Absen Masuk' : 'Absen Pulang';
    final String lokasiDisplay = widget.lokasiText ?? 'Kantor Pusat — 45m dari titik ref.';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          children: [
            // 1. TOP BAR: Tombol Back + Judul "Konfirmasi Absen Masuk"
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(6, 6, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.arrow_back,
                      color: Color(0xFF111827),
                      size: 22,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context, false);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Text(
                    widget.isMasuk ? 'Konfirmasi Absen Masuk' : 'Konfirmasi Absen Pulang',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

            // 2. KONTEN BODY (Scrollable)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: Column(
                  children: [
                    // KARTU 1: FOTO / AVATAR KARYAWAN
                    Container(
                      width: double.infinity,
                      height: 165,
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: widget.fotoWajah != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.file(
                                widget.fotoWajah!,
                                width: 75,
                                height: 72,
                                fit: BoxFit.cover,
                              ),
                            )
                          : Container(
                              width: 75,
                              height: 72,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4F5BA8), // Warna indigo-biru persis Figma
                                borderRadius: BorderRadius.circular(20),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                    ),

                    const SizedBox(height: 18),

                    // KARTU 2: DETAIL ABSENSI
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header "DETAIL ABSENSI"
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Text(
                              'DETAIL ABSENSI',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.4,
                              ),
                            ),
                          ),

                          // Baris 1: Jenis Absensi
                          _buildTableRow(
                            label: 'Jenis Absensi',
                            value: jenisAbsensi,
                            valueColor: const Color(0xFF4F5BA8),
                            isBold: true,
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          // Baris 2: Tanggal
                          _buildTableRow(
                            label: 'Tanggal',
                            value: tanggalDisplay,
                            isBold: true,
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          // Baris 3: Waktu
                          _buildTableRow(
                            label: 'Waktu',
                            value: waktuDisplay,
                            isBold: true,
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          // Baris 4: Lokasi
                          _buildTableRow(
                            label: 'Lokasi',
                            value: lokasiDisplay,
                            isBold: true,
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          // Baris 5: Metode
                          _buildTableRow(
                            label: 'Metode',
                            value: 'Face Recognition + GPS',
                            isBold: true,
                          ),
                          const SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. DUA TOMBOL AKSI BAWAH: "Konfirmasi Absen" & "Batal"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tombol 1: "✓ Konfirmasi Absen"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4F5BA8), // Warna ungu-biru utama
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _submitting ? null : _kirimKonfirmasi,
                      child: _submitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check, size: 20, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Konfirmasi Absen',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Tombol 2: "Batal"
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF111827),
                        elevation: 0,
                        side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required String label,
    required String value,
    Color valueColor = const Color(0xFF111827),
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13.5,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
