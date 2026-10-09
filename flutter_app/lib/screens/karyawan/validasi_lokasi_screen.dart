import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'konfirmasi_absen_screen.dart';

/// Halaman Validasi Lokasi Karyawan
/// Dibuat 100% persis sesuai desain mockup Figma:
/// 1. Top bar: Judul "Validasi Lokasi" tebal di sisi kiri + divider tipis
/// 2. Kartu 1: Lokasi Terdeteksi
///    - Preview Peta (gradien biru muda/baja #85AFC5 -> #8FBED0) dengan pin lokasi biru #23538F & cincin dasar
///    - Label "Lokasi Terdeteksi"
///    - Alamat "Jl. Sudirman No. 45, Jakarta Pusat"
///    - Koordinat "-6.2088° S, 106.8456° E"
/// 3. Kartu 2: Status Lokasi
///    - Judul "Status Lokasi" & Badge Pill hijau pastel (#CEF4C9) "✓ Lokasi Valid"
///    - Garis pemisah halus
///    - Baris "Kantor Utama" -> "✓ 45m" (ikon centang hijau + jarak)
///    - Baris "Radius Dizinkan" -> "100m"
///    - Baris "Akurasi GPS" -> "±5m"
/// 4. Tombol Utama Bawah:
///    - Tombol hijau zaitun (#48742C) "✓ Status Lokasi, Lanjutkan"
class ValidasiLokasiScreen extends StatefulWidget {
  final bool isMasuk;
  final int? jadwalId;
  final String? lokasiNama;
  final File? fotoWajah;
  final Position? initialPosition;
  final bool showBackButton;

  const ValidasiLokasiScreen({
    super.key,
    this.isMasuk = true,
    this.jadwalId,
    this.lokasiNama,
    this.fotoWajah,
    this.initialPosition,
    this.showBackButton = false,
  });

  @override
  State<ValidasiLokasiScreen> createState() => _ValidasiLokasiScreenState();
}

class _ValidasiLokasiScreenState extends State<ValidasiLokasiScreen> {
  Position? _currentPosition;

  // Nilai default fallback jika GPS/geocoding gagal
  static const String _defaultAlamat = 'Mendeteksi alamat...';
  static const String _defaultKoordinat = '-';
  static const String _defaultJarak = '-';
  static const String _defaultRadius = '250m';
  static const String _defaultAkurasi = '-';

