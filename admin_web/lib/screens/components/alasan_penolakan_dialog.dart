import 'package:flutter/material.dart';

class AlasanPenolakanDialog extends StatefulWidget {
  final String namaKaryawan;
  final String jenisCuti;

  const AlasanPenolakanDialog({
    super.key,
    required this.namaKaryawan,
    required this.jenisCuti,
  });

  static Future<String?> show(
    BuildContext context, {
    required String namaKaryawan,
    required String jenisCuti,
  }) async {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlasanPenolakanDialog(
        namaKaryawan: namaKaryawan,
        jenisCuti: jenisCuti,
      ),
    );
  }

  @override
  State<AlasanPenolakanDialog> createState() => _AlasanPenolakanDialogState();
}

class _AlasanPenolakanDialogState extends State<AlasanPenolakanDialog> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Tolak Pengajuan ${widget.jenisCuti}'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Berikan alasan penolakan cuti untuk ${widget.namaKaryawan}:',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Contoh: Jadwal bertabrakan dengan event penting...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
          onPressed: () {
            final text = _controller.text.trim();
            Navigator.pop(context, text.isNotEmpty ? text : 'Ditolak oleh admin');
          },
          child: const Text('Tolak Cuti', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
