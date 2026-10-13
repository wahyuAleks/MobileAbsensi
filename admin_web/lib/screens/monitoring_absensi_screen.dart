import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/api_service.dart';
import '../core/constants.dart';

class MonitoringAbsensiScreen extends StatefulWidget {
  final bool showAppBar;
  final VoidCallback? onOpenDrawer;
  final VoidCallback? onOpenNotifikasi;
  final VoidCallback? onBukaKaryawan;
  final VoidCallback? onBukaPersetujuanCuti;
  final VoidCallback? onBukaProfil;

  const MonitoringAbsensiScreen({
    super.key,
    this.showAppBar = false,
    this.onOpenDrawer,
    this.onOpenNotifikasi,
    this.onBukaKaryawan,
    this.onBukaPersetujuanCuti,
    this.onBukaProfil,
  });

  @override
  State<MonitoringAbsensiScreen> createState() => _MonitoringAbsensiScreenState();
}

class _MonitoringAbsensiScreenState extends State<MonitoringAbsensiScreen> {
  DateTime _selectedDate = DateTime.now();
  String _activeFilter = 'semua'; // 'semua', 'hadir', 'terlambat', 'belum'
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  List<Map<String, dynamic>> _karyawanList = [];
  List<Map<String, dynamic>> _absensiList = [];
  bool _loading = true;
  String? _error;

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

  Future<void> _muat() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final tglStr = DateFormat('yyyy-MM-dd').format(_selectedDate);

    try {
      final results = await Future.wait([
        ApiService.rekapAbsensiAdmin(tanggal: tglStr),
        ApiService.daftarKaryawan(),
      ]);

      if (!mounted) return;
      setState(() {
        _absensiList = results[0]
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _karyawanList = results[1]
            .map((e) => Map<String, dynamic>.from(e as Map))
            .where((item) =>
                item['is_active'] == true ||
                item['is_active'] == 1 ||
                item['is_active'] == '1')
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
      helpText: 'Pilih Tanggal Monitoring',
    );

    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      await _muat();
    }
  }

