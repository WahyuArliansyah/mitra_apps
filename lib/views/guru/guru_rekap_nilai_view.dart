import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/tugas/detail_nilai_siswa_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruRekapNilaiView extends StatefulWidget {
  final String idGuru;

  const GuruRekapNilaiView({super.key, required this.idGuru});

  @override
  State<GuruRekapNilaiView> createState() => _GuruRekapNilaiViewState();
}

class _GuruRekapNilaiViewState extends State<GuruRekapNilaiView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  List<Map<String, dynamic>> _penugasanList = [];
  Map<String, dynamic>? _penugasanTerpilih;
  List<Map<String, dynamic>> _rekapList = [];

  String _semester = '1';
  String _tahunAjaran = '${DateTime.now().year}/${DateTime.now().year + 1}';

  bool _isLoadingPenugasan = true;
  bool _isLoadingRekap = false;

  @override
  void initState() {
    super.initState();
    _ambilPenugasan();
  }

  // ambil penugasan guru untuk dropdown
  Future<void> _ambilPenugasan() async {
    if (widget.idGuru.isEmpty) return;
    setState(() => _isLoadingPenugasan = true);
    try {
      final data = await supabase
          .from('penugasan_guru')
          .select('*, kelas(id, nama_kelas), mata_pelajaran(id, nama_mapel)')
          .eq('id_guru', widget.idGuru);

      if (!mounted) return;
      setState(() {
        _penugasanList = List<Map<String, dynamic>>.from(data);
        _isLoadingPenugasan = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingPenugasan = false);
    }
  }

  // ambil rekap nilai per penugasan terpilih
  Future<void> _ambilRekap() async {
    if (_penugasanTerpilih == null) return;
    setState(() => _isLoadingRekap = true);

    try {
      final idKelas = _penugasanTerpilih!['kelas']['id'].toString();
      final idMapel = _penugasanTerpilih!['mata_pelajaran']['id'].toString();

      // Ambil semua siswa di kelas
      final siswaList = await supabase
          .from('siswa')
          .select('id_siswa, nama_siswa, nis')
          .eq('id_kelas', idKelas)
          .order('nama_siswa', ascending: true);

      // Hitung nilai akhir per siswa via RPC
      final List<Map<String, dynamic>> rekap = [];
      for (final siswa in siswaList) {
        final hasil = await supabase.rpc(
          'hitung_nilai_akhir',
          params: {
            'p_id_siswa': siswa['id_siswa'],
            'p_id_kelas': idKelas,
            'p_id_mapel': idMapel,
            'p_semester': _semester,
            'p_tahun_ajaran': _tahunAjaran,
          },
        );

        final h = hasil.isNotEmpty ? hasil[0] : null;
        rekap.add({
          'siswa': siswa,
          'rata_materi': h?['rata_materi'] ?? 0,
          'rata_praktikum': h?['rata_praktikum'] ?? 0,
          'nilai_tugas': h?['nilai_tugas'] ?? 0,
          'nilai_akhir': h?['nilai_akhir'] ?? 0,
        });
      }

      if (!mounted) return;
      setState(() {
        _rekapList = rekap;
        _isLoadingRekap = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRekap = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Rekap Nilai',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Filter panel
          Container(
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Pilih kelas & mapel
                _isLoadingPenugasan
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : DropdownButtonFormField<Map<String, dynamic>>(
                        value: _penugasanTerpilih,
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
                            vertical: 10,
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
                        hint: const Text('Pilih Kelas & Mapel'),
                        items: _penugasanList
                            .map(
                              (p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  '${p['kelas']['nama_kelas']} - ${p['mata_pelajaran']['nama_mapel']}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _penugasanTerpilih = v),
                      ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // Semester
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _semester,
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
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: '1',
                            child: Text('Semester 1'),
                          ),
                          DropdownMenuItem(
                            value: '2',
                            child: Text('Semester 2'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _semester = v!),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Tombol tampilkan
                    ElevatedButton(
                      onPressed: _ambilRekap,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: _primary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        'Tampilkan',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Rekap list
          Expanded(
            child: _isLoadingRekap
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _rekapList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_outlined,
                          size: 60,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _penugasanTerpilih == null
                              ? 'Pilih kelas & mapel dulu'
                              : 'Belum ada data nilai',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _rekapList.length,
                    itemBuilder: (ctx, i) =>
                        _buildRekapCard(_rekapList[i], i + 1),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRekapCard(Map<String, dynamic> rekap, int no) {
    final siswa = rekap['siswa'];
    final nilaiAkhir = (rekap['nilai_akhir'] as num).toDouble();
    final rataMateri = (rekap['rata_materi'] as num).toDouble();
    final rataPraktikum = (rekap['rata_praktikum'] as num).toDouble();

    Color nilaiColor;
    if (nilaiAkhir >= 80) {
      nilaiColor = const Color(0xFF059669);
    } else if (nilaiAkhir >= 60) {
      nilaiColor = const Color(0xFFD97706);
    } else {
      nilaiColor = Colors.redAccent;
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailNilaiSiswaView(
            siswa: rekap['siswa'],
            idKelas: _penugasanTerpilih!['kelas']['id'].toString(),
            idMapel: _penugasanTerpilih!['mata_pelajaran']['id'].toString(),
            namaKelas: _penugasanTerpilih!['kelas']['nama_kelas'],
            namaMapel: _penugasanTerpilih!['mata_pelajaran']['nama_mapel'],
            semester: _semester,
            tahunAjaran: _tahunAjaran,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Nomor urut
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$no',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    siswa['nama_siswa'],
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _miniInfo('Materi', rataMateri, const Color(0xFF0EA5E9)),
                      const SizedBox(width: 8),
                      _miniInfo(
                        'Praktikum',
                        rataPraktikum,
                        const Color(0xFFD97706),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Nilai akhir
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  nilaiAkhir.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: nilaiColor,
                  ),
                ),
                Text(
                  'Nilai Akhir',
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniInfo(String label, double nilai, Color color) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        Text(
          nilai.toStringAsFixed(1),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
