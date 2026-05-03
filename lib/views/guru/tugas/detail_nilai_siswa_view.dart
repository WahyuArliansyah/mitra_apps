import 'package:flutter/material.dart';
import 'package:mitra_apps/widgets/ringkasan_nilai_card.dart';
import 'package:mitra_apps/widgets/tabel_history_nilai.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailNilaiSiswaView extends StatefulWidget {
  final Map<String, dynamic> siswa;
  final String idKelas;
  final String idMapel;
  final String namaKelas;
  final String namaMapel;
  final String semester;
  final String tahunAjaran;

  const DetailNilaiSiswaView({
    super.key,
    required this.siswa,
    required this.idKelas,
    required this.idMapel,
    required this.namaKelas,
    required this.namaMapel,
    required this.semester,
    required this.tahunAjaran,
  });

  @override
  State<DetailNilaiSiswaView> createState() => _DetailNilaiSiswaViewState();
}

class _DetailNilaiSiswaViewState extends State<DetailNilaiSiswaView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  List<Map<String, dynamic>> _historyNilai = [];
  bool _isLoading = true;
  double _rataMateri = 0;
  double _rataPraktikum = 0;
  double _nilaiAkhir = 0;

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  Future<void> _ambilData() async {
    setState(() => _isLoading = true);
    try {
      // ✅ Pisah jadi 2 await terpisah
      final nilaiData = await supabase
          .from('nilai')
          .select(
            '*, tugas!inner(judul_tugas, type_tugas, metode, id_kelas, id_mapel)',
          )
          .eq('id_siswa', widget.siswa['id_siswa'])
          .eq('tugas.id_kelas', widget.idKelas)
          .eq('tugas.id_mapel', widget.idMapel)
          .order('dinilai_at', ascending: true);

      final rekap = await supabase.rpc(
        'hitung_nilai_akhir',
        params: {
          'p_id_siswa': widget.siswa['id_siswa'],
          'p_id_kelas': widget.idKelas,
          'p_id_mapel': widget.idMapel,
          'p_semester': widget.semester,
          'p_tahun_ajaran': widget.tahunAjaran,
        },
      );

      if (!mounted) return;
      setState(() {
        _historyNilai = List<Map<String, dynamic>>.from(nilaiData);
        if (rekap.isNotEmpty) {
          _rataMateri = (rekap[0]['rata_materi'] as num).toDouble();
          _rataPraktikum = (rekap[0]['rata_praktikum'] as num).toDouble();
          _nilaiAkhir = (rekap[0]['nilai_akhir'] as num).toDouble();
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inisial = widget.siswa['nama_siswa']
        .toString()
        .trim()
        .split(' ')
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.siswa['nama_siswa'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.namaKelas} • ${widget.namaMapel}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : RefreshIndicator(
              onRefresh: _ambilData,
              color: _primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Info siswa
                    _buildInfoSiswa(inisial),
                    const SizedBox(height: 16),

                    // ✅ Widget ringkasan nilai
                    RingkasanNilaiCard(
                      rataMateri: _rataMateri,
                      rataPraktikum: _rataPraktikum,
                      nilaiAkhir: _nilaiAkhir,
                    ),
                    const SizedBox(height: 16),

                    // ✅ Widget tabel history
                    TabelHistoryNilai(historyNilai: _historyNilai),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoSiswa(String inisial) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFE0F2FE),
            child: Text(
              inisial,
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.siswa['nama_siswa'],
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                Text(
                  'NIS: ${widget.siswa['nis'] ?? '-'}',
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                Text(
                  'Semester ${widget.semester} • ${widget.tahunAjaran}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
