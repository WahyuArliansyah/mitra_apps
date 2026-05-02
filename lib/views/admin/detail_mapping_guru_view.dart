import 'package:flutter/material.dart';
import 'package:mitra_apps/widgets/filter_bar_mapping.dart';
import 'package:mitra_apps/widgets/form_penugasan_dialog.dart';
import 'package:mitra_apps/widgets/mapping_card.dart';
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
      setState(() {
        _listMapping = mappings;
        _listKelas = List<Map<String, dynamic>>.from(results[1]);
        _listMapel = List<Map<String, dynamic>>.from(results[2]);
        _tahunList = [
          'Semua',
          ...mappings.map((m) => m['tahun_ajaran'].toString()).toSet(),
        ];
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered => _listMapping.where((m) {
    final tahunMatch =
        _filterTahun == 'Semua' || m['tahun_ajaran'].toString() == _filterTahun;
    final semesterMatch =
        _filterSemester == 'Semua' ||
        m['semester'].toString() == _filterSemester;
    return tahunMatch && semesterMatch;
  }).toList();

  Future<void> _hapusMapping(String id) async {
    final ok = await showDialog<bool>(
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await supabase.from('penugasan_guru').delete().eq('id', id);
    _ambilData();
  }

  Future<void> _simpanPenugasan(
    List<Map<String, String>> pasangan,
    String tahun,
    String semester,
  ) async {
    List<Map<String, dynamic>> dataInsert = [];

    for (final p in pasangan) {
      // Cek duplikat per pasangan
      final cek = await supabase
          .from('penugasan_guru')
          .select('id')
          .eq('id_guru', widget.idGuru)
          .eq('id_kelas', p['kelas']!)
          .eq('id_mapel', p['mapel']!)
          .eq('tahun_ajaran', tahun)
          .eq('semester', semester);

      if (cek.isEmpty) {
        dataInsert.add({
          'id_guru': widget.idGuru,
          'id_kelas': p['kelas'],
          'id_mapel': p['mapel'],
          'tahun_ajaran': tahun,
          'semester': semester,
        });
      }
    }

    if (dataInsert.isEmpty) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua penugasan yang dipilih sudah ada!'),
            backgroundColor: Colors.orange,
          ),
        );
      return;
    }

    await supabase.from('penugasan_guru').insert(dataInsert);
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${dataInsert.length} penugasan berhasil ditambahkan'),
          backgroundColor: Colors.green,
        ),
      );
    }
    _ambilData();
  }

  void _tampilkanFormTambah() {
    showDialog(
      context: context,
      builder: (_) => FormPenugasanDialog(
        listKelas: _listKelas,
        listMapel: _listMapel,
        onSimpan: _simpanPenugasan,
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
            FilterBarMapping(
              filterTahun: _filterTahun,
              filterSemester: _filterSemester,
              tahunList: _tahunList,
              onTahunChanged: (v) => setState(() => _filterTahun = v),
              onSemesterChanged: (v) => setState(() => _filterSemester = v),
            ),
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
                        return MappingCard(
                          mapping: m,
                          onEdit: () => _tampilkanFormEdit(m),
                          onHapus: () => _hapusMapping(m['id'].toString()),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Form edit tetap di sini karena butuh akses langsung ke supabase & _ambilData
  void _tampilkanFormEdit(Map<String, dynamic> mapping) {
    String? idKelas = mapping['id_kelas'].toString();
    String? idMapel = mapping['id_mapel'].toString();
    final tahunCtrl = TextEditingController(text: mapping['tahun_ajaran']);
    String semester = mapping['semester'].toString();

    InputDecoration inputDeco(String label, IconData icon) => InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primary, width: 2),
      ),
    );

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
                    decoration: inputDeco('Kelas', Icons.class_rounded),
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
                    decoration: inputDeco(
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
                    decoration: inputDeco(
                      'Tahun Ajaran',
                      Icons.calendar_today_rounded,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: inputDeco('Semester', Icons.book_rounded),
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
                if (idKelas == null || idMapel == null) return;
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
}
