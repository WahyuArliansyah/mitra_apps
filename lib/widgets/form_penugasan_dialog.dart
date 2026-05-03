import 'package:flutter/material.dart';

class FormPenugasanDialog extends StatefulWidget {
  final List<Map<String, dynamic>> listKelas;
  final List<Map<String, dynamic>> listMapel;
  final Future<void> Function(
    List<Map<String, String>> pasangan,
    String tahunAjaran,
    String semester,
  )
  onSimpan;

  const FormPenugasanDialog({
    super.key,
    required this.listKelas,
    required this.listMapel,
    required this.onSimpan,
  });

  @override
  State<FormPenugasanDialog> createState() => _FormPenugasanDialogState();
}

class _FormPenugasanDialogState extends State<FormPenugasanDialog> {
  static const _primary = Color(0xFF7C3AED);

  // Struktur: 1 kelas → list mapel
  // [{ 'kelas': 'id_kelas', 'mapelList': ['id_mapel1', 'id_mapel2'] }]
  List<Map<String, dynamic>> _kelasMapel = [
    {
      'kelas': null,
      'mapelList': <String?>[null],
    },
  ];

  late TextEditingController tahunCtrl;
  String semester = '1';

  @override
  void initState() {
    super.initState();
    tahunCtrl = TextEditingController(
      text: '${DateTime.now().year}/${DateTime.now().year + 1}',
    );
  }

  @override
  void dispose() {
    tahunCtrl.dispose();
    super.dispose();
  }

  InputDecoration _inputDeco(String label, IconData icon) => InputDecoration(
    labelText: label,
    prefixIcon: Icon(icon, color: _primary),
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _primary, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      title: const Text('Tambah Penugasan'),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── List Kelas ──
              ...List.generate(_kelasMapel.length, (i) => _buildKelasItem(i)),

              // Tombol tambah kelas
              const SizedBox(height: 4),
              GestureDetector(
                onTap: () => setState(
                  () => _kelasMapel.add({
                    'kelas': null,
                    'mapelList': <String?>[null],
                  }),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: _primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Tambah Kelas',
                      style: TextStyle(
                        color: _primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ── Tahun Ajaran ──
              TextField(
                controller: tahunCtrl,
                decoration: _inputDeco(
                  'Tahun Ajaran',
                  Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // ── Semester ──
              DropdownButtonFormField<String>(
                decoration: _inputDeco('Semester', Icons.book_rounded),
                value: semester,
                items: const [
                  DropdownMenuItem(value: '1', child: Text('Semester 1')),
                  DropdownMenuItem(value: '2', child: Text('Semester 2')),
                ],
                onChanged: (v) => setState(() => semester = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: () async {
            // Validasi
            for (final km in _kelasMapel) {
              if (km['kelas'] == null) {
                _showSnackbar(context, 'Pilih kelas terlebih dahulu!');
                return;
              }
              final mapelList = km['mapelList'] as List<String?>;
              if (mapelList.any((m) => m == null)) {
                _showSnackbar(context, 'Pilih semua mata pelajaran!');
                return;
              }
            }

            // Generate pasangan: setiap kelas × mapelnya
            final List<Map<String, String>> pasangan = [];
            for (final km in _kelasMapel) {
              final idKelas = km['kelas'] as String;
              final mapelList = km['mapelList'] as List<String?>;
              for (final idMapel in mapelList) {
                pasangan.add({'kelas': idKelas, 'mapel': idMapel!});
              }
            }

            await widget.onSimpan(pasangan, tahunCtrl.text, semester);
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildKelasItem(int i) {
    final km = _kelasMapel[i];
    final mapelList = km['mapelList'] as List<String?>;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header kelas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Kelas ${i + 1}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _primary,
                ),
              ),
              if (_kelasMapel.length > 1)
                GestureDetector(
                  onTap: () => setState(() => _kelasMapel.removeAt(i)),
                  child: const Icon(
                    Icons.remove_circle_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdown Kelas
          DropdownButtonFormField<String>(
            isExpanded: true,
            decoration: _inputDeco('Pilih Kelas', Icons.class_rounded),
            value: km['kelas'],
            hint: const Text('Pilih kelas'),
            items: widget.listKelas
                .map(
                  (k) => DropdownMenuItem(
                    value: k['id'].toString(),
                    child: Text(
                      '${k['nama_kelas']} - ${k['jurusan']}',
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => km['kelas'] = v),
          ),

          const SizedBox(height: 12),

          // Divider mapel
          Row(
            children: [
              const Icon(Icons.menu_book_rounded, size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Mata Pelajaran',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // List Mapel untuk kelas ini
          ...List.generate(
            mapelList.length,
            (j) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      decoration: _inputDeco(
                        'Mapel ${j + 1}',
                        Icons.menu_book_rounded,
                      ),
                      value: mapelList[j],
                      hint: const Text('Pilih mapel'),
                      items: widget.listMapel
                          .map(
                            (m) => DropdownMenuItem(
                              value: m['id'].toString(),
                              child: Text(
                                '${m['nama_mapel']} (${m['kode_mapel']})',
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => mapelList[j] = v),
                    ),
                  ),
                  if (mapelList.length > 1) ...[
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => setState(() => mapelList.removeAt(j)),
                      child: const Icon(
                        Icons.remove_circle_outline,
                        color: Colors.redAccent,
                        size: 20,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Tombol tambah mapel di kelas ini
          GestureDetector(
            onTap: () => setState(() => mapelList.add(null)),
            child: Row(
              children: [
                Icon(Icons.add_circle_outline, color: _primary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Tambah Mapel',
                  style: TextStyle(
                    color: _primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
