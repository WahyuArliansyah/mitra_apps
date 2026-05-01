import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailMappingGuruView extends StatefulWidget {
  final String idGuru;
  final String namaGuru;

  const DetailMappingGuruView({
    super.key,
    required this.idGuru,
    required this.namaGuru,
  });

  @override
  State<DetailMappingGuruView> createState() => _DetailMappingGuruViewState();
}

class _DetailMappingGuruViewState extends State<DetailMappingGuruView> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _listMapping = [];
  List<Map<String, dynamic>> _listKelas = [];
  List<Map<String, dynamic>> _listMapel = [];
  bool _isLoading = true;

  // Filter
  String _filterTahun = 'Semua';
  String _filterSemester = 'Semua';
  List<String> _tahunList = ['Semua'];

  static const _primary = Color(0xFF7C3AED);
  static const _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  Future<void> _ambilData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        supabase
            .from('penugasan_guru')
            .select(
              '*, kelas(nama_kelas, jurusan), mata_pelajaran(nama_mapel, kode_mapel)',
            )
            .eq('id_guru', widget.idGuru)
            .order('created_at', ascending: false),
        supabase
            .from('kelas')
            .select('id, nama_kelas, jurusan')
            .order('nama_kelas'),
        supabase
            .from('mata_pelajaran')
            .select('id, nama_mapel, kode_mapel')
            .order('nama_mapel'),
      ]);

      final mappings = List<Map<String, dynamic>>.from(results[0]);
      final tahunSet = mappings
          .map((m) => m['tahun_ajaran'].toString())
          .toSet()
          .toList();

      setState(() {
        _listMapping = mappings;
        _listKelas = List<Map<String, dynamic>>.from(results[1]);
        _listMapel = List<Map<String, dynamic>>.from(results[2]);
        _tahunList = ['Semua', ...tahunSet];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _listMapping.where((m) {
      final tahunMatch =
          _filterTahun == 'Semua' ||
          m['tahun_ajaran'].toString() == _filterTahun;
      final semesterMatch =
          _filterSemester == 'Semua' ||
          m['semester'].toString() == _filterSemester;
      return tahunMatch && semesterMatch;
    }).toList();
  }

  Future<void> _hapusMapping(String id) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Penugasan'),
        content: const Text('Yakin ingin menghapus penugasan ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (konfirmasi != true) return;
    await supabase.from('penugasan_guru').delete().eq('id', id);
    _ambilData();
  }

  void _tampilkanFormEdit(Map<String, dynamic> mapping) {
    String? idKelas = mapping['id_kelas'].toString();
    String? idMapel = mapping['id_mapel'].toString();
    final tahunCtrl = TextEditingController(text: mapping['tahun_ajaran']);
    String semester = mapping['semester'].toString();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: const Text('Edit Penugasan'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: _inputDeco('Kelas', Icons.class_rounded),
                    value: idKelas,
                    items: _listKelas
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
                    onChanged: (v) => setStateDialog(() => idKelas = v),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: _inputDeco(
                      'Mata Pelajaran',
                      Icons.menu_book_rounded,
                    ),
                    value: idMapel,
                    items: _listMapel
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
                    onChanged: (v) => setStateDialog(() => idMapel = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: tahunCtrl,
                    decoration: _inputDeco(
                      'Tahun Ajaran',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: _inputDeco('Semester', Icons.book_rounded),
                    value: semester,
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Semester 1')),
                      DropdownMenuItem(value: '2', child: Text('Semester 2')),
                    ],
                    onChanged: (v) => setStateDialog(() => semester = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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
                if (idKelas == null || idMapel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kelas dan mata pelajaran wajib dipilih!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                await supabase
                    .from('penugasan_guru')
                    .update({
                      'id_kelas': idKelas,
                      'id_mapel': idMapel,
                      'tahun_ajaran': tahunCtrl.text,
                      'semester': semester,
                    })
                    .eq('id', mapping['id'].toString());

                if (ctx.mounted) Navigator.pop(ctx);
                _ambilData();
              },
              child: const Text('Simpan Perubahan'),
            ),
          ],
        ),
      ),
    );
  }

  void _tampilkanFormTambah() {
    String? idKelas;
    String? idMapel;
    final tahunCtrl = TextEditingController(
      text: '${DateTime.now().year}/${DateTime.now().year + 1}',
    );
    String semester = '1';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: const Text('Tambah Penugasan'),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Pilih Kelas
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: _inputDeco('Kelas', Icons.class_rounded),
                    value: idKelas,
                    items: _listKelas
                        .map(
                          (k) => DropdownMenuItem(
                            value: k['id'].toString(),
                            child: Text(
                              '${k['nama_kelas']} - ${k['jurusan']}',
                              overflow: TextOverflow.ellipsis, // ← tambah ini
                              maxLines: 1,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setStateDialog(() => idKelas = v),
                    hint: const Text('Pilih kelas'),
                  ),
                  const SizedBox(height: 16),
                  // Pilih Mapel
                  DropdownButtonFormField<String>(
                    decoration: _inputDeco(
                      'Mata Pelajaran',
                      Icons.menu_book_rounded,
                    ),
                    value: idMapel,
                    items: _listMapel
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
                    onChanged: (v) => setStateDialog(() => idMapel = v),
                    hint: const Text('Pilih mata pelajaran'),
                  ),
                  const SizedBox(height: 16),
                  // Tahun Ajaran
                  TextField(
                    controller: tahunCtrl,
                    decoration: _inputDeco(
                      'Tahun Ajaran',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Semester
                  DropdownButtonFormField<String>(
                    decoration: _inputDeco('Semester', Icons.book_rounded),
                    value: semester,
                    items: const [
                      DropdownMenuItem(value: '1', child: Text('Semester 1')),
                      DropdownMenuItem(value: '2', child: Text('Semester 2')),
                    ],
                    onChanged: (v) => setStateDialog(() => semester = v!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
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
                if (idKelas == null || idMapel == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Kelas dan mata pelajaran wajib dipilih!'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                  return;
                }

                // Cek duplikat
                final cek = await supabase
                    .from('penugasan_guru')
                    .select('id')
                    .eq('id_guru', widget.idGuru)
                    .eq('id_kelas', idKelas!)
                    .eq('id_mapel', idMapel!)
                    .eq('tahun_ajaran', tahunCtrl.text)
                    .eq('semester', semester);

                if (cek.isNotEmpty) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Penugasan ini sudah ada!'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                  return;
                }

                await supabase.from('penugasan_guru').insert({
                  'id_guru': widget.idGuru,
                  'id_kelas': idKelas,
                  'id_mapel': idMapel,
                  'tahun_ajaran': tahunCtrl.text,
                  'semester': semester,
                });

                if (ctx.mounted) Navigator.pop(ctx);
                _ambilData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Penugasan Guru',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.namaGuru,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _tampilkanFormTambah,
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah Penugasan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _ambilData,
        color: _primary,
        child: Column(
          children: [
            // Filter bar
            Container(
              color: _primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  // Filter Tahun
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filterTahun,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: _tahunList
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _filterTahun = v!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter Semester
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _filterSemester,
                      dropdownColor: Colors.white,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.9),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
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
                      onChanged: (v) => setState(() => _filterSemester = v!),
                    ),
                  ),
                ],
              ),
            ),

            // List mapping
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : _filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada penugasan',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final m = _filtered[i];
                        final kelas = m['kelas'];
                        final mapel = m['mata_pelajaran'];
                        return Card(
                          elevation: 2,
                          margin: const EdgeInsets.only(bottom: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            leading: Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: _primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.assignment_rounded,
                                color: _primary,
                                size: 22,
                              ),
                            ),
                            title: Text(
                              mapel?['nama_mapel'] ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.class_rounded,
                                      size: 13,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        '${kelas?['nama_kelas'] ?? '-'} • ${kelas?['jurusan'] ?? '-'}',
                                        style: const TextStyle(fontSize: 12),
                                        overflow: TextOverflow
                                            .ellipsis, // ← tambah ini
                                        maxLines: 1,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today_rounded,
                                      size: 13,
                                      color: Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${m['tahun_ajaran']} • Semester ${m['semester']}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),

                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_note_rounded,
                                    color: Colors.blueAccent,
                                  ),
                                  onPressed: () => _tampilkanFormEdit(m),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_sweep_rounded,
                                    color: Colors.redAccent,
                                  ),
                                  onPressed: () =>
                                      _hapusMapping(m['id'].toString()),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