  void _lihatDetailAbsensi(Map<String, dynamic> item) {
    final user = item['User'] is Map ? item['User'] as Map : const {};
    final nama = (user['nama'] ?? item['nama'] ?? 'Karyawan').toString();
    final jabatan = (user['jabatan'] ?? item['jabatan'] ?? '-').toString();
    final jamMasuk = (item['jam_masuk'] ?? '-').toString();
    final jamPulang = (item['jam_pulang'] ?? '-').toString();
    final status = (item['status'] ?? '').toString();
    final isTerlambat = status.toLowerCase().contains('terlambat') || status.toLowerCase().contains('telat');
    final fotoMasuk = item['foto_masuk']?.toString();
    final fotoPulang = item['foto_pulang']?.toString();
    final latMasuk = item['lat_masuk'] ?? item['latitude'];
    final lngMasuk = item['lng_masuk'] ?? item['longitude'];
    final lokasiNama = item['lokasi_nama'] ?? item['Location']?['nama'] ?? 'Kantor / Lokasi Kerja';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.person_pin_circle_outlined, color: AppConstants.primaryColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Detail Absensi: $nama',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Jabatan: $jabatan', style: const TextStyle(color: Color(0xFF64748B))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isTerlambat ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isTerlambat ? 'Terlambat' : (jamMasuk != '-' ? 'Tepat Waktu' : 'Belum Absen'),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isTerlambat ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Jam & Lokasi
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jam Masuk', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text(jamMasuk, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Jam Pulang', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            const SizedBox(height: 4),
                            Text(jamPulang, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.green, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Lokasi: $lokasiNama' + (latMasuk != null ? ' ($latMasuk, $lngMasuk)' : ''),
                        style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Foto Dokumentasi Masuk & Pulang
                const Text('Foto Verifikasi:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Foto Masuk', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: fotoMasuk != null && fotoMasuk.isNotEmpty
                                ? Image.network(
                                    AppConstants.getImageUrl(fotoMasuk)!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 140,
                                      color: const Color(0xFFF1F5F9),
                                      alignment: Alignment.center,
                                      child: const Text('Foto tidak ada', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ),
                                  )
                                : Container(
                                    height: 140,
                                    color: const Color(0xFFF1F5F9),
                                    alignment: Alignment.center,
                                    child: const Text('Tidak ada foto', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Foto Pulang', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: fotoPulang != null && fotoPulang.isNotEmpty
                                ? Image.network(
                                    AppConstants.getImageUrl(fotoPulang)!,
                                    height: 140,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      height: 140,
                                      color: const Color(0xFFF1F5F9),
                                      alignment: Alignment.center,
                                      child: const Text('Foto tidak ada', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ),
                                  )
                                : Container(
                                    height: 140,
                                    color: const Color(0xFFF1F5F9),
                                    alignment: Alignment.center,
                                    child: const Text('Tidak ada foto', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tutup'),
          ),
        ],
      ),
    );
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
    // Menghitung status
    final totalKaryawan = _karyawanList.isNotEmpty ? _karyawanList.length : _absensiList.length;
    int hadirCount = 0;
    int terlambatCount = 0;

    for (final item in _absensiList) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      final jamMasuk = item['jam_masuk']?.toString();
      if (status.contains('terlambat') || status.contains('telat')) {
        terlambatCount++;
        hadirCount++;
      } else if (jamMasuk != null && jamMasuk.isNotEmpty && jamMasuk != '-') {
        hadirCount++;
      }
    }

    final belumAbsenCount = (totalKaryawan - hadirCount).clamp(0, totalKaryawan);

    final filteredList = _absensiList.where((item) {
      final status = (item['status'] ?? '').toString().toLowerCase();
      final isTelat = status.contains('terlambat') || status.contains('telat');

      if (_activeFilter == 'hadir' && isTelat) return false;
      if (_activeFilter == 'terlambat' && !isTelat) return false;

      if (_query.isNotEmpty) {
        final user = item['User'] is Map ? item['User'] as Map : const {};
        final nama = (user['nama'] ?? item['nama'] ?? '').toString().toLowerCase();
        return nama.contains(_query);
      }
      return true;
    }).toList();

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
                  children: [
                    const Text(
                      'Monitoring Absensi Real-Time',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                      style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pilihTanggal,
                      icon: const Icon(Icons.calendar_month_outlined, size: 18),
                      label: Text(DateFormat('dd MMM yyyy').format(_selectedDate)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _muat,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Metrics Cards
            Row(
              children: [
                _buildSummaryCard('Total Karyawan', totalKaryawan, const Color(0xFF3B82F6), Icons.groups_rounded),
                const SizedBox(width: 14),
                _buildSummaryCard('Hadir', hadirCount, const Color(0xFF10B981), Icons.check_circle_outline),
                const SizedBox(width: 14),
                _buildSummaryCard('Terlambat', terlambatCount, const Color(0xFFF59E0B), Icons.access_time_rounded),
                const SizedBox(width: 14),
                _buildSummaryCard('Belum Absen', belumAbsenCount, const Color(0xFFEF4444), Icons.cancel_outlined),
              ],
            ),
            const SizedBox(height: 20),

            // Filter Chips & Search
            Row(
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _buildFilterChip('Semua (${_absensiList.length})', 'semua'),
                    _buildFilterChip('Tepat Waktu (${hadirCount - terlambatCount})', 'hadir'),
                    _buildFilterChip('Terlambat ($terlambatCount)', 'terlambat'),
                  ],
                ),
                const Spacer(),
                SizedBox(
                  width: 320,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Cari nama karyawan...',
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

            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(40),
                  child: Text('Gagal memuat: $_error', style: const TextStyle(color: Colors.red)),
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
                          flex: 3,
                          child: Text('KARYAWAN',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('JAM MASUK',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('JAM PULANG',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('LOKASI / GPS',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF64748B), fontSize: 12)),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text('STATUS',
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
                          child: Text('Belum ada data absensi untuk filter atau tanggal ini.',
                              style: TextStyle(color: Colors.grey)),
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
                          final nama = (user['nama'] ?? item['nama'] ?? 'Karyawan').toString();
                          final jamMasuk = (item['jam_masuk'] ?? '-').toString();
                          final jamPulang = (item['jam_pulang'] ?? '-').toString();
                          final status = (item['status'] ?? '').toString().toLowerCase();
                          final isTerlambat = status.contains('terlambat') || status.contains('telat');

                          return InkWell(
                            onTap: () => _lihatDetailAbsensi(item),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
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
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
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
                                    flex: 2,
                                    child: Text(
                                      jamMasuk,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      jamPulang,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(color: Color(0xFF64748B)),
                                    ),
                                  ),
                                  const Expanded(
                                    flex: 2,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.location_on, color: Colors.green, size: 16),
                                        SizedBox(width: 4),
                                        Text('Valid GPS',
                                            style: TextStyle(
                                                fontSize: 12, color: Colors.green, fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: isTerlambat ? const Color(0xFFFEE2E2) : const Color(0xFFDCFCE7),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          isTerlambat ? 'Terlambat' : 'Tepat Waktu',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isTerlambat ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                                          ),
                                        ),
                                      ),
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
        ),
      ),
    );
  }
}
