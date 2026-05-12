import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuatTugasView extends StatefulWidget {
  final String idGuru;

  const BuatTugasView({super.key, required this.idGuru});

  @override
  State<BuatTugasView> createState() => _BuatTugasViewState();
}

class _BuatTugasViewState extends State<BuatTugasView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);

  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();

  String? _idKelasTerpilih;
  String? _idMapelTerpilih;
  String _typeTugas = 'teori';
  String _metode = 'upload';
  String _semester = '1';
  String _tahunAjaran = '${DateTime.now().year}/${DateTime.now().year + 1}';
  DateTime? _deadline;

  List<Map<String, dynamic>> _listKelas = [];
  List<Map<String, dynamic>> _listMapel = [];
  List<Map<String, dynamic>> _penugasanGuru = [];

  PlatformFile? _fileTerpilih;
  bool _isLoading = false;
  bool _isUploading = false;

  // Logika visibilitas
  // File lampiran tampil HANYA jika: teori + upload
  bool get _tampilFile => _typeTugas == 'teori' && _metode == 'upload';

  // Metode penilaian tampil HANYA jika: teori
  // Praktikum otomatis = manual
  bool get _tampilMetode => _typeTugas == 'teori';

  // Deadline tampil HANYA jika: teori + upload
  bool get _tampilDeadline => _typeTugas == 'teori' && _metode == 'upload';

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  @override
  void dispose() {
    _judulCtrl.dispose();
    _deskripsiCtrl.dispose();
    super.dispose();
  }

  Future<void> _ambilData() async {
    try {
      final penugasan = await supabase
          .from('penugasan_guru')
          .select(
            '*, kelas(id, nama_kelas, jurusan), mata_pelajaran(id, nama_mapel)',
          )
          .eq('id_guru', widget.idGuru);

      if (!mounted) return;
      setState(() {
        _penugasanGuru = List<Map<String, dynamic>>.from(penugasan);
        final kelasMap = <String, Map<String, dynamic>>{};
        for (final p in _penugasanGuru) {
          final k = p['kelas'];
          if (k != null) kelasMap[k['id'].toString()] = k;
        }
        _listKelas = kelasMap.values.toList();
      });
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void _updateMapel() {
    final mapelMap = <String, Map<String, dynamic>>{};
    for (final p in _penugasanGuru) {
      if (p['kelas']?['id'].toString() == _idKelasTerpilih) {
        final m = p['mata_pelajaran'];
        if (m != null) mapelMap[m['id'].toString()] = m;
      }
    }
    setState(() {
      _listMapel = mapelMap.values.toList();
      _idMapelTerpilih = null;
    });
  }

  void _onTypeTugasChanged(String type) {
    setState(() {
      _typeTugas = type;
      // Praktikum otomatis pakai manual & reset file
      if (type == 'praktikum') {
        _metode = 'manual';
        _fileTerpilih = null;
        _deadline = null;
      } else {
        _metode = 'upload';
      }
    });
  }

  void _onMetodeChanged(String metode) {
    setState(() {
      _metode = metode;
      // Jika ganti ke manual, reset file & deadline
      if (metode == 'manual') {
        _fileTerpilih = null;
        _deadline = null;
      }
    });
  }

  Future<void> _kirimNotifikasi(String idTugas) async {
    try {
      // Ambil semua siswa di kelas yang dipilih
      final siswaList = await supabase
          .from('siswa')
          .select('id_siswa')
          .eq('id_kelas', _idKelasTerpilih!);

      if (siswaList.isEmpty) return;

      // Ambil nama mapel untuk isi notifikasi
      final namaMapel = _listMapel.firstWhere(
        (m) => m['id'].toString() == _idMapelTerpilih,
        orElse: () => {'nama_mapel': 'Mata Pelajaran'},
      )['nama_mapel'];

      // Insert notifikasi untuk setiap siswa
      final notifList = (siswaList as List)
          .map(
            (s) => {
              'id_siswa': s['id_siswa'],
              'judul': 'Tugas Baru: ${_judulCtrl.text.trim()}',
              'pesan':
                  'Guru telah memberikan tugas baru pada mata pelajaran $namaMapel. '
                  'Tenggat waktu: ${_deadline != null ? '${_deadline!.day}/${_deadline!.month}/${_deadline!.year}' : '-'}',
              'is_read': false,
            },
          )
          .toList();

      await supabase.from('notifikasi').insert(notifList);
    } catch (e) {
      debugPrint('Error kirim notifikasi: $e');
    }
  }

  Future<void> _pilihFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'jpg', 'png'],
    );
    if (result != null) {
      setState(() => _fileTerpilih = result.files.first);
    }
  }

  Future<String?> _uploadFile() async {
    if (_fileTerpilih == null) return null;
    setState(() => _isUploading = true);
    try {
      final file = File(_fileTerpilih!.path!);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_fileTerpilih!.name}';
      final path = 'tugas/$fileName';
      await supabase.storage.from('tugas-files').upload(path, file);
      return supabase.storage.from('tugas-files').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _simpan() async {
    if (_judulCtrl.text.isEmpty ||
        _idKelasTerpilih == null ||
        _idMapelTerpilih == null) {
      _showSnackbar('Judul, kelas, dan mapel wajib diisi!', isError: true);
      return;
    }
    debugPrint('Deadline yang akan disimpan: ${_deadline?.toIso8601String()}');
    if (_tampilDeadline && _deadline == null) {
      _showSnackbar('Tenggat waktu wajib diisi!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? urlFile;
      if (_tampilFile && _fileTerpilih != null) {
        urlFile = await _uploadFile();
      }

      // Insert tugas dan ambil ID nya
      final result = await supabase
          .from('tugas')
          .insert({
            'id_guru': widget.idGuru,
            'id_kelas': _idKelasTerpilih,
            'id_mapel': _idMapelTerpilih,
            'judul_tugas': _judulCtrl.text.trim(),
            'deskripsi': _deskripsiCtrl.text.trim(),
            'url_file_materi': urlFile,
            'type_tugas': _typeTugas,
            'metode': _metode,
            'semester': _semester,
            'tahun_ajaran': _tahunAjaran,
            'tenggat_waktu': _deadline?.toIso8601String(),
          })
          .select('id')
          .single();

      // Kirim notifikasi hanya jika teori + upload
      if (_typeTugas == 'teori' && _metode == 'upload') {
        await _kirimNotifikasi(result['id']);
      }

      if (mounted) {
        Navigator.pop(context);
        _showSnackbar('Tugas berhasil dibuat!');
      }
    } catch (e) {
      _showSnackbar('Gagal membuat tugas: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Buat Tugas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Judul ──
            TextField(
              controller: _judulCtrl,
              decoration: _inputDeco('Judul Tugas', Icons.title_rounded),
            ),
            const SizedBox(height: 16),

            // ── Deskripsi ──
            TextField(
              controller: _deskripsiCtrl,
              maxLines: 3,
              decoration: _inputDeco(
                'Deskripsi (opsional)',
                Icons.description_rounded,
              ),
            ),
            const SizedBox(height: 16),

            // Milih tipe tugas
            _sectionLabel('Tipe Tugas'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _toggleBtn(
                    label: 'Teori',
                    icon: Icons.menu_book_rounded,
                    isActive: _typeTugas == 'teori',
                    color: _primary,
                    onTap: () => _onTypeTugasChanged('teori'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _toggleBtn(
                    label: 'Praktikum',
                    icon: Icons.science_rounded,
                    isActive: _typeTugas == 'praktikum',
                    color: const Color(0xFFD97706),
                    onTap: () => _onTypeTugasChanged('praktikum'),
                  ),
                ),
              ],
            ),

            // Jika praktikum, tampilkan info tambahan
            if (_typeTugas == 'praktikum') ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3E0),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFD97706).withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Color(0xFFD97706),
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tugas praktikum dinilai secara manual oleh guru.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Memilih metode penilaian (hanya untuk teori)
            if (_tampilMetode) ...[
              _sectionLabel('Metode Penilaian'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _toggleBtn(
                      label: 'Siswa Upload',
                      icon: Icons.upload_file_rounded,
                      isActive: _metode == 'upload',
                      color: const Color(0xFF059669),
                      onTap: () => _onMetodeChanged('upload'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _toggleBtn(
                      label: 'Input Manual',
                      icon: Icons.edit_note_rounded,
                      isActive: _metode == 'manual',
                      color: const Color(0xFF7C3AED),
                      onTap: () => _onMetodeChanged('manual'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Milih kelas
            DropdownButtonFormField<String>(
              value: _idKelasTerpilih,
              decoration: _inputDeco('Pilih Kelas', Icons.class_rounded),
              hint: const Text('Pilih kelas'),
              isExpanded: true,
              items: _listKelas
                  .map(
                    (k) => DropdownMenuItem(
                      value: k['id'].toString(),
                      child: Text(
                        '${k['nama_kelas']} - ${k['jurusan']}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() => _idKelasTerpilih = v);
                _updateMapel();
              },
            ),
            const SizedBox(height: 16),

            // Mapel disesuaikan dengan kelas yang dipilih
            DropdownButtonFormField<String>(
              value: _idMapelTerpilih,
              decoration: _inputDeco(
                'Pilih Mata Pelajaran',
                Icons.menu_book_rounded,
              ),
              hint: const Text('Pilih mata pelajaran'),
              isExpanded: true,
              items: _listMapel
                  .map(
                    (m) => DropdownMenuItem(
                      value: m['id'].toString(),
                      child: Text(
                        m['nama_mapel'],
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _idMapelTerpilih = v),
            ),
            const SizedBox(height: 16),

            // Milih semester dan tahun ajaran
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _semester,
                    isExpanded: true,
                    decoration: _inputDeco('Semester', Icons.book_rounded),
                    items: const [
                      DropdownMenuItem(
                        value: '1',
                        child: Text(
                          'Semester 1',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DropdownMenuItem(
                        value: '2',
                        child: Text(
                          'Semester 2',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _semester = v!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    onChanged: (v) => _tahunAjaran = v,
                    controller: TextEditingController(text: _tahunAjaran),
                    decoration: _inputDeco(
                      'Tahun Ajaran',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Deadline (hanya teori + upload) ──
            if (_tampilDeadline) ...[
              _sectionLabel('Tenggat Waktu'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null && mounted) {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      setState(
                        () => _deadline = DateTime(
                          picked.year,
                          picked.month,
                          picked.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _deadline != null
                          ? _primary
                          : Colors.grey.shade200,
                      width: _deadline != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: _deadline != null ? _primary : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _deadline == null
                              ? 'Pilih tenggat waktu'
                              : '${_deadline!.day}/${_deadline!.month}/${_deadline!.year} ${_deadline!.hour.toString().padLeft(2, '0')}:${_deadline!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: _deadline == null
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ),
                      if (_deadline != null)
                        GestureDetector(
                          onTap: () => setState(() => _deadline = null),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // File lampiran (hanya teori + upload)
            if (_tampilFile) ...[
              _sectionLabel('File Lampiran (opsional)'),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pilihFile,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _fileTerpilih != null
                          ? _primary
                          : Colors.grey.shade200,
                      width: _fileTerpilih != null ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _fileTerpilih != null
                            ? Icons.insert_drive_file_rounded
                            : Icons.attach_file_rounded,
                        color: _fileTerpilih != null ? _primary : Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _fileTerpilih != null
                              ? _fileTerpilih!.name
                              : 'Pilih file (PDF, Word, Excel, JPG, PNG)',
                          style: TextStyle(
                            color: _fileTerpilih != null
                                ? Colors.black87
                                : Colors.grey,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (_fileTerpilih != null)
                        GestureDetector(
                          onTap: () => setState(() => _fileTerpilih = null),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            const SizedBox(height: 12),

            // Style tombol simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isUploading ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading || _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan Tugas',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: Color(0xFF1A1F36),
    ),
  );

  Widget _toggleBtn({
    required String label,
    required IconData icon,
    required bool isActive,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? color : Colors.grey.shade200,
            width: isActive ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isActive ? color : Colors.grey, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? color : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
