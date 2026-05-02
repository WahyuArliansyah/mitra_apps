import 'package:flutter/material.dart';

class FormPenugasanDialog extends StatefulWidget {
  final List<Map<String, dynamic>> listKelas;
  final List<Map<String, dynamic>> listMapel;
  final Future<void> Function(
    List<String> idKelasList,
    List<String> idMapelList,
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

  List<String?> idKelasList = [null];
  List<String?> idMapelList = [null];
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

  Widget _tombolTambah(String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Row(
      children: [
        Icon(Icons.add_circle_outline, color: _primary, size: 20),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: _primary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
              // KELAS
              const Text(
                'Kelas',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                idKelasList.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _inputDeco(
                            'Kelas ${i + 1}',
                            Icons.class_rounded,
                          ),
                          value: idKelasList[i],
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
                          onChanged: (v) => setState(() => idKelasList[i] = v),
                        ),
                      ),
                      if (idKelasList.length > 1) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => idKelasList.removeAt(i)),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _tombolTambah(
                'Tambah Kelas',
                () => setState(() => idKelasList.add(null)),
              ),

              const SizedBox(height: 16),

              // MAPEL
              const Text(
                'Mata Pelajaran',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              ...List.generate(
                idMapelList.length,
                (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          decoration: _inputDeco(
                            'Mapel ${i + 1}',
                            Icons.menu_book_rounded,
                          ),
                          value: idMapelList[i],
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
                          onChanged: (v) => setState(() => idMapelList[i] = v),
                        ),
                      ),
                      if (idMapelList.length > 1) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () => setState(() => idMapelList.removeAt(i)),
                          child: const Icon(
                            Icons.remove_circle_outline,
                            color: Colors.redAccent,
                            size: 22,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              _tombolTambah(
                'Tambah Mapel',
                () => setState(() => idMapelList.add(null)),
              ),

              const SizedBox(height: 16),

              // TAHUN AJARAN
              TextField(
                controller: tahunCtrl,
                decoration: _inputDeco(
                  'Tahun Ajaran',
                  Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(height: 16),

              // SEMESTER
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
            if (idKelasList.any((k) => k == null) ||
                idMapelList.any((m) => m == null)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Semua kelas dan mata pelajaran wajib dipilih!',
                  ),
                  backgroundColor: Colors.redAccent,
                ),
              );
              return;
            }
            await widget.onSimpan(
              idKelasList.cast<String>(),
              idMapelList.cast<String>(),
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
