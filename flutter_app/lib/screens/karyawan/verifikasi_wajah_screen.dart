import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import 'validasi_lokasi_screen.dart';

class VerifikasiWajahScreen extends StatefulWidget {
  final bool isMasuk;
  final int? jadwalId;
  final String? lokasiNama;

  const VerifikasiWajahScreen({
    super.key,
    required this.isMasuk,
    this.jadwalId,
    this.lokasiNama,
  });

  @override
  State<VerifikasiWajahScreen> createState() => _VerifikasiWajahScreenState();
}

class _VerifikasiWajahScreenState extends State<VerifikasiWajahScreen> {
  File? _fotoWajah;
  bool _loadingGps = false;
  bool _isProcessing = false;
  int _verifStep = 0;
  late final FaceDetector _faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      performanceMode: FaceDetectorMode.fast,
      minFaceSize: 0.1,
    ),
  );

  @override
  void dispose() {
    unawaited(_faceDetector.close());
    super.dispose();
  }

  Future<void> _pilihAtauAmbilFoto() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF27315B),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ambil Foto Wajah',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded,
                    color: Color(0xFF22C55E)),
                title: const Text('Buka Kamera (Selfie)',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _ambilFoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded,
                    color: Color(0xFF60A5FA)),
                title: const Text('Pilih dari Galeri',
                    style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(ctx);
                  _ambilFoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _ambilFoto(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (picked != null) {
        if (!mounted) return;
        setState(() {
          _fotoWajah = File(picked.path);
          _isProcessing = true;
          _verifStep = 0;
        });

        final faces = await _faceDetector.processImage(
          InputImage.fromFilePath(picked.path),
        );
        if (!mounted) return;

        if (faces.isEmpty) {
          setState(() {
            _fotoWajah = null;
            _isProcessing = false;
          });
          _tampilkanAlert(
            'Wajah Tidak Terdeteksi',
            'Foto harus menampilkan wajah dengan jelas. Silakan ambil atau pilih foto wajah.',
          );
          return;
        }
        if (faces.length > 1) {
          setState(() {
            _fotoWajah = null;
            _isProcessing = false;
          });
          _tampilkanAlert(
            'Terdeteksi Lebih dari Satu Wajah',
            'Pastikan foto hanya menampilkan wajah Anda seorang.',
          );
          return;
        }

        setState(() {
          _fotoWajah = File(picked.path);
          _verifStep = 3;
          _isProcessing = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _fotoWajah = null;
        _verifStep = 0;
        _isProcessing = false;
      });
      _tampilkanAlert(
        'Gagal Menganalisis Foto',
        'Foto tidak dapat diperiksa. Coba ambil foto lain.\n${e.toString()}',
      );
    }
  }

  Future<void> _lanjutValidasiGps() async {
    if (_fotoWajah == null || _verifStep < 3) return;

    setState(() => _loadingGps = true);

    try {
      // 1. Cek & Minta Izin Lokasi GPS
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _loadingGps = false);
        _tampilkanAlert('Izin Lokasi',
            'Izin lokasi (GPS) diperlukan untuk memvalidasi radius kantor.');
        return;
      }

      final isGpsOn = await Geolocator.isLocationServiceEnabled();
      if (!isGpsOn) {
        if (mounted) setState(() => _loadingGps = false);
        _tampilkanAlert('GPS Tidak Aktif',
            'Harap aktifkan GPS / Lokasi perangkat terlebih dahulu.');
        return;
      }

      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            timeLimit: Duration(seconds: 10),
          ),
        );
      } catch (_) {
        position = await Geolocator.getLastKnownPosition() ??
            await Geolocator.getCurrentPosition(
              locationSettings:
                  const LocationSettings(accuracy: LocationAccuracy.medium),
            );
      }

      if (!mounted) return;
      setState(() => _loadingGps = false);

      // 2. Lanjut ke Layar Validasi Lokasi
      final sukses = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => ValidasiLokasiScreen(
            isMasuk: widget.isMasuk,
            jadwalId: widget.jadwalId,
            lokasiNama: widget.lokasiNama,
            fotoWajah: _fotoWajah!,
            initialPosition: position,
          ),
        ),
      );

      if (sukses == true && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) setState(() => _loadingGps = false);
      _tampilkanAlert('Validasi Gagal', e.toString());
    }
  }

  void _tampilkanAlert(String title, String pesan) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF27315B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(pesan, style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFF22C55E), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  String get _statusTitle {
    if (_isProcessing) return 'Memverifikasi Wajah...';
    if (_fotoWajah == null) return 'Ambil Foto Wajah';
    return 'Wajah Terdeteksi!';
  }

  String get _statusSubtitle {
    if (_fotoWajah == null) {
      return 'Ketuk kotak kamera di atas untuk mengambil foto';
    }
    if (_isProcessing) {
      return 'Sistem sedang memeriksa apakah foto berisi satu wajah...';
    }
    return 'Satu wajah terdeteksi. Lanjutkan validasi lokasi.';
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF1E2548);
    final isMasuk = widget.isMasuk;
    final bool canContinue =
        _fotoWajah != null && _verifStep >= 3 && !_isProcessing && !_loadingGps;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      // Tombol Back Squircle
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: const Color(0xFF323B65),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Verifikasi Wajah',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Status Badge Pill di Kanan Atas
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isMasuk
                          ? const Color(0xFFD6DBED)
                          : const Color(0xFF1E432B),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isMasuk ? 'Absen Masuk' : 'Absen Pulang',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMasuk
                            ? const Color(0xFF2C355E)
                            : const Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

              // 2. Kotak Kamera Pemindaian Wajah (Squircle Ganda Hijau Neon)
              GestureDetector(
                onTap: _isProcessing ? null : _pilihAtauAmbilFoto,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(
                      color: _verifStep >= 3
                          ? const Color(0xFF22C55E).withValues(alpha: 0.9)
                          : const Color(0xFF22C55E).withValues(alpha: 0.6),
                      width: 1.6,
                    ),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.6),
                        width: 1.2,
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF16324D), Color(0xFF12243C)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(19),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Tampilkan foto jika sudah diambil
                          if (_fotoWajah != null)
                            Image.file(
                              _fotoWajah!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),

                          // JIKA BELUM ADA FOTO: Tampilkan Logo Kamera Hijau (Permintaan 2)
                          if (_fotoWajah == null)
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF43A047),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt_rounded,
                                    color: Color(0xFF1E2548),
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Ketuk untuk Ambil Foto',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          else if (_isProcessing)
                            // Overlay loading saat verifikasi bertahap
                            Container(
                              color: Colors.black.withValues(alpha: 0.35),
                              child: const Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFF22C55E),
                                  strokeWidth: 3,
                                ),
                              ),
                            )
                          else if (_verifStep >= 3)
                            // Badge sukses & opsi ganti foto
                            Positioned(
                              bottom: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_rounded,
                                        color: Color(0xFF22C55E), size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Wajah terdeteksi • Ketuk ganti',
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Status Teks (Dibuat sesuai kondisi foto, Permintaan 3)
              Text(
                _statusTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _statusSubtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFFD1D5DB),
                ),
              ),
              const SizedBox(height: 32),

              // Face presence is detected locally; this does not verify identity.
              _buildChecklistTile(
                _isProcessing
                    ? 'Memeriksa foto wajah'
                    : _verifStep >= 3
                        ? 'Satu wajah berhasil terdeteksi'
                        : 'Menunggu deteksi wajah',
                _verifStep >= 3,
                _isProcessing,
              ),
              const SizedBox(height: 36),

              // 4. Tombol Aksi: Lanjut Validasi GPS (Hanya aktif jika foto & verifikasi selesai)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canContinue
                        ? const Color(0xFF43732E)
                        : const Color(0xFF293252),
                    foregroundColor:
                        canContinue ? Colors.white : Colors.white38,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: canContinue ? _lanjutValidasiGps : null,
                  child: _loadingGps
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          'Lanjut Validasi GPS',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: canContinue ? Colors.white : Colors.white38,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistTile(String label, bool isChecked, bool isLoading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF27315B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isChecked
              ? const Color(0xFF22C55E).withValues(alpha: 0.35)
              : Colors.transparent,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color:
                  isChecked ? const Color(0xFF22C55E) : const Color(0xFF1E2548),
              shape: BoxShape.circle,
              border: isChecked
                  ? null
                  : Border.all(color: const Color(0xFF4B5563), width: 1.5),
            ),
            child: isChecked
                ? const Icon(
                    Icons.check,
                    color: Color(0xFF1E2548),
                    size: 18,
                    weight: 800,
                  )
                : (isLoading
                    ? const Padding(
                        padding: EdgeInsets.all(5.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF22C55E),
                        ),
                      )
                    : null),
          ),
          const SizedBox(width: 14),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: isChecked ? FontWeight.bold : FontWeight.w500,
              color:
                  isChecked ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
