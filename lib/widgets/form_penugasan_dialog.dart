import 'package:flutter/material.dart';

class FormPenugasanDialog extends StatefulWidget {
  final List<Map<String, dynamic>> listKelas;
  final List<Map<String, dynamic>> listMapel;
  final Future<void> Function(
    List<Map<String, String>> pasangan, // ← berubah
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

  // Setiap data kelas & mapel disimpan sebagai pasangan dalam list
  List<Map<String, String?>> _pasangan = [
    {'kelas': null, 'mapel': null},
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
    fillColor: Colors.grey.shade50,
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
              // data pasangan kelas & mapel
              const Text(
                'Pasangan Kelas & Mata Pelajaran',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),

              ...List.generate(
                _pasangan.length,
                (i) => Container(
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
                      // Header pasangan
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Kelas dan Mata Pelajaran ${i + 1}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _primary,
                            ),
                          ),
                          if (_pasangan.length > 1)
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _pasangan.removeAt(i)),
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
                        decoration: _inputDeco('Kelas', Icons.class_rounded),
                        value: _pasangan[i]['kelas'],
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
                        onChanged: (v) =>
                            setState(() => _pasangan[i]['kelas'] = v),
                      ),
                      const SizedBox(height: 10),

                      // Dropdown Mapel
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: _inputDeco(
                          'Mata Pelajaran',
                          Icons.menu_book_rounded,
                        ),
                        value: _pasangan[i]['mapel'],
                        hint: const Text('Pilih mata pelajaran'),
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
                        onChanged: (v) =>
                            setState(() => _pasangan[i]['mapel'] = v),
                      ),
                    ],
                  ),
                ),
              ),

              // Tombol tambah pasangan
              GestureDetector(
                onTap: () => setState(
                  () => _pasangan.add({'kelas': null, 'mapel': null}),
                ),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, color: _primary, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      'Tambah Kelas & Mapel',
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

              // ── TAHUN AJARAN ──
              TextField(
                controller: tahunCtrl,
                decoration: _inputDeco(
                  'Tahun Ajaran',
                  Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // ── SEMESTER ──
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
            // Validasi semua pasangan terisi
            final adaKosong = _pasangan.any(
              (p) => p['kelas'] == null || p['mapel'] == null,
            );
            if (adaKosong) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Semua pasangan kelas & mapel wajib diisi!'),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }

            await widget.onSimpan(
              _pasangan
                  .map((p) => {'kelas': p['kelas']!, 'mapel': p['mapel']!})
                  .toList(),
              tahunCtrl.text,
              semester,
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
