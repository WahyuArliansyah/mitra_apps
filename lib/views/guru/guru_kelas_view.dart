import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/tugas/detail_kelas_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruKelasView extends StatefulWidget {
  final String idGuru;

  const GuruKelasView({super.key, required this.idGuru});

  @override
  State<GuruKelasView> createState() => _GuruKelasViewState();
}

class _GuruKelasViewState extends State<GuruKelasView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  List<Map<String, dynamic>> _listPenugasan = [];
  bool _isLoading = true;
  String _filterTahun = 'Semua';
  String _filterSemester = 'Semua';
  List<String> _tahunList = ['Semua'];

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  Future<void> _ambilData() async {
    if (widget.idGuru.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('penugasan_guru')
          .select(
            '*, kelas(id, nama_kelas, jurusan), mata_pelajaran(id, nama_mapel)',
          )
          .eq('id_guru', widget.idGuru)
          .order('created_at', ascending: false);

      final list = List<Map<String, dynamic>>.from(data);
      final tahunSet = list
          .map((m) => m['tahun_ajaran'].toString())
          .toSet()
          .toList();

      if (!mounted) return;
      setState(() {
        _listPenugasan = list;
        _tahunList = ['Semua', ...tahunSet];
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    return _listPenugasan.where((p) {
      final tahunMatch =
          _filterTahun == 'Semua' ||
          p['tahun_ajaran'].toString() == _filterTahun;
      final semesterMatch =
          _filterSemester == 'Semua' ||
          p['semester'].toString() == _filterSemester;
      return tahunMatch && semesterMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Kelas yang Diajar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
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

            // List kelas
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
                            Icons.class_outlined,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada kelas yang diajar',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) => _buildKelasCard(_filtered[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKelasCard(Map<String, dynamic> penugasan) {
    final kelas = penugasan['kelas'];
    final mapel = penugasan['mata_pelajaran'];

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailKelasView(
            idGuru: widget.idGuru,
            idKelas: kelas['id'].toString(),
            idMapel: mapel['id'].toString(),
            namaKelas: kelas['nama_kelas'],
            namaMapel: mapel['nama_mapel'],
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.class_rounded, color: _primary, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kelas?['nama_kelas'] ?? '-',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mapel?['nama_mapel'] ?? '-',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${penugasan['tahun_ajaran']} • Semester ${penugasan['semester']}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
