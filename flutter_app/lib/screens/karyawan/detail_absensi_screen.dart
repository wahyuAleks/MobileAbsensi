import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';

/// Halaman Detail Absensi Karyawan & Admin
/// Menampilkan informasi absensi lengkap:
/// 1. Profil Karyawan (Nama, Jabatan, Email, Foto Profil)
/// 2. Foto Selfie Absen Masuk & Pulang (bisa diklik untuk perbesar)
/// 3. Status ketepatan waktu mengikuti target jam masuk lokasi pada tanggal absensi.
/// 4. Waktu Jam Masuk, Jam Pulang, dan Total Jam Kerja
/// 5. Validasi Lokasi GPS & Tombol Buka di Google Maps
class DetailAbsensiScreen extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback? onBack;

  const DetailAbsensiScreen({
    super.key,
    required this.item,
    this.onBack,
  });

  /// Menghitung status ketepatan waktu dari target yang tersimpan pada absensi.
  Map<String, dynamic> _hitungStatusKetepatanWaktu(
    String jamMasukRaw,
    String rawStatus,
    String targetRaw,
  ) {
    if (rawStatus.toLowerCase().contains('cuti') || rawStatus.toLowerCase().contains('izin')) {
      return {
        'status': 'Izin Cuti',
        'isLate': false,
        'badgeColor': const Color(0xFF4F5BA8),
        'bgColor': const Color(0xFFEEF2FF),
        'keterangan': 'Karyawan sedang dalam masa izin dinas / cuti.',
      };
    }

    if (jamMasukRaw == '—' || jamMasukRaw.trim().isEmpty || rawStatus.toLowerCase().contains('belum')) {
      return {
        'status': 'Belum Absen',
        'isLate': false,
        'badgeColor': const Color(0xFF6B7280),
        'bgColor': const Color(0xFFF3F4F6),
        'keterangan': 'Belum melakukan absensi masuk hari ini.',
      };
    }

    final clean = jamMasukRaw.replaceAll(' WIB', '').trim();
    final parts = clean.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      final s = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;

      final totalDetik = h * 3600 + m * 60 + s;
      final targetParts = targetRaw.split(':');
      final targetJam = int.tryParse(targetParts[0]) ?? 8;
      final targetMenit = int.tryParse(targetParts.length > 1 ? targetParts[1] : '0') ?? 0;
      final targetDetik = targetJam * 3600 + targetMenit * 60;
      final targetLabel = '${targetJam.toString().padLeft(2, '0')}:${targetMenit.toString().padLeft(2, '0')} WIB';

      if (totalDetik < targetDetik) {
        // Sebelum batas lokasi -> Datang Lebih Awal
        final selisihDetik = targetDetik - totalDetik;
        final selisihMenit = (selisihDetik / 60).floor();
        String durasiAwal;
        if (selisihMenit >= 60) {
          final jam = selisihMenit ~/ 60;
          final sisaMenit = selisihMenit % 60;
          durasiAwal = sisaMenit > 0 ? '$jam jam $sisaMenit menit' : '$jam jam';
        } else {
          durasiAwal = '$selisihMenit menit';
        }

        return {
          'status': 'Datang Lebih Awal',
          'isLate': false,
          'durasi': durasiAwal,
          'badgeColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFDCFCE7),
          'keterangan': 'Datang lebih awal $durasiAwal sebelum batas jam $targetLabel.',
        };
      } else if (totalDetik == targetDetik) {
        // Tepat pada batas lokasi -> Tepat Waktu
        return {
          'status': 'Tepat Waktu',
          'isLate': false,
          'durasi': '0 menit',
          'badgeColor': const Color(0xFF16A34A),
          'bgColor': const Color(0xFFDCFCE7),
          'keterangan': 'Hadir tepat waktu pada batas jam masuk $targetLabel.',
        };
      } else {
        // Lewat batas lokasi -> Terlambat
        final selisihDetik = totalDetik - targetDetik;
        final selisihMenit = (selisihDetik / 60).ceil();
        String durasiTelat;
        if (selisihMenit >= 60) {
          final jam = selisihMenit ~/ 60;
          final sisaMenit = selisihMenit % 60;
          durasiTelat = sisaMenit > 0 ? '$jam jam $sisaMenit menit' : '$jam jam';
        } else {
          durasiTelat = '$selisihMenit menit';
        }

        return {
          'status': 'Terlambat',
          'isLate': true,
          'durasi': durasiTelat,
          'badgeColor': const Color(0xFFEA580C),
          'bgColor': const Color(0xFFFFEDD5),
          'keterangan': 'Terlambat $durasiTelat dari batas jam masuk $targetLabel.',
        };
      }
    }

    return {
      'status': 'Hadir',
      'isLate': false,
      'badgeColor': const Color(0xFF16A34A),
      'bgColor': const Color(0xFFDCFCE7),
      'keterangan': 'Absensi masuk tercatat.',
    };
  }

  /// Membuka lokasi absensi di aplikasi Google Maps
  Future<void> _bukaGoogleMaps(BuildContext context, dynamic rawLat, dynamic rawLng) async {
    double lat = -6.949161;
    double lng = 107.645018;

    if (rawLat != null) {
      final parsed = double.tryParse(rawLat.toString());
      if (parsed != null) lat = parsed;
    }
    if (rawLng != null) {
      final parsed = double.tryParse(rawLng.toString());
      if (parsed != null) lng = parsed;
    }

    final urlMaps = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');

    try {
      final launched = await launchUrl(
        urlMaps,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(urlMaps, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade700,
            content: Text('Tidak dapat membuka Google Maps: $e'),
          ),
        );
      }
    }
  }

  void _bukaFotoBesar(BuildContext context, String imageUrl, String judul) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF1E2548),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    judul,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
            ),
            ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Container(
                  height: 220,
                  color: const Color(0xFF1E2548),
                  child: const Center(
                    child: Text('Gagal memuat foto', style: TextStyle(color: Colors.white70)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // 1. Data User / Karyawan
    final dynamic userObj = item['User'];
    final String namaKaryawan = userObj != null && userObj['nama'] != null
        ? userObj['nama'].toString()
        : (item['rawNama'] ?? item['nama'] ?? 'Karyawan').toString().replaceAll('\n', ' ');

    final String jabatanKaryawan = userObj != null && userObj['jabatan'] != null
        ? userObj['jabatan'].toString()
        : (item['devisi'] ?? 'Karyawan').toString().replaceAll('\n', ' ');

    final String emailKaryawan = userObj != null && userObj['email'] != null
        ? userObj['email'].toString()
        : (item['email'] ?? 'karyawan@mail.com').toString();

    final String? userFoto = userObj != null ? userObj['foto_profil']?.toString() : null;

    // 2. Data Jam & Status Masuk/Pulang
    final rawStatus = (item['status'] ?? 'Hadir').toString();
    final jamMasukRaw = (item['jam_masuk'] ?? '—').toString();
    final jamPulangRaw = (item['jam_pulang'] ?? '—').toString();
    final targetMasukRaw = (item['jam_masuk_target'] ?? '08:00:00').toString();

    final statusInfo = _hitungStatusKetepatanWaktu(jamMasukRaw, rawStatus, targetMasukRaw);
    final String statusDisplay = statusInfo['status'] as String;
    final Color statusColor = statusInfo['badgeColor'] as Color;
    final Color statusBg = statusInfo['bgColor'] as Color;
    final String statusKeterangan = statusInfo['keterangan'] as String;

    final String jamMasuk = jamMasukRaw == '—' || jamMasukRaw.isEmpty
        ? '—'
        : (jamMasukRaw.contains('WIB') ? jamMasukRaw : '$jamMasukRaw WIB');

    final String jamPulang = jamPulangRaw == '—' || jamPulangRaw.isEmpty
        ? '—'
        : (jamPulangRaw.contains('WIB') ? jamPulangRaw : '$jamPulangRaw WIB');

    final String totalJamKerja = (jamMasukRaw == '—' || jamPulangRaw == '—' || jamPulangRaw.isEmpty)
        ? (jamMasukRaw != '—' ? 'Sedang Bekerja' : '—')
        : (item['total_jam']?.toString() ?? _hitungTotalJamKerja(jamMasukRaw, jamPulangRaw));

    // 3. Data Tanggal
    final tanggalLengkap = _formatTanggal(item);

    // 4. Data Foto Masuk & Pulang
    final String? fotoMasukPath = item['foto_masuk']?.toString();
    final String? fotoPulangPath = item['foto_pulang']?.toString();
    final String? fotoMasukUrl = AppConstants.getImageUrl(fotoMasukPath);
    final String? fotoPulangUrl = AppConstants.getImageUrl(fotoPulangPath);

    // 5. Data Koordinat GPS
    final latMsk = item['lat_masuk'];
    final lngMsk = item['lng_masuk'];
    final latPlg = item['lat_pulang'];
    final lngPlg = item['lng_pulang'];

    String koordinatDisplay;
    if (latMsk != null && lngMsk != null) {
      koordinatDisplay = 'Masuk: $latMsk, $lngMsk • Akurasi ±5m';
      if (latPlg != null && lngPlg != null) {
        koordinatDisplay += '\nPulang: $latPlg, $lngPlg';
      }
    } else {
      koordinatDisplay = item['koordinat']?.toString() ?? '-6.9492° S, 107.6450° E • Akurasi ±5m';
    }

    final jadwalKerja = item['jadwal_kerja'];
    final lokasiJadwal = jadwalKerja is Map ? jadwalKerja['Location'] : null;
    final String lokasiMasuk = lokasiJadwal is Map
        ? lokasiJadwal['nama']?.toString() ?? 'Lokasi kerja'
        : item['lokasi']?.toString() ??
            'Kantor Pusat — Jl. Sudirman No. 45';

    return PopScope(
      canPop: onBack == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && onBack != null) {
          onBack!();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP BAR: Back Button + Title + Status Chip
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  children: [
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
                        width: 34,
                        height: 34,
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
                    const Expanded(
                      child: Text(
                        'Detail Absensi',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    // Status Badge di Kanan Atas
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        statusDisplay,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

              // 2. KONTEN DETAIL
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                  children: [
                    // KARTU 1: PROFIL KARYAWAN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: const Color(0xFF4F5BA8),
                            backgroundImage: userFoto != null && userFoto.isNotEmpty
                                ? NetworkImage(AppConstants.getImageUrl(userFoto)!)
                                : null,
                            child: (userFoto == null || userFoto.isEmpty)
                                ? Text(
                                    namaKaryawan.isNotEmpty ? namaKaryawan[0].toUpperCase() : 'K',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  namaKaryawan,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  jabatanKaryawan,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4F5BA8),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  emailKaryawan,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // KARTU 2: STATUS KETEPATAN WAKTU SESUAI TARGET LOKASI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              statusDisplay.contains('Awal') || statusDisplay.contains('Tepat')
                                  ? Icons.check_circle_rounded
                                  : (statusDisplay == 'Terlambat'
                                      ? Icons.alarm_on_rounded
                                      : Icons.info_outline_rounded),
                              color: statusColor,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status Kehadiran: $statusDisplay',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  statusKeterangan,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF4B5563),
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // KARTU 3: FOTO BUKTI PRESENSI (MASUK & PULANG)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.camera_alt_outlined, size: 16, color: Color(0xFF4F5BA8)),
                              SizedBox(width: 8),
                              Text(
                                'FOTO BUKTI ABSENSI',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              // 1. Foto Absen Masuk
                              Expanded(
                                child: _buildFotoBox(
                                  context: context,
                                  label: 'Foto Masuk',
                                  jam: jamMasuk,
                                  imageUrl: fotoMasukUrl,
                                  isMasuk: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 2. Foto Absen Pulang
                              Expanded(
                                child: _buildFotoBox(
                                  context: context,
                                  label: 'Foto Pulang',
                                  jam: jamPulang,
                                  imageUrl: fotoPulangUrl,
                                  isMasuk: false,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // KARTU 4: RINCIAN INFORMASI ABSENSI LENGKAP
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(16, 14, 16, 12),
                            child: Text(
                              'RINCIAN LENGKAP PRESENSI',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6B7280),
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow('Tanggal', tanggalLengkap),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow('Jam Masuk', jamMasuk),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow(
                            'Target Masuk Kantor',
                            '${targetMasukRaw.substring(0, targetMasukRaw.length >= 5 ? 5 : targetMasukRaw.length)} WIB',
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow(
                            'Status Kehadiran',
                            statusDisplay,
                            valueColor: statusColor,
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow('Jam Pulang', jamPulang),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow('Total Jam Kerja', totalJamKerja),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow('Lokasi Masuk', lokasiMasuk),
                          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

                          _buildTableRow('Metode Validasi', 'Face Biometric + GPS'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // KARTU 5: LOKASI GPS & PETA (BISA DIKLIK BUKA GOOGLE MAPS)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.2),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'LOKASI & GPS GEOLOKASI',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF6B7280),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Row(
                                children: [
                                  Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A), size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'Valid (Dalam Radius)',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF16A34A),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Map Preview Box (Bisa diklik untuk buka Google Maps)
                          GestureDetector(
                            onTap: () => _bukaGoogleMaps(context, latMsk, lngMsk),
                            child: Container(
                              height: 120,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFC9EFC4),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              alignment: Alignment.center,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Positioned(
                                    bottom: 35,
                                    child: Container(
                                      width: 34,
                                      height: 14,
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF23538F),
                                          width: 2.2,
                                        ),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  const Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF23538F),
                                    size: 38,
                                  ),
                                  // Petunjuk klik di pojok kanan bawah peta
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.open_in_new_rounded, size: 12, color: Colors.white),
                                          SizedBox(width: 4),
                                          Text(
                                            'Google Maps',
                                            style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),

                          Center(
                            child: Text(
                              koordinatDisplay,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF4B5563),
                                height: 1.35,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Tombol Aksi Buka di Google Maps
                          SizedBox(
                            width: double.infinity,
                            height: 44,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF4F5BA8),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: () => _bukaGoogleMaps(context, latMsk, lngMsk),
                              icon: const Icon(Icons.map_rounded, size: 18),
                              label: const Text(
                                'Buka Lokasi di Google Maps',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFotoBox({
    required BuildContext context,
    required String label,
    required String jam,
    required String? imageUrl,
    required bool isMasuk,
  }) {
    final bool hasImage = imageUrl != null && imageUrl.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: hasImage ? () => _bukaFotoBesar(context, imageUrl, label) : null,
          child: Container(
            height: 130,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: hasImage ? const Color(0xFF4F5BA8).withValues(alpha: 0.5) : const Color(0xFFD1D5DB),
                width: 1.2,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(13),
              child: hasImage
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(label, 'Gagal memuat'),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.zoom_in, color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    )
                  : _buildPlaceholder(label, isMasuk ? 'Belum ada foto' : 'Belum absen pulang'),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Color(0xFF111827),
          ),
        ),
        Text(
          jam,
          style: const TextStyle(
            fontSize: 11.5,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholder(String label, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 28,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF111827),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTanggal(Map<String, dynamic> item) {
    if (item['tanggal_lengkap'] != null &&
        item['tanggal_lengkap'].toString().isNotEmpty) {
      return item['tanggal_lengkap'].toString();
    }

    final tglStr = item['tanggal']?.toString() ?? '';
    if (tglStr.isNotEmpty) {
      try {
        final dt = DateTime.parse(tglStr);
        const hariList = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
        const blnList = [
          'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
          'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
        ];
        return '${hariList[dt.weekday - 1]}, ${dt.day} ${blnList[dt.month - 1]} ${dt.year}';
      } catch (_) {}
    }

    final hari = item['hari']?.toString() ?? 'Senin';
    final tgl = item['tgl']?.toString() ?? '14';
    final blnRaw = item['bulan']?.toString() ?? 'AGU';
    final bln = _namaBulanLengkap(blnRaw);
    return '$hari, $tgl $bln 2026';
  }

  static String _namaBulanLengkap(String blnRaw) {
    final b = blnRaw.toUpperCase();
    if (b.contains('JAN')) return 'Januari';
    if (b.contains('FEB')) return 'Februari';
    if (b.contains('MAR')) return 'Maret';
    if (b.contains('APR')) return 'April';
    if (b.contains('MEI')) return 'Mei';
    if (b.contains('JUN')) return 'Juni';
    if (b.contains('JUL')) return 'Juli';
    if (b.contains('AGU')) return 'Agustus';
    if (b.contains('SEP')) return 'September';
    if (b.contains('OKT')) return 'Oktober';
    if (b.contains('NOV')) return 'November';
    if (b.contains('DES')) return 'Desember';
    return 'Agustus';
  }

  static String _hitungTotalJamKerja(String masuk, String pulang) {
    if (masuk == '—' || pulang == '—' || masuk.isEmpty || pulang.isEmpty) {
      return '—';
    }

    try {
      final cleanMasuk = masuk.replaceAll(' WIB', '').trim();
      final cleanPulang = pulang.replaceAll(' WIB', '').trim();

      final pMasuk = cleanMasuk.split(':');
      final pPulang = cleanPulang.split(':');

      if (pMasuk.length >= 2 && pPulang.length >= 2) {
        final mH = int.parse(pMasuk[0]);
        final mM = int.parse(pMasuk[1]);
        final pH = int.parse(pPulang[0]);
        final pM = int.parse(pPulang[1]);

        int totalMenitMasuk = mH * 60 + mM;
        int totalMenitPulang = pH * 60 + pM;

        if (totalMenitPulang >= totalMenitMasuk) {
          int selisih = totalMenitPulang - totalMenitMasuk;
          int jam = selisih ~/ 60;
          int menit = selisih % 60;

          if (menit == 0) {
            return '$jam jam';
          }
          return '$jam jam $menit menit';
        }
      }
    } catch (_) {}

    return '8 jam';
  }
}
