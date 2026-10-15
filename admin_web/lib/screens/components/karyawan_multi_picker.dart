import 'package:flutter/material.dart';

class KaryawanMultiPicker extends StatefulWidget {
  final List<Map<String, dynamic>> employees;
  final Set<int> selectedIds;
  final ValueChanged<Set<int>> onChanged;
  final double maxHeight;

  const KaryawanMultiPicker({
    super.key,
    required this.employees,
    required this.selectedIds,
    required this.onChanged,
    this.maxHeight = 260,
  });

  @override
  State<KaryawanMultiPicker> createState() => _KaryawanMultiPickerState();
}

class _KaryawanMultiPickerState extends State<KaryawanMultiPicker> {
  String _searchQuery = '';
  bool _onlySelected = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleEmployee(int id) {
    final updated = Set<int>.from(widget.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    widget.onChanged(updated);
  }

  void _selectAll(List<Map<String, dynamic>> targetList) {
    final updated = Set<int>.from(widget.selectedIds);
    for (final emp in targetList) {
      final id = int.tryParse(emp['id'].toString());
      if (id != null) updated.add(id);
    }
    widget.onChanged(updated);
  }

  void _deselectAll() {
    widget.onChanged({});
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchQuery.trim().toLowerCase();

    final filtered = widget.employees.where((emp) {
      final id = int.tryParse(emp['id'].toString());
      if (id == null) return false;

      if (_onlySelected && !widget.selectedIds.contains(id)) {
        return false;
      }

      if (query.isEmpty) return true;

      final nama = (emp['nama']?.toString() ?? '').toLowerCase();
      final email = (emp['email']?.toString() ?? '').toLowerCase();
      final jabatan = (emp['jabatan']?.toString() ?? '').toLowerCase();
      return nama.contains(query) ||
          email.contains(query) ||
          jabatan.contains(query);
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header info & Actions
        Row(
          children: [
            Text(
              'Pilih Karyawan (${widget.selectedIds.length} dipilih)',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1F2937),
              ),
            ),
            const Spacer(),
            if (filtered.isNotEmpty)
              TextButton.icon(
                onPressed: () => _selectAll(filtered),
                icon: const Icon(Icons.select_all_rounded, size: 16),
                label: Text(
                  _searchQuery.isNotEmpty
                      ? 'Pilih Hasil (${filtered.length})'
                      : 'Pilih Semua',
                  style: const TextStyle(fontSize: 12),
                ),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            if (widget.selectedIds.isNotEmpty) ...[
              const SizedBox(width: 4),
              TextButton.icon(
                onPressed: _deselectAll,
                icon: const Icon(Icons.clear_all_rounded, size: 16),
                label: const Text('Batal Semua', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Search bar & Filter
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 38,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari nama, email, atau jabatan karyawan...',
                    hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 18, color: Color(0xFF6B7280)),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 16),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFF4338CA), width: 1.5),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
            ),
            if (widget.selectedIds.isNotEmpty) ...[
              const SizedBox(width: 8),
              FilterChip(
                selected: _onlySelected,
                label: Text(
                  'Terpilih (${widget.selectedIds.length})',
                  style: TextStyle(
                    fontSize: 12,
                    color: _onlySelected
                        ? const Color(0xFF4338CA)
                        : const Color(0xFF4B5563),
                    fontWeight: _onlySelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                selectedColor: const Color(0xFFEEF2FF),
                checkmarkColor: const Color(0xFF4338CA),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                side: BorderSide(
                  color: _onlySelected ? const Color(0xFF4338CA) : const Color(0xFFE5E7EB),
                ),
                onSelected: (val) => setState(() => _onlySelected = val),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),

        // Scrollable Employee List / Grid
        Container(
          constraints: BoxConstraints(maxHeight: widget.maxHeight),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_search_rounded,
                          size: 32,
                          color: Color(0xFF9CA3AF),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Tidak ada karyawan cocok dengan "$_searchQuery"'
                              : 'Tidak ada data karyawan.',
                          style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 520;
                    final crossAxisCount = isWide ? 2 : 1;

                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisExtent: 60,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemBuilder: (context, index) {
                        final emp = filtered[index];
                        final id = int.tryParse(emp['id'].toString())!;
                        final isSelected = widget.selectedIds.contains(id);
                        final nama = emp['nama']?.toString() ?? 'Karyawan';
                        final email = emp['email']?.toString() ?? '';
                        final jabatan = emp['jabatan']?.toString() ?? '';

                        final sub = [
                          if (jabatan.isNotEmpty) jabatan,
                          if (email.isNotEmpty) email,
                        ].join(' • ');

                        return Material(
                          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => _toggleEmployee(id),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF4338CA)
                                      : const Color(0xFFE5E7EB),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: Checkbox(
                                      value: isSelected,
                                      activeColor: const Color(0xFF4338CA),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      onChanged: (_) => _toggleEmployee(id),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: isSelected
                                        ? const Color(0xFF4338CA)
                                        : const Color(0xFFE0E7FF),
                                    child: Text(
                                      nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.white
                                            : const Color(0xFF4338CA),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          nama,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSelected
                                                ? const Color(0xFF312E81)
                                                : const Color(0xFF1F2937),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        if (sub.isNotEmpty)
                                          Text(
                                            sub,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF6B7280),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
        ),

        // Quick Selected Chips Preview Bar (when there are selections)
        if (widget.selectedIds.isNotEmpty) ...[
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                const Text(
                  'Terpilih: ',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7280)),
                ),
                ...widget.employees
                    .where((e) => widget.selectedIds.contains(int.tryParse(e['id'].toString())))
                    .map((e) {
                  final id = int.tryParse(e['id'].toString())!;
                  final nama = e['nama']?.toString() ?? 'Karyawan';
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Chip(
                      label: Text(nama, style: const TextStyle(fontSize: 11)),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => _toggleEmployee(id),
                      backgroundColor: const Color(0xFFEEF2FF),
                      labelPadding: const EdgeInsets.only(left: 4),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      side: const BorderSide(color: Color(0xFFC7D2FE)),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
