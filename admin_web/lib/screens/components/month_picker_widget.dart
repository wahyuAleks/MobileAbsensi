import 'package:flutter/material.dart';

class MonthPickerWidget extends StatelessWidget {
  final int bulan;
  final int tahun;
  final Function(int bulan, int tahun) onChanged;

  const MonthPickerWidget({
    super.key,
    required this.bulan,
    required this.tahun,
    required this.onChanged,
  });

  static const List<String> namaBulan = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButton<int>(
            value: bulan,
            underline: const SizedBox(),
            items: List.generate(12, (i) {
              return DropdownMenuItem<int>(
                value: i + 1,
                child: Text(namaBulan[i], style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }),
            onChanged: (val) {
              if (val != null) onChanged(val, tahun);
            },
          ),
          const SizedBox(width: 8),
          DropdownButton<int>(
            value: tahun,
            underline: const SizedBox(),
            items: [2024, 2025, 2026, 2027].map((y) {
              return DropdownMenuItem<int>(
                value: y,
                child: Text('$y', style: const TextStyle(fontWeight: FontWeight.w600)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) onChanged(bulan, val);
            },
          ),
        ],
      ),
    );
  }
}
