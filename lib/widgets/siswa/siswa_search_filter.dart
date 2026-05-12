import 'package:flutter/material.dart';

class SiswaSearchFilter extends StatelessWidget {
  final TextEditingController searchController;
  final List<Map<String, dynamic>> listKelas;
  final String? filterKelasId;
  final int jumlahDitemukan;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onFilterKelas;

  static const _primary = Color(0xFF4338CA);

  const SiswaSearchFilter({
    super.key,
    required this.searchController,
    required this.listKelas,
    required this.filterKelasId,
    required this.jumlahDitemukan,
    required this.onSearch,
    required this.onFilterKelas,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          // Search
          TextField(
            controller: searchController,
            onChanged: onSearch,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Cari nama atau NIS...',
              hintStyle: const TextStyle(color: Colors.white60),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: Colors.white70,
              ),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        searchController.clear();
                        onSearch('');
                        FocusManager.instance.primaryFocus?.unfocus();
                      },
                    )
                  : null,
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 10),
          // Filter Kelas
          DropdownButtonFormField<String>(
            value: filterKelasId,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87, fontSize: 13),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white.withOpacity(0.9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              prefixIcon: const Icon(
                Icons.class_rounded,
                color: _primary,
                size: 20,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
            hint: const Text('Semua Kelas'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua Kelas'),
              ),
              ...listKelas.map(
                (k) => DropdownMenuItem<String>(
                  value: k['id'].toString(),
                  child: Text(k['nama_kelas']),
                ),
              ),
            ],
            onChanged: onFilterKelas,
          ),
          // Info jumlah
          if (jumlahDitemukan > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '$jumlahDitemukan siswa ditemukan',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