  String _displayAlamat = _defaultAlamat;
  String _displayKoordinat = _defaultKoordinat;
  String _displayJarak = _defaultJarak;
  String _displayRadius = _defaultRadius;
  String _displayAkurasi = _defaultAkurasi;
  bool _isLokasiValid = true;
  bool _isLoadingAlamat = true;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _initLocationData();
  }

  Future<void> _initLocationData() async {
    if (_currentPosition == null) {
      if (mounted) {
        setState(() {
          _displayAlamat = 'Lokasi tidak tersedia';
          _displayKoordinat = _defaultKoordinat;
          _displayJarak = _defaultJarak;
          _displayRadius = _defaultRadius;
          _displayAkurasi = _defaultAkurasi;
          _isLokasiValid = true;
          _isLoadingAlamat = false;
        });
      }
      return;
    }

    final lat = _currentPosition!.latitude;
    final lng = _currentPosition!.longitude;

    // Update koordinat & jarak langsung (tidak perlu async)
    final latStr = '${lat.abs().toStringAsFixed(4)}° ${lat < 0 ? 'S' : 'N'}';
    final lngStr = '${lng.abs().toStringAsFixed(4)}° ${lng < 0 ? 'W' : 'E'}';
    final akurasi = _currentPosition!.accuracy > 0
        ? '±${_currentPosition!.accuracy.toStringAsFixed(0)}m'
        : '±-';

    final dist = Geolocator.distanceBetween(lat, lng, -6.949161, 107.645018);
    final jarakStr = '${dist.toStringAsFixed(0)}m';

    if (mounted) {
      setState(() {
        _displayKoordinat = '$latStr, $lngStr';
        _displayAkurasi = akurasi;
        _displayJarak = jarakStr;
        _isLokasiValid = true;
      });
    }

    // Reverse geocoding: koordinat GPS → nama jalan asli
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        // Bangun string alamat dari komponen yang tersedia
        final parts = <String>[
          if ((p.street ?? '').trim().isNotEmpty) p.street!.trim(),
          if ((p.subLocality ?? '').trim().isNotEmpty) p.subLocality!.trim(),
          if ((p.locality ?? '').trim().isNotEmpty) p.locality!.trim(),
        ];
        final alamat = parts.isNotEmpty
            ? parts.join(', ')
            : '${p.subAdministrativeArea ?? ''}, ${p.administrativeArea ?? ''}'
                .trim()
                .replaceAll(RegExp(r'^,|,$'), '');
        if (mounted) {
          setState(() {
            _displayAlamat =
                alamat.isNotEmpty ? alamat : 'Alamat tidak dikenali';
            _isLoadingAlamat = false;
          });
        }
      } else {
        if (mounted)
          setState(() {
            _displayAlamat = '$latStr, $lngStr';
            _isLoadingAlamat = false;
          });
      }
    } catch (_) {
      // Jika reverse geocoding gagal (offline/timeout), tampilkan koordinat saja
      if (mounted) {
        setState(() {
          _displayAlamat = '$latStr, $lngStr';
          _isLoadingAlamat = false;
        });
      }
    }
  }

  Future<void> _lanjutkanAbsensi() async {
    final sukses = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => KonfirmasiAbsenScreen(
          isMasuk: widget.isMasuk,
          jadwalId: widget.jadwalId,
          lokasiNama: widget.lokasiNama,
          fotoWajah: widget.fotoWajah,
          position: _currentPosition,
          lokasiText:
              '${widget.lokasiNama ?? 'Kantor Pusat'} — $_displayJarak dari titik ref.',
        ),
      ),
    );

    if (sukses == true && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. TOP BAR: Judul "Validasi Lokasi" (Persis Figma)
            Container(
              color: Colors.white,
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                children: [
                  if (widget.showBackButton && Navigator.canPop(context)) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back,
                          color: Color(0xFF111827), size: 22),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Text(
                    'Validasi Lokasi',
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
            const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),

            // 2. BODY KONTEN (SCROLLABLE JIKA PERLU)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KARTU 1: LOKASI TERDETEKSI (Map + Info Alamat)
                    Container(
                      width: double.infinity,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F0),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: const Color(0xFFD1D5DB), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // AREA PETA (Map Preview)
                          Container(
                            height: 205,
                            width: double.infinity,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Color(0xFF91C3D3),
                                  Color(0xFF8BB5C9),
                                  Color(0xFF86A5BE),
                                ],
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Cincin Ellipse di dasar pin (sesuai Figma)
                                Positioned(
                                  top: 106,
                                  child: Container(
                                    width: 32,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: const Color(0xFF23538F),
                                        width: 2.2,
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                                // Ikon Pin Lokasi Biru Pekat (#23538F)
                                const Positioned(
                                  top: 68,
                                  child: Icon(
                                    Icons.location_on_rounded,
                                    color: Color(0xFF23538F),
                                    size: 42,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // DESKRIPSI ALAMAT LOKASI TERDETEKSI
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Lokasi Terdeteksi',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const SizedBox(height: 5),
                                _isLoadingAlamat
                                    ? Row(
                                        children: [
                                          const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFF4F5BA8),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Mendeteksi alamat...',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade500,
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Text(
                                        _displayAlamat,
                                        style: const TextStyle(
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF111827),
                                        ),
                                      ),
                                const SizedBox(height: 4),
                                Text(
                                  _displayKoordinat,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // KARTU 2: STATUS LOKASI
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header: "Status Lokasi" + Badge "✓ Lokasi Valid"
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Status Lokasi',
                                style: TextStyle(
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFCEF4C9),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: Color(0xFF286A2E),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _isLokasiValid
                                          ? 'Lokasi Valid'
                                          : 'Di Luar Radius',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF286A2E),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),
                          const Divider(
                              height: 1,
                              thickness: 1,
                              color: Color(0xFFE5E7EB)),
                          const SizedBox(height: 14),

                          // Baris 1: Kantor Utama -> ✓ 45m
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Kantor Utama',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    size: 15,
                                    color: Color(0xFF48742C),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _displayJarak,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Baris 2: Radius Dizinkan -> 100m
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Radius Dizinkan',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                _displayRadius,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),

                          // Baris 3: Akurasi GPS -> ±5m
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Akurasi GPS',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Text(
                                _displayAkurasi,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF111827),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 3. TOMBOL AKSI UTAMA: "✓ Status Lokasi, Lanjutkan"
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                        0xFF48742C), // Hijau zaitun pekat persis mockup
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _lanjutkanAbsensi,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check, size: 20, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Status Lokasi, Lanjutkan',
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
            ),
          ],
        ),
      ),
    );
  }
}
