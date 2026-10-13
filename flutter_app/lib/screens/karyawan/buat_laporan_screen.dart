import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:geolocator/geolocator.dart';
import '../../core/api_service.dart';
import '../../core/constants.dart';
import '../../core/session.dart';
import 'laporan_sukses_screen.dart';

class BuatLaporanScreen extends StatefulWidget {
  final Map<String, dynamic>? draft;

  const BuatLaporanScreen({super.key, this.draft});

  @override
  State<BuatLaporanScreen> createState() => _BuatLaporanScreenState();
}

class _BuatLaporanScreenState extends State<BuatLaporanScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime _tanggal = DateTime.now();
  final _judulCtrl = TextEditingController();
  final _unitDroneCtrl = TextEditingController(text: 'DA-001 (DJI Agras T40)');
  final _luasAreaCtrl = TextEditingController(text: '8 Ha');
  final _uraianCtrl = TextEditingController();
  final _hasilCtrl = TextEditingController();
  final _rencanaEsokCtrl = TextEditingController();
  final _imagePicker = ImagePicker();

  // Multi-photo state
  final List<File> _dokumentasiFiles = [];
  final List<String> _draftDokumentasiPaths = [];
  static const int _maxFoto = 10;

  // Per-photo GPS metadata
  final List<Position?> _posisiPerFoto = [];
  final List<DateTime?> _waktuPerFoto = [];

  String? _namaKaryawan;

  // Lokasi dropdown state
  List<Map<String, dynamic>> _lokasiList = [];
  int? _lokasiId;
  bool _lokasiLoading = true;
  String? _lokasiError;

  // Jenis kegiatan state
  List<Map<String, dynamic>> _jenisKegiatanList = [];
  int? _jenisKegiatanId;
  bool _jenisKegiatanLoading = true;
  String? _jenisKegiatanError;

  bool _submitting = false;

  static const double _akurasiGpsMaksimalMeter = 150;

  int? get _draftId {
    final id = widget.draft?['id'];
    return id is int ? id : int.tryParse(id?.toString() ?? '');
  }

  String get _jenisKegiatanTerpilih {
    for (final item in _jenisKegiatanList) {
      if (int.tryParse(item['id'].toString()) == _jenisKegiatanId) {
        return item['nama'].toString();
      }
    }
    return '';
  }

  Map<String, dynamic>? get _lokasiTerpilih {
    for (final l in _lokasiList) {
      if (int.tryParse(l['id'].toString()) == _lokasiId) return l;
    }
    return null;
  }

  String get _lokasiNamaTerpilih => _lokasiTerpilih?['nama']?.toString() ?? '';

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    if (draft != null) {
      _tanggal = DateTime.tryParse(
            (draft['tanggal_raw'] ?? draft['tanggal'])?.toString() ?? '',
          ) ??
          _tanggal;
      _judulCtrl.text = draft['judul']?.toString() == 'Draft tanpa judul'
          ? ''
          : draft['judul']?.toString() ?? '';
      _unitDroneCtrl.text = draft['unit_drone']?.toString() ?? '';
      _luasAreaCtrl.text = draft['luas_area']?.toString() ?? '';
      _uraianCtrl.text =
          (draft['uraian_pekerjaan'] ?? draft['isi_laporan'])?.toString() ?? '';
      _hasilCtrl.text = draft['hasil']?.toString() ?? '';
      _rencanaEsokCtrl.text = draft['rencana_esok']?.toString() ?? '';
      _jenisKegiatanId = int.tryParse(
        draft['jenis_kegiatan_id']?.toString() ?? '',
      );
      // Restore draft lampiran paths (JSON array or single string)
      final lampiranRaw = draft['lampiran']?.toString();
      if (lampiranRaw != null && lampiranRaw.isNotEmpty) {
        if (lampiranRaw.startsWith('[')) {
          try {
            final decoded = jsonDecode(lampiranRaw) as List;
            _draftDokumentasiPaths
                .addAll(decoded.map((e) => e.toString()));
          } catch (_) {
            _draftDokumentasiPaths.add(lampiranRaw);
          }
        } else {
          _draftDokumentasiPaths.add(lampiranRaw);
        }
      }
    }
    _muatData();
  }

  Future<void> _muatData() async {
    await Future.wait([_muatLokasi(), _muatJenisKegiatan()]);
    // After locations load, match draft lokasi by name
    if (widget.draft != null && _lokasiId == null) {
      final draftLokasi = widget.draft!['lokasi']?.toString();
      if (draftLokasi != null && draftLokasi.isNotEmpty) {
        final match = _lokasiList.where(
          (l) => l['nama']?.toString() == draftLokasi,
        );
        if (match.isNotEmpty && mounted) {
          setState(() {
            _lokasiId = int.tryParse(match.first['id'].toString());
          });
        }
      }
    }
  }

  Future<void> _muatLokasi() async {
    if (!mounted) return;
    setState(() {
      _lokasiLoading = true;
      _lokasiError = null;
    });
    try {
      final results = await ApiService.daftarLokasi();
      if (!mounted) return;
      setState(() {
        _lokasiList =
            results.map((item) => Map<String, dynamic>.from(item)).toList();
        _lokasiLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lokasiLoading = false;
        _lokasiError = e.toString();
      });
    }
  }

  Future<void> _muatJenisKegiatan() async {
    if (!mounted) return;
    setState(() {
      _jenisKegiatanLoading = true;
      _jenisKegiatanError = null;
    });
    try {
      final results = await ApiService.jenisKegiatanAktif();
      if (!mounted) return;
      final items =
          results.map((item) => Map<String, dynamic>.from(item)).toList();
      final draftName = widget.draft?['jenis_kegiatan']?.toString();
      var selectedId = _jenisKegiatanId;
      if (!items
          .any((item) => int.tryParse(item['id'].toString()) == selectedId)) {
        final matching = items.where((item) => item['nama'] == draftName);
        selectedId = matching.isEmpty
            ? (draftName == null && items.isNotEmpty
                ? int.tryParse(items.first['id'].toString())
                : null)
            : int.tryParse(matching.first['id'].toString());
      }
      setState(() {
        _jenisKegiatanList = items;
        _jenisKegiatanId = selectedId;
        _jenisKegiatanLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _jenisKegiatanLoading = false;
        _jenisKegiatanError = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _unitDroneCtrl.dispose();
    _luasAreaCtrl.dispose();
    _uraianCtrl.dispose();
    _hasilCtrl.dispose();
    _rencanaEsokCtrl.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggal() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggal,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Color(0xFF111827),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _tanggal = picked);
    }
  }

  Future<Position> _dapatkanPosisiGps() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw StateError('Izin lokasi diperlukan untuk mencocokkan GPS foto.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw StateError('Aktifkan GPS perangkat untuk mengambil dokumentasi.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        timeLimit: Duration(seconds: 20),
      ),
    );
    if (position.accuracy > _akurasiGpsMaksimalMeter) {
      throw StateError(
        'Sinyal GPS kurang akurat (±${position.accuracy.toStringAsFixed(0)} m). '
        'Coba lagi di area terbuka.',
      );
    }
    return position;
  }

  (double, double, double) _koordinatLokasiGps(
    Map<String, dynamic>? lokasi,
  ) {
    lokasi ??= _lokasiTerpilih;
    if (lokasi == null) {
      throw StateError('Pilih lokasi kerja terlebih dahulu.');
    }
    final lat = double.tryParse(lokasi['latitude']?.toString() ?? '');
    final lng = double.tryParse(lokasi['longitude']?.toString() ?? '');
    if (lat == null || lng == null || !lat.isFinite || !lng.isFinite) {
      throw StateError(
        'Koordinat GPS lokasi kerja belum diatur. Minta admin melengkapi lokasi ini.',
      );
    }

    final radius =
        double.tryParse(lokasi['radius_meters']?.toString() ?? '') ?? 500;
    if (!radius.isFinite || radius <= 0) {
      throw StateError('Radius GPS lokasi kerja tidak valid.');
    }
    return (lat, lng, radius);
  }

  /// Validates GPS against the selected master location and its configured radius.
  (double, bool) _validasiLokasiGps(
    Position posisi, {
    Map<String, dynamic>? lokasi,
  }) {
    final (lat, lng, radius) = _koordinatLokasiGps(lokasi);
    final jarak = Geolocator.distanceBetween(
      posisi.latitude,
      posisi.longitude,
      lat,
      lng,
    );
    return (jarak, jarak <= radius);
  }

  void _pilihLokasi(int? value) {
    Map<String, dynamic>? lokasi;
    for (final item in _lokasiList) {
      if (int.tryParse(item['id']?.toString() ?? '') == value) {
        lokasi = item;
        break;
      }
    }
    if (value != null && lokasi == null) return;

    try {
      if (_posisiPerFoto.isNotEmpty && lokasi == null) {
        throw StateError(
          'Hapus foto terlebih dahulu sebelum mengosongkan lokasi kerja.',
        );
      }
      for (final posisi in _posisiPerFoto) {
        if (posisi == null) {
          throw StateError(
            'Hapus foto yang belum memiliki data GPS sebelum mengganti lokasi.',
          );
        }
        final (_, dalamRadius) = _validasiLokasiGps(posisi, lokasi: lokasi);
        if (!dalamRadius) {
          throw StateError(
            'Hapus foto di luar radius lokasi yang dipilih sebelum mengganti lokasi kerja.',
          );
        }
      }
    } on StateError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }

    setState(() => _lokasiId = value);
  }

  Future<void> _pastikanNamaKaryawan() async {
    if (_namaKaryawan?.isNotEmpty ?? false) return;
    final namaSesi = (await Session.getNama())?.trim();
    if (namaSesi != null && namaSesi.isNotEmpty) {
      _namaKaryawan = namaSesi;
      return;
    }
    final profil = await ApiService.getProfile();
    final namaProfil = profil['nama']?.toString().trim();
    if (namaProfil == null || namaProfil.isEmpty) {
      throw StateError('Nama karyawan belum tersedia di profil.');
    }
    _namaKaryawan = namaProfil;
    await Session.setNama(namaProfil);
  }

  /// Picks a photo only when its current GPS position matches the selected location.
  Future<(File, Position?, DateTime)?> _ambilSatuFoto(
      ImageSource source) async {
    final image = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 2000,
      maxHeight: 2000,
    );
    if (image == null) return null;

    final waktu = DateTime.now();
    final posisi = await _dapatkanPosisiGps();

    if (!mounted) return null;

    final (jarak, dalamRadius) = _validasiLokasiGps(posisi);
    if (!dalamRadius) {
      final lokasi = _lokasiTerpilih!;
      final radius =
          double.tryParse(lokasi['radius_meters']?.toString() ?? '') ?? 500;
      throw StateError(
        'Foto ditolak: GPS berada ${jarak.toStringAsFixed(0)} m dari '
        '"$_lokasiNamaTerpilih" (batas ${radius.toStringAsFixed(0)} m). '
        'Ambil foto di lokasi kerja yang dipilih.',
      );
    }

    return (File(image.path), posisi, waktu);
  }

  Future<void> _pilihDokumentasi() async {
    if (_dokumentasiFiles.length >= _maxFoto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maksimal 10 foto dokumentasi.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await _pastikanNamaKaryawan();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Nama karyawan tidak dapat dimuat: $e')),
      );
      return;
    }
    if (!mounted) return;

    // Check lokasi selected
    if (_lokasiTerpilih == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih lokasi kerja terlebih dahulu.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    try {
      _koordinatLokasiGps(_lokasiTerpilih);
    } on StateError catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih dari galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    try {
      final result = await _ambilSatuFoto(source);
      if (result == null || !mounted) return;
      final (file, posisi, waktu) = result;
      setState(() {
        _dokumentasiFiles.add(file);
        _posisiPerFoto.add(posisi);
        _waktuPerFoto.add(waktu);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Bad state: ', '')),
        ),
      );
    }
  }

  void _hapusFoto(int index) {
    setState(() {
      _dokumentasiFiles.removeAt(index);
      if (index < _posisiPerFoto.length) _posisiPerFoto.removeAt(index);
      if (index < _waktuPerFoto.length) _waktuPerFoto.removeAt(index);
    });
  }

  void _hapusDraftFoto(int index) {
    setState(() {
      _draftDokumentasiPaths.removeAt(index);
    });
  }

  void _validasiFotoUntukDikirim() {
    if (_draftDokumentasiPaths.isNotEmpty && _dokumentasiFiles.isEmpty) {
      throw StateError(
        'Foto pada draft belum memiliki validasi GPS. Tambahkan foto baru '
        'yang GPS-nya cocok dengan lokasi kerja untuk mengganti lampiran lama.',
      );
    }
    if (_dokumentasiFiles.isEmpty) return;
    for (final posisi in _posisiPerFoto) {
      if (posisi == null) {
        throw StateError(
          'Semua foto harus memiliki GPS yang cocok dengan lokasi kerja. '
          'Hapus lalu ambil ulang foto yang tidak memiliki GPS.',
        );
      }
      final (_, dalamRadius) = _validasiLokasiGps(posisi);
      if (!dalamRadius) {
        throw StateError(
          'Lokasi kerja berubah dan tidak cocok dengan GPS salah satu foto. '
          'Hapus foto yang tidak sesuai lalu ambil ulang.',
        );
      }
    }
  }

  /// Add watermark tag to a single File photo, returns the tagged temp File.
  Future<File?> _siapkanFotoBertag(
    File foto,
    Position? posisi,
    DateTime? waktu,
  ) async {
    await _pastikanNamaKaryawan();
    final lokasiNama = _lokasiNamaTerpilih;

    final codec = await ui.instantiateImageCodec(await foto.readAsBytes());
    final frame = await codec.getNextFrame();
    final source = frame.image;
    final scale =
        (1600 / source.width).clamp(0.0, 1600 / source.height).clamp(0.0, 1.0);
    final width = (source.width * scale).round().clamp(1, 1600).toInt();
    final height = (source.height * scale).round().clamp(1, 1600).toInt();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final target = Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble());
    canvas.drawImageRect(
      source,
      Rect.fromLTWH(
        0,
        0,
        source.width.toDouble(),
        source.height.toDouble(),
      ),
      target,
      Paint(),
    );

    final padding = width * 0.035;
    final fontSize = (width * 0.027).clamp(18.0, 38.0).toDouble();
    final waktuStr =
        DateFormat('dd/MM/yyyy HH:mm').format(waktu ?? DateTime.now());

    final posisiStr = posisi == null
        ? 'GPS tidak tersedia'
        : '${posisi.latitude.toStringAsFixed(6)}, ${posisi.longitude.toStringAsFixed(6)}';

    final paragraphBuilder = ui.ParagraphBuilder(
      ui.ParagraphStyle(
        textDirection: ui.TextDirection.ltr,
        maxLines: 4,
        ellipsis: '…',
      ),
    )
      ..pushStyle(
        ui.TextStyle(
          color: const Color(0xFFFFFFFF),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
      )
      ..addText(
        'Nama: $_namaKaryawan\n'
        'Lokasi: $posisiStr${lokasiNama.isNotEmpty ? ' - $lokasiNama' : ''}\n'
        'Waktu: $waktuStr',
      );
    final paragraph = paragraphBuilder.build()
      ..layout(ui.ParagraphConstraints(
        width: width.toDouble() - padding * 2,
      ));
    final panelHeight = paragraph.height + padding * 2;
    final panelTop = height - panelHeight;
    canvas.drawRect(
      Rect.fromLTWH(0, panelTop, width.toDouble(), panelHeight),
      Paint()..color = const Color(0xBB000000),
    );
    canvas.drawParagraph(
      paragraph,
      Offset(padding, panelTop + padding),
    );

    final picture = recorder.endRecording();
    final taggedImage = await picture.toImage(width, height);
    final png = await taggedImage.toByteData(format: ui.ImageByteFormat.png);
    source.dispose();
    taggedImage.dispose();
    picture.dispose();
    if (png == null) throw StateError('Foto dokumentasi gagal diproses.');

    final decoded = img.decodeImage(
      png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes),
    );
    if (decoded == null) {
      throw StateError('Foto dokumentasi gagal dibaca setelah diberi tag.');
    }
    final jpg = img.encodeJpg(decoded, quality: 85);
    final tempPath =
        '${Directory.systemTemp.path}${Platform.pathSeparator}laporan-${DateTime.now().microsecondsSinceEpoch}.jpg';
    return File(tempPath).writeAsBytes(jpg, flush: true);
  }

  /// Prepares all photos with watermarks, returns list of tagged files.
  Future<List<File>> _siapkanSemuaFotoBertag() async {
    final tagged = <File>[];
    for (var i = 0; i < _dokumentasiFiles.length; i++) {
      final posisi = i < _posisiPerFoto.length ? _posisiPerFoto[i] : null;
      final waktu = i < _waktuPerFoto.length ? _waktuPerFoto[i] : null;
      final f = await _siapkanFotoBertag(_dokumentasiFiles[i], posisi, waktu);
      if (f != null) tagged.add(f);
    }
    return tagged;
  }

  Future<void> _hapusFotoBertagSementara(List<File> fotoList) async {
    for (final foto in fotoList) {
      // Skip if it's the original (shouldn't happen but safety)
      if (_dokumentasiFiles.any((f) => f.path == foto.path)) continue;
      try {
        if (await foto.exists()) await foto.delete();
      } on FileSystemException catch (e) {
        debugPrint('Gagal menghapus file foto sementara: $e');
      }
    }
  }

  String _formatTanggalIndo(DateTime dt, {bool withDay = false}) {
    const namaHari = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu'
    ];
    const namaBulan = [
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
      'Desember'
    ];
    final hari = namaHari[dt.weekday - 1];
    final tgl = dt.day;
    final bulan = namaBulan[dt.month - 1];
    final tahun = dt.year;
    if (withDay) {
      return '$hari, $tgl $bulan $tahun';
    }
    return '$tgl $bulan $tahun';
  }

  Map<String, String> _dataLaporan(String tanggal) {
    final uraian = _uraianCtrl.text.trim();
    return {
      'tanggal': tanggal,
      'judul': _judulCtrl.text.trim(),
      'isi_laporan': uraian,
      'jenis_kegiatan': _jenisKegiatanTerpilih,
      'jenis_kegiatan_id': _jenisKegiatanId?.toString() ?? '',
      'lokasi': _lokasiNamaTerpilih,
      'unit_drone': _unitDroneCtrl.text.trim(),
      'luas_area': _luasAreaCtrl.text.trim(),
      'uraian_pekerjaan': uraian,
      'hasil': _hasilCtrl.text.trim(),
      'rencana_esok': _rencanaEsokCtrl.text.trim(),
    };
  }

  Future<void> _kirimLaporan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final List<File> fotosBertag = [];

    try {
      final tglFormatted = DateFormat('yyyy-MM-dd').format(_tanggal);
      final displayTanggal = _formatTanggalIndo(_tanggal);
      final displayWaktu = DateFormat('HH.mm').format(DateTime.now());
      final data = _dataLaporan(tglFormatted);
      if (_jenisKegiatanId == null) {
        throw StateError('Pilih jenis kegiatan dari data master.');
      }

      _validasiFotoUntukDikirim();
      fotosBertag.addAll(await _siapkanSemuaFotoBertag());

      final draftId = _draftId;
      if (draftId != null) {
        await ApiService.kirimDraft(
          draftId,
          tanggal: tglFormatted,
          judul: data['judul']!,
          isiLaporan: data['isi_laporan']!,
          jenisKegiatan: data['jenis_kegiatan'],
          jenisKegiatanId: _jenisKegiatanId,
          lokasi: data['lokasi'],
          unitDrone: data['unit_drone'],
          luasArea: data['luas_area'],
          uraianPekerjaan: data['uraian_pekerjaan'],
          hasil: data['hasil'],
          rencanaEsok: data['rencana_esok'],
          lampiranList: fotosBertag.isNotEmpty ? fotosBertag : null,
        );
      } else {
        await ApiService.submitLaporan(
          tanggal: tglFormatted,
          judul: data['judul']!,
          isiLaporan: data['isi_laporan']!,
          jenisKegiatan: data['jenis_kegiatan'],
          jenisKegiatanId: _jenisKegiatanId,
          lokasi: data['lokasi'],
          unitDrone: data['unit_drone'],
          luasArea: data['luas_area'],
          uraianPekerjaan: data['uraian_pekerjaan'],
          hasil: data['hasil']!.isNotEmpty
              ? data['hasil']
              : 'Penyemprotan 100% selesai. Tidak ada kendala signifikan.',
          rencanaEsok: data['rencana_esok']!.isNotEmpty
              ? data['rencana_esok']
              : 'Melanjutkan operasional sesuai rencana kerja tim.',
          lampiranList: fotosBertag.isNotEmpty ? fotosBertag : null,
        );
      }

      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => LaporanSuksesScreen(
            tanggal: displayTanggal,
            waktuKirim: displayWaktu,
            status: 'Terkirim',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Gagal mengirim laporan: ${e.toString().replaceAll("Exception:", "").trim()}',
            ),
          ),
        );
      }
    } finally {
      await _hapusFotoBertagSementara(fotosBertag);
    }
  }

  Future<void> _simpanDraft() async {
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final List<File> fotosBertag = [];
    try {
      final tanggal = DateFormat('yyyy-MM-dd').format(_tanggal);
      final data = _dataLaporan(tanggal);
      if (_jenisKegiatanId == null) {
        throw StateError('Pilih jenis kegiatan dari data master.');
      }
      final judul =
          data['judul']!.isEmpty ? 'Draft tanpa judul' : data['judul']!;
      final id = _draftId;
      fotosBertag.addAll(await _siapkanSemuaFotoBertag());

      if (id == null) {
        await ApiService.submitLaporan(
          tanggal: tanggal,
          judul: judul,
          isiLaporan: data['isi_laporan']!,
          jenisKegiatan: data['jenis_kegiatan'],
          jenisKegiatanId: _jenisKegiatanId,
          lokasi: data['lokasi'],
          unitDrone: data['unit_drone'],
          luasArea: data['luas_area'],
          uraianPekerjaan: data['uraian_pekerjaan'],
          hasil: data['hasil'],
          rencanaEsok: data['rencana_esok'],
          lampiranList: fotosBertag.isNotEmpty ? fotosBertag : null,
          status: 'Draft',
        );
      } else {
        await ApiService.updateDraft(
          id,
          tanggal: tanggal,
          judul: judul,
          isiLaporan: data['isi_laporan']!,
          jenisKegiatan: data['jenis_kegiatan'],
          jenisKegiatanId: _jenisKegiatanId,
          lokasi: data['lokasi'],
          unitDrone: data['unit_drone'],
          luasArea: data['luas_area'],
          uraianPekerjaan: data['uraian_pekerjaan'],
          hasil: data['hasil'],
          rencanaEsok: data['rencana_esok'],
          lampiranList: fotosBertag.isNotEmpty ? fotosBertag : null,
        );
      }

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(content: Text('Draft laporan berhasil disimpan')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Gagal menyimpan draft: ${e.toString().replaceAll("Exception:", "").trim()}',
            ),
          ),
        );
      }
    } finally {
      await _hapusFotoBertagSementara(fotosBertag);
    }
  }

  // ────────────────────────────────────────────── BUILD ──

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            // TOP BAR
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
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
                  const SizedBox(width: 14),
                  Text(
                    _draftId == null
                        ? 'Buat Laporan Baru'
                        : 'Edit Draft Laporan',
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

            // FORM
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    // ── KARTU 1: INFORMASI OPERASIONAL ──
                    _buildCard(
                      children: [
                        _sectionLabel('INFORMASI OPERASIONAL'),
                        const SizedBox(height: 14),

                        // Tanggal
                        _fieldLabel('Tanggal Kegiatan'),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: _pilihTanggal,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(12),
                              border:
                                  Border.all(color: const Color(0xFFD1D5DB)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    color: AppConstants.primaryColor, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  _formatTanggalIndo(_tanggal, withDay: true),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF111827),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(Icons.keyboard_arrow_down_rounded,
                                    color: Color(0xFF9CA3AF)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Judul
                        _fieldLabel('Judul Laporan *'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _judulCtrl,
                          decoration: _inputDeco(
                              'Contoh: Penyemprotan pestisida Blok A — 8 Ha'),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Judul laporan wajib diisi'
                              : null,
                        ),
                        const SizedBox(height: 16),

                        // Jenis Kegiatan
                        _fieldLabel('Jenis Kegiatan'),
                        const SizedBox(height: 8),
                        if (_jenisKegiatanLoading)
                          const LinearProgressIndicator()
                        else if (_jenisKegiatanError != null)
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Gagal memuat jenis kegiatan.',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: _muatJenisKegiatan,
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          )
                        else
                          DropdownButtonFormField<int>(
                            initialValue: _jenisKegiatanId,
                            isExpanded: true,
                            decoration: _inputDeco(
                              _jenisKegiatanList.isEmpty
                                  ? 'Belum ada jenis kegiatan aktif'
                                  : 'Pilih jenis kegiatan',
                            ),
                            items: _jenisKegiatanList.map((item) {
                              final id = int.tryParse(item['id'].toString());
                              if (id == null) return null;
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(item['nama'].toString()),
                              );
                            }).whereType<DropdownMenuItem<int>>().toList(),
                            validator: (value) =>
                                value == null ? 'Pilih jenis kegiatan' : null,
                            onChanged: _jenisKegiatanList.isEmpty
                                ? null
                                : (value) =>
                                    setState(() => _jenisKegiatanId = value),
                          ),
                        const SizedBox(height: 16),

                        // Lokasi / Area — DROPDOWN
                        _fieldLabel('Lokasi / Area Kerja'),
                        const SizedBox(height: 8),
                        if (_lokasiLoading)
                          const LinearProgressIndicator()
                        else if (_lokasiError != null)
                          Row(
                            children: [
                              const Expanded(
                                child: Text('Gagal memuat lokasi kerja.',
                                    style: TextStyle(color: Colors.red)),
                              ),
                              TextButton(
                                onPressed: _muatLokasi,
                                child: const Text('Coba lagi'),
                              ),
                            ],
                          )
                        else
                          DropdownButtonFormField<int>(
                            initialValue: _lokasiId,
                            isExpanded: true,
                            decoration: _inputDeco(
                              _lokasiList.isEmpty
                                  ? 'Belum ada lokasi terdaftar'
                                  : 'Pilih lokasi kerja',
                            ),
                            items: _lokasiList.map((item) {
                              final id = int.tryParse(item['id'].toString());
                              if (id == null) return null;
                              return DropdownMenuItem<int>(
                                value: id,
                                child: Text(item['nama'].toString()),
                              );
                            }).whereType<DropdownMenuItem<int>>().toList(),
                            onChanged: _submitting || _lokasiList.isEmpty
                                ? null
                                : _pilihLokasi,
                          ),
                        const SizedBox(height: 16),

                        // Unit Drone & Luas Area (2 kolom)
                        Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('Unit Drone'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _unitDroneCtrl,
                                    decoration: _inputDeco(
                                        'DA-001 (DJI Agras T40)',
                                        compact: true),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _fieldLabel('Luas Area'),
                                  const SizedBox(height: 6),
                                  TextFormField(
                                    controller: _luasAreaCtrl,
                                    decoration:
                                        _inputDeco('8 Ha', compact: true),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── DOKUMENTASI KEGIATAN ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: const Color(0xFFE5E7EB), width: 1.2),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'DOKUMENTASI KEGIATAN LAPANGAN',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_dokumentasiFiles.length + _draftDokumentasiPaths.length}/$_maxFoto',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF9CA3AF),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Tambahkan foto dokumentasi kegiatan lapangan (opsional, maks. 10 foto).',
                                style: TextStyle(
                                    fontSize: 12.5, color: Color(0xFF9CA3AF)),
                              ),
                              const SizedBox(height: 12),
                              _buildFotoGrid(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── KARTU 2: URAIAN PEKERJAAN ──
                    _buildCard(
                      children: [
                        _sectionLabel('URAIAN PEKERJAAN *'),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: _uraianCtrl,
                          maxLines: 5,
                          decoration: _inputDeco(
                            'Tuliskan deskripsi lengkap pekerjaan lapangan, jam operasional, dosis semprot / perlakuan, kondisi cuaca, dan SOP...',
                          ),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? 'Uraian pekerjaan wajib diisi'
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── KARTU 3: HASIL & RENCANA ESOK ──
                    _buildCard(
                      children: [
                        _sectionLabel('HASIL & RENCANA ESOK'),
                        const SizedBox(height: 14),
                        _fieldLabel('Hasil Pekerjaan'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _hasilCtrl,
                          decoration: _inputDeco(
                              'Penyemprotan 100% selesai. Tidak ada kendala signifikan.'),
                        ),
                        const SizedBox(height: 14),
                        _fieldLabel('Rencana Esok'),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _rencanaEsokCtrl,
                          decoration: _inputDeco(
                              'Penyemprotan Blok B — 5 Ha dengan drone DA-002.'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM BUTTONS
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Colors.white,
                border:
                    Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: OutlinedButton(
                        onPressed: _submitting ? null : _simpanDraft,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppConstants.primaryColor,
                          side: const BorderSide(
                              color: AppConstants.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Simpan Draft',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppConstants.primaryColor,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: _submitting ? null : _kirimLaporan,
                        child: _submitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.2,
                                ),
                              )
                            : const Text(
                                'Kirim Laporan',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
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

  // ────────────────────── FOTO GRID ──────────────────────

  Widget _buildFotoGrid() {
    final totalDraftPaths = _draftDokumentasiPaths.length;
    final totalNewFiles = _dokumentasiFiles.length;
    final total = totalDraftPaths + totalNewFiles;
    final canAdd = total < _maxFoto;

    // Build items: draft paths first, then new files, then add button
    final List<Widget> items = [];

    // Draft paths (from server)
    for (var i = 0; i < totalDraftPaths; i++) {
      items.add(_buildDraftPhotoTile(i, _draftDokumentasiPaths[i]));
    }

    // Newly picked files
    for (var i = 0; i < totalNewFiles; i++) {
      items.add(_buildNewPhotoTile(i, _dokumentasiFiles[i]));
    }

    // Add button
    if (canAdd) {
      items.add(_buildAddPhotoButton());
    }

    if (items.isEmpty) {
      return _buildAddPhotoButton();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: items,
    );
  }

  Widget _buildDraftPhotoTile(int index, String path) {
    final url = AppConstants.getImageUrl(path);
    return _photoTileWrapper(
      onRemove: () => _hapusDraftFoto(index),
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 28, color: Color(0xFF9CA3AF)),
              ),
            )
          : const Center(
              child: Icon(Icons.broken_image_outlined,
                  size: 28, color: Color(0xFF9CA3AF)),
            ),
    );
  }

  Widget _buildNewPhotoTile(int index, File file) {
    final posisi = index < _posisiPerFoto.length ? _posisiPerFoto[index] : null;
    return _photoTileWrapper(
      onRemove: () => _hapusFoto(index),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(file, fit: BoxFit.cover),
          if (posisi != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                color: Colors.black54,
                child: const Text(
                  'GPS ✓',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _photoTileWrapper({
    required Widget child,
    required VoidCallback onRemove,
  }) {
    return SizedBox(
      width: 95,
      height: 95,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 95,
              height: 95,
              child: child,
            ),
          ),
          Positioned(
            top: 3,
            right: 3,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 13, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPhotoButton() {
    return GestureDetector(
      onTap: _submitting ? null : _pilihDokumentasi,
      child: Container(
        width: 95,
        height: 95,
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                size: 26, color: AppConstants.primaryColor),
            SizedBox(height: 4),
            Text(
              'Tambah\nFoto',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppConstants.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────── HELPERS ───────────────────

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Color(0xFF6B7280),
          letterSpacing: 0.6,
        ),
      );

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      );

  InputDecoration _inputDeco(String hint, {bool compact = false}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13.5),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 14,
          vertical: compact ? 12 : 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppConstants.primaryColor, width: 1.5),
        ),
      );
}
