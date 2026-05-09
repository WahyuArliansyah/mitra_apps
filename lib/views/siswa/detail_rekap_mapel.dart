import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Screen 2 — Detail Rekap Nilai per Mapel (POV Siswa, read-only)
class DetailRekapMapelView extends StatefulWidget {
  final Map<String, dynamic> siswa; // row dari tabel `siswa`
  final String idKelas;
  final String idMapel;
  final String namaKelas;
  final String namaMapel;
  final String semester;
  final String tahunAjaran;

  const DetailRekapMapelView({
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
  State<DetailRekapMapelView> createState() => _DetailRekapMapelViewState();
}

class _DetailRekapMapelViewState extends State<DetailRekapMapelView> {
  final _supabase = Supabase.instance.client;

  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  bool _isLoading = true;
  List<Map<String, dynamic>> _historyNilai = [];
  double _rataMateri = 0;
  double _rataPraktikum = 0;
  double _nilaiAkhir = 0;

  String get _idSiswa => widget.siswa['id_siswa'].toString();

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  Future<void> _ambilData() async {
    setState(() => _isLoading = true);
    try {
      final nilaiData = await _supabase
          .from('nilai')
          .select(
            '*, tugas!inner(judul_tugas, type_tugas, metode, id_kelas, id_mapel)',
          )
          .eq('id_siswa', _idSiswa)
          .eq('tugas.id_kelas', widget.idKelas)
          .eq('tugas.id_mapel', widget.idMapel)
          .order('dinilai_at', ascending: true);

      final rekap = await _supabase.rpc(
        'hitung_nilai_akhir',
        params: {
          'p_id_siswa': _idSiswa,
          'p_id_kelas': widget.idKelas,
          'p_id_mapel': widget.idMapel,
          'p_semester': widget.semester,
          'p_tahun_ajaran': widget.tahunAjaran,
        },
      );

      if (!mounted) return;
      setState(() {
        _historyNilai = List<Map<String, dynamic>>.from(nilaiData);
        final rekapList = rekap as List;
        if (rekapList.isNotEmpty) {
          _rataMateri = (rekapList[0]['rata_materi'] as num).toDouble();
          _rataPraktikum = (rekapList[0]['rata_praktikum'] as num).toDouble();
          _nilaiAkhir = (rekapList[0]['nilai_akhir'] as num).toDouble();
        }
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error detail nilai: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.namaMapel,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.namaKelas} • Semester ${widget.semester}',
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
                    _buildInfoMapel(),
                    const SizedBox(height: 16),
                    _buildRingkasanNilai(),
                    const SizedBox(height: 16),
                    _buildTabelHistory(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoMapel() {
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.menu_book_rounded,
              color: _primary,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.namaMapel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.namaKelas,
                  style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                ),
                Text(
                  'Semester ${widget.semester} · ${widget.tahunAjaran}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRingkasanNilai() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Nilai',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildNilaiBox(
                  label: 'Rata-rata\nMateri',
                  nilai: _rataMateri,
                  color: const Color(0xFF0EA5E9),
                  bgColor: const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNilaiBox(
                  label: 'Rata-rata\nPraktikum',
                  nilai: _rataPraktikum,
                  color: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFEDE9FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildNilaiBox(
                  label: 'Nilai\nAkhir',
                  nilai: _nilaiAkhir,
                  color: const Color(0xFF059669),
                  bgColor: const Color(0xFFD1FAE5),
                  isBig: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNilaiBox({
    required String label,
    required double nilai,
    required Color color,
    required Color bgColor,
    bool isBig = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            nilai.toStringAsFixed(1),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: isBig ? 22 : 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color.withOpacity(0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabelHistory() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
            child: Row(
              children: [
                const Text(
                  'Riwayat Nilai',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_historyNilai.length} tugas',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_historyNilai.isEmpty) _buildEmptyHistory() else _buildTabelIsi(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyHistory() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 40,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 8),
            Text(
              'Belum ada nilai tercatat',
              style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabelIsi() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6FB),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Tugas',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Tipe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Nilai',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        ...List.generate(_historyNilai.length, (i) {
          final item = _historyNilai[i];
          final tugas = item['tugas'] as Map<String, dynamic>? ?? {};
          final judul = tugas['judul_tugas']?.toString() ?? '-';
          final tipe = tugas['type_tugas']?.toString() ?? '-';
          final metode = tugas['metode']?.toString() ?? '-';
          final nilai = (item['nilai'] as num?)?.toDouble() ?? 0;
          final isPraktikum = tipe.toLowerCase() == 'praktikum';

          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : const Color(0xFFFAFAFA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        judul,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1F36),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (metode.isNotEmpty && metode != '-')
                        Text(
                          metode,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isPraktikum
                            ? const Color(0xFFEDE9FE)
                            : const Color(0xFFE0F2FE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tipe,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isPraktikum
                              ? const Color(0xFF7C3AED)
                              : const Color(0xFF0369A1),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    nilai.toStringAsFixed(1),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _nilaiColor(nilai),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Color _nilaiColor(double nilai) {
    if (nilai >= 75) return const Color(0xFF059669);
    if (nilai >= 60) return const Color(0xFFD97706);
    return const Color(0xFFDC2626);
  }
}
