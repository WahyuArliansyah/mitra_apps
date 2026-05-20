import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BuatMateriView extends StatefulWidget {
  final String idGuru;

  const BuatMateriView({super.key, required this.idGuru});

  @override
  State<BuatMateriView> createState() => _BuatMateriViewState();
}

class _BuatMateriViewState extends State<BuatMateriView> {
  final supabase = Supabase.instance.client;
  static const _navy = Color(0xFF0F2D5C);

  final _judulCtrl = TextEditingController();
  final _deskripsiCtrl = TextEditingController();

  String? _idKelasTerpilih;
  String? _idMapelTerpilih;
  String _semester = '1';
  String _tahunAjaran = '${DateTime.now().year}/${DateTime.now().year + 1}';

  List<Map<String, dynamic>> _listKelas = [];
  List<Map<String, dynamic>> _listMapel = [];
  List<Map<String, dynamic>> _penugasanGuru = [];

  PlatformFile? _fileTerpilih;
  bool _isLoading = false;
  bool _isUploading = false;

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

  // Ambil data penugasan guru untuk mengisi dropdown kelas dan mapel
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

  // Update daftar mapel saat kelas berubah
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

  // Pilih file menggunakan file_picker
  Future<void> _pilihFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'jpg',
        'png',
        'ppt',
        'pptx',
      ],
    );
    if (result != null) {
      setState(() => _fileTerpilih = result.files.first);
    }
  }

  // Upload file ke Supabase Storage dan dapatkan URL publiknya
  Future<String?> _uploadFile() async {
    if (_fileTerpilih == null) return null;
    setState(() => _isUploading = true);
    try {
      final file = File(_fileTerpilih!.path!);
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_fileTerpilih!.name}';
      final path = 'materi/$fileName';

      // Mengirim file ke Supabase Storage bernama materi-files
      await supabase.storage.from('materi-files').upload(path, file);
      return supabase.storage.from('materi-files').getPublicUrl(path);
    } catch (e) {
      debugPrint('Upload error: $e');
      return null;
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  // Simpan data materi ke database
  Future<void> _simpan() async {
    if (_judulCtrl.text.isEmpty ||
        _idKelasTerpilih == null ||
        _idMapelTerpilih == null) {
      _showSnackbar('Judul, kelas, dan mapel wajib diisi!', isError: true);
      return;
    }

    if (_fileTerpilih == null) {
      _showSnackbar('File materi wajib diunggah!', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final urlFile = await _uploadFile();

      // Sesuaikan nama kolom dengan struktur tabel 'materi' di Supabase kamu
      await supabase.from('materi').insert({
        'id_guru': widget.idGuru,
        'id_kelas': _idKelasTerpilih,
        'id_mapel': _idMapelTerpilih,
        'judul_materi': _judulCtrl.text.trim(),
        'deskripsi': _deskripsiCtrl.text.trim(),
        'url_file': urlFile,
        'semester': _semester,
        'tahun_ajaran': _tahunAjaran,
      });

      // Setelah berhasil menyimpan materi, kirim notifikasi ke siswa
      await _kirimNotifikasi();

      if (mounted) {
        Navigator.pop(context);
        _showSnackbar('Materi berhasil dibagikan!');
      }
    } catch (e) {
      _showSnackbar('Gagal mengunggah materi: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Kirim notifikasi ke semua siswa di kelas yang dipilih
  Future<void> _kirimNotifikasi() async {
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

      // Bikin list notifikasi untuk setiap siswa
      final notifList = (siswaList as List)
          .map(
            (s) => {
              'id_siswa': s['id_siswa'],
              'judul': 'Materi Baru: ${_judulCtrl.text.trim()}',
              'pesan':
                  'Guru telah membagikan materi baru pada mata pelajaran $namaMapel. Silakan diunduh dan dipelajari.',
              'is_read': false,
              // 'created_at' otomatis diisi oleh Supabase
            },
          )
          .toList();

      // Arahkan ke database
      await supabase.from('notifikasi').insert(notifList);
    } catch (e) {
      debugPrint('Error kirim notifikasi materi: $e');
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
    prefixIcon: Icon(icon, color: _navy),
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
      borderSide: const BorderSide(color: _navy, width: 2),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        toolbarHeight: 70,
        title: const Text(
          'Upload Materi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _judulCtrl,
              decoration: _inputDeco('Judul Materi', Icons.menu_book_rounded),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _deskripsiCtrl,
              maxLines: 3,
              decoration: _inputDeco(
                'Deskripsi (opsional)',
                Icons.description_rounded,
              ),
            ),
            const SizedBox(height: 16),

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

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _semester,
                    isExpanded: true,
                    decoration: _inputDeco('Semester', Icons.bookmark_rounded),
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Semester 1')),
                      DropdownMenuItem(value: '2', child: Text('Semester 2')),
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
            const SizedBox(height: 20),

            const Text(
              'File Materi (Wajib)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pilihFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _fileTerpilih != null ? _navy : Colors.grey.shade200,
                    width: _fileTerpilih != null ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _fileTerpilih != null
                          ? Icons.insert_drive_file_rounded
                          : Icons.cloud_upload_rounded,
                      color: _fileTerpilih != null ? _navy : Colors.grey,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _fileTerpilih != null
                            ? _fileTerpilih!.name
                            : 'Pilih file (PDF, Word, PPT, JPG)',
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
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading || _isUploading ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _navy,
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
                        'Bagikan Materi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
