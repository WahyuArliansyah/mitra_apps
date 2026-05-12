import 'package:flutter/material.dart';

class FilterBarMapping extends StatelessWidget {
  final String filterTahun;
  final String filterSemester;
  final List<String> tahunList;
  final ValueChanged<String> onTahunChanged;
  final ValueChanged<String> onSemesterChanged;

  const FilterBarMapping({
    super.key,
    required this.filterTahun,
    required this.filterSemester,
    required this.tahunList,
    required this.onTahunChanged,
    required this.onSemesterChanged,
  });

  InputDecoration _filterDeco() => InputDecoration(
    filled: true,
    fillColor: Colors.white.withOpacity(0.9),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF7C3AED),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              value: filterTahun,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              decoration: _filterDeco(),
              items: tahunList
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => onTahunChanged(v!),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: filterSemester,
              dropdownColor: Colors.white,
              style: const TextStyle(color: Colors.black87, fontSize: 13),
              decoration: _filterDeco(),
              items: ['Semua', '1', '2']
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s == 'Semua' ? 'Semua Semester' : 'Semester $s',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => onSemesterChanged(v!),
            ),
          ),
        ],
      ),
    );
  }
}
