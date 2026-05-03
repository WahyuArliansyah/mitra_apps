import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/tugas/input_nilai_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailTugasView extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final String idGuru;

  const DetailTugasView({super.key, required this.tugas, required this.idGuru});

  @override
  State<DetailTugasView> createState() => _DetailTugasViewState();
}

class _DetailTugasViewState extends State<DetailTugasView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  List<Map<String, dynamic>> _listSiswa = [];
  Map<String, Map<String, dynamic>> _pengumpulanMap = {};
  Map<String, Map<String, dynamic>> _nilaiMap = {};
  bool _isLoading = true;
  bool _isMetodeManual = false;

  @override
  void initState() {
    super.initState();
    _isMetodeManual = widget.tugas['metode'] == 'manual';
    _ambilData();
  }

  Future<void> _ambilData() async {
    setState(() => _isLoading = true);
    try {
      final idTugas = widget.tugas['id'];
      final idKelas = widget.tugas['id_kelas'];

      final results = await Future.wait([
        // Ambil semua siswa di kelas ini
        supabase
            .from('siswa')
            .select('id_siswa, nama_siswa, nis')
            .eq('id_kelas', idKelas)
            .order('nama_siswa', ascending: true),
        // Ambil pengumpulan siswa
        supabase.from('pengumpulan').select('*').eq('id_tugas', idTugas),
        // Ambil nilai siswa
        supabase.from('nilai').select('*').eq('id_tugas', idTugas),
      ]);

      final siswaList = List<Map<String, dynamic>>.from(results[0]);
      final pengumpulanList = List<Map<String, dynamic>>.from(results[1]);
      final nilaiList = List<Map<String, dynamic>>.from(results[2]);

      // Map pengumpulan & nilai by id_siswa
      final pengumpulanMap = <String, Map<String, dynamic>>{};
      for (final p in pengumpulanList) {
        pengumpulanMap[p['id_siswa'].toString()] = p;
      }

      final nilaiMap = <String, Map<String, dynamic>>{};
      for (final n in nilaiList) {
        nilaiMap[n['id_siswa'].toString()] = n;
      }

      if (!mounted) return;
      setState(() {
        _listSiswa = siswaList;
        _pengumpulanMap = pengumpulanMap;
        _nilaiMap = nilaiMap;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPraktikum = widget.tugas['type_tugas'] == 'praktikum';
    final deadline = widget.tugas['tenggat_waktu'] != null
        ? DateTime.parse(widget.tugas['tenggat_waktu'])
        : null;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.tugas['judul_tugas'] ?? '-',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${widget.tugas['kelas']?['nama_kelas'] ?? '-'} • ${widget.tugas['mata_pelajaran']?['nama_mapel'] ?? '-'}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _ambilData,
        color: _primary,
        child: Column(
          children: [
            // Info tugas
            Container(
              color: _primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _infoBadge(
                    isPraktikum ? 'Praktikum' : 'Materi',
                    isPraktikum ? const Color(0xFFD97706) : Colors.white,
                    isPraktikum
                        ? const Color(0xFFFEF3E0)
                        : Colors.white.withOpacity(0.2),
                  ),
                  const SizedBox(width: 8),
                  _infoBadge(
                    _isMetodeManual ? 'Manual' : 'Upload',
                    Colors.white,
                    Colors.white.withOpacity(0.2),
                  ),
                  const Spacer(),
                  if (deadline != null)
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_rounded,
                          color: Colors.white70,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${deadline.day}/${deadline.month}/${deadline.year}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // Statistik
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _statCard(
                      'Total Siswa',
                      _listSiswa.length,
                      Icons.people_rounded,
                      _primary,
                      const Color(0xFFE0F2FE),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Sudah Dinilai',
                      _nilaiMap.length,
                      Icons.check_circle_rounded,
                      const Color(0xFF059669),
                      const Color(0xFFE6FAF5),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _statCard(
                      'Belum Dinilai',
                      _listSiswa.length - _nilaiMap.length,
                      Icons.pending_rounded,
                      const Color(0xFFD97706),
                      const Color(0xFFFEF3E0),
                    ),
                  ),
                ],
              ),
            ),

            // List siswa
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      itemCount: _listSiswa.length,
                      itemBuilder: (ctx, i) => _buildSiswaCard(_listSiswa[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> siswa) {
    final idSiswa = siswa['id_siswa'].toString();
    final pengumpulan = _pengumpulanMap[idSiswa];
    final nilai = _nilaiMap[idSiswa];
    final sudahDinilai = nilai != null;
    final sudahKumpul = pengumpulan != null;

    final inisial = siswa['nama_siswa'].toString().isNotEmpty
        ? siswa['nama_siswa']
              .toString()
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
        : '?';

    // Tentukan status
    String statusLabel;
    Color statusColor;
    Color statusBg;

    if (sudahDinilai) {
      statusLabel = 'Dinilai';
      statusColor = const Color(0xFF059669);
      statusBg = const Color(0xFFE6FAF5);
    } else if (_isMetodeManual) {
      statusLabel = 'Belum Dinilai';
      statusColor = const Color(0xFFD97706);
      statusBg = const Color(0xFFFEF3E0);
    } else if (sudahKumpul) {
      statusLabel = 'Sudah Kumpul';
      statusColor = _primary;
      statusBg = const Color(0xFFE0F2FE);
    } else {
      statusLabel = 'Belum Kumpul';
      statusColor = Colors.grey;
      statusBg = Colors.grey.shade100;
    }

    // Bisa dinilai jika: manual ATAU sudah kumpul
    final bisaDinilai = _isMetodeManual || sudahKumpul;

    return Container(
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
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(0xFFE0F2FE),
            child: Text(
              inisial.toUpperCase(),
              style: const TextStyle(
                color: _primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
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
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Tampilkan nilai jika sudah dinilai
                    if (sudahDinilai) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Nilai: ${nilai!['nilai']}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF059669),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Tombol nilai
          if (bisaDinilai)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InputNilaiView(
                    siswa: siswa,
                    tugas: widget.tugas,
                    pengumpulan: pengumpulan,
                    nilaiExisting: nilai,
                    idGuru: widget.idGuru,
                  ),
                ),
              ).then((_) => _ambilData()),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: sudahDinilai
                      ? const Color(0xFFE6FAF5)
                      : _primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  sudahDinilai ? 'Edit Nilai' : 'Beri Nilai',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: sudahDinilai ? const Color(0xFF059669) : _primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statCard(
    String label,
    int value,
    IconData icon,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF9AA0B2)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _infoBadge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
