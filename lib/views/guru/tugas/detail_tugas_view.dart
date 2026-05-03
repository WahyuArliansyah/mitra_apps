import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'input_nilai_view.dart';

class DetailTugasView extends StatefulWidget {
  final Map<String, dynamic> tugas;

  const DetailTugasView({
    super.key,
    required this.tugas,
    required String idGuru,
  });

  @override
  State<DetailTugasView> createState() => _DetailTugasViewState();
}

class _DetailTugasViewState extends State<DetailTugasView> {
  final supabase = Supabase.instance.client;

  static const _primary = Color(0xFF1A3A8F);
  static const _orange = Color(0xFFF97316);

  List<Map<String, dynamic>> _listPengumpulan = [];
  List<Map<String, dynamic>> _listSiswaKelas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ambilData();
  }

  Future<void> _ambilData() async {
    try {
      // Ambil semua siswa di kelas ini
      final siswa = await supabase
          .from('siswa')
          .select('id_siswa, nama_siswa, nis')
          .eq('id_kelas', widget.tugas['id_kelas']);

      // Ambil semua pengumpulan untuk tugas ini
      final pengumpulan = await supabase
          .from('pengumpulan')
          .select('*, siswa(nama_siswa, nis)')
          .eq('id_tugas', widget.tugas['id']);

      // Ambil semua nilai untuk tugas ini
      final nilaiList = await supabase
          .from('nilai')
          .select('id_siswa, nilai, umpan_balik, type_penilaian')
          .eq('id_tugas', widget.tugas['id']);

      // Gabungkan data siswa dengan status pengumpulan & nilai
      final Map<String, dynamic> nilaiMap = {
        for (var n in nilaiList) n['id_siswa']: n,
      };
      final Map<String, dynamic> pengumpulanMap = {
        for (var p in pengumpulan) p['id_siswa']: p,
      };

      final List<Map<String, dynamic>> gabungan = (siswa as List)
          .map<Map<String, dynamic>>((item) {
            final s = Map<String, dynamic>.from(item as Map);
            final idSiswa = s['id_siswa'];
            return {
              ...s,
              'pengumpulan': pengumpulanMap[idSiswa],
              'nilai': nilaiMap[idSiswa],
            };
          })
          .toList();

      setState(() {
        _listSiswaKelas = gabungan;
        _listPengumpulan = pengumpulan as List<Map<String, dynamic>>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  String _formatTanggal(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id').format(dt.toLocal());
  }

  Color _statusColor(Map<String, dynamic> siswa) {
    if (siswa['nilai'] != null) return Colors.green;
    if (siswa['pengumpulan'] != null) return _orange;
    return Colors.grey;
  }

  String _statusLabel(Map<String, dynamic> siswa) {
    if (siswa['nilai'] != null) return 'Dinilai';
    if (siswa['pengumpulan'] != null) return 'Dikumpulkan';
    return 'Belum';
  }

  @override
  Widget build(BuildContext context) {
    final tugas = widget.tugas;
    final isUpload = tugas['metode'] == 'upload';
    final isMateri = tugas['type_tugas'] == 'materi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Detail Tugas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : CustomScrollView(
              slivers: [
                // ── Info Tugas ──────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _typeBadge(isMateri),
                            const SizedBox(width: 8),
                            _metodeBadge(isUpload),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          tugas['judul_tugas'] ?? '-',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        if (tugas['deskripsi'] != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            tugas['deskripsi'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        const Divider(height: 24),
                        _infoRow(
                          Icons.class_rounded,
                          'Kelas',
                          tugas['kelas']?['nama_kelas'] ?? '-',
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          Icons.book_rounded,
                          'Mapel',
                          tugas['mata_pelajaran']?['nama_mapel'] ?? '-',
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          Icons.calendar_today_rounded,
                          'Tenggat',
                          _formatTanggal(tugas['tenggat_waktu']),
                        ),
                        const SizedBox(height: 8),
                        _infoRow(
                          Icons.school_rounded,
                          'Semester',
                          'Semester ${tugas['semester']} — ${tugas['tahun_ajaran']}',
                        ),
                        if (tugas['url_file_materi'] != null) ...[
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: () async {
                              final url = Uri.parse(tugas['url_file_materi']);
                              if (await canLaunchUrl(url)) {
                                launchUrl(
                                  url,
                                  mode: LaunchMode.externalApplication,
                                );
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEF2FF),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.attach_file_rounded,
                                    color: _primary,
                                    size: 18,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    'Lihat File Materi',
                                    style: TextStyle(
                                      color: _primary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // ── Statistik ───────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _buildStatistik(),
                  ),
                ),

                // ── Header list siswa ───────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Daftar Siswa (${_listSiswaKelas.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                  ),
                ),

                // ── List siswa ──────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildSiswaCard(_listSiswaKelas[i], isUpload),
                    childCount: _listSiswaKelas.length,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 24)),
              ],
            ),
    );
  }

  Widget _buildStatistik() {
    final total = _listSiswaKelas.length;
    final dinilai = _listSiswaKelas.where((s) => s['nilai'] != null).length;
    final dikumpul = _listSiswaKelas
        .where((s) => s['pengumpulan'] != null && s['nilai'] == null)
        .length;
    final belum = total - dinilai - dikumpul;

    return Row(
      children: [
        _statBox('Dinilai', dinilai, Colors.green),
        const SizedBox(width: 8),
        _statBox('Dikumpulkan', dikumpul, _orange),
        const SizedBox(width: 8),
        _statBox('Belum', belum, Colors.grey),
      ],
    );
  }

  Widget _statBox(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 11, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> siswa, bool isUpload) {
    final statusColor = _statusColor(siswa);
    final statusLabel = _statusLabel(siswa);
    final sudahDinilai = siswa['nilai'] != null;
    final sudahKumpul = siswa['pengumpulan'] != null;
    final inisial = (siswa['nama_siswa'] as String)
        .trim()
        .split(' ')
        .map((e) => e[0])
        .take(2)
        .join()
        .toUpperCase();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFFEEF2FF),
          child: Text(
            inisial,
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          siswa['nama_siswa'],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1A1F36),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              // NIS badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  siswa['nis'] ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
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
              if (sudahDinilai) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${siswa['nilai']['nilai']}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: sudahDinilai
            ? const Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 22,
              )
            : (isUpload && !sudahKumpul)
            ? const Icon(
                Icons.hourglass_empty_rounded,
                color: Colors.grey,
                size: 20,
              )
            : ElevatedButton(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InputNilaiView(
                        tugas: widget.tugas,
                        siswa: siswa,
                        pengumpulan: siswa['pengumpulan'],
                      ),
                    ),
                  );
                  _ambilData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Nilai'),
              ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: _primary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1F36),
            ),
          ),
        ),
      ],
    );
  }

  Widget _typeBadge(bool isMateri) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isMateri ? const Color(0xFFEEF2FF) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isMateri ? 'Materi (30%)' : 'Praktikum (70%)',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isMateri ? _primary : Colors.orange.shade800,
        ),
      ),
    );
  }

  Widget _metodeBadge(bool isUpload) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUpload ? const Color(0xFFE8F5E9) : const Color(0xFFFCE4EC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isUpload ? 'Upload Siswa' : 'Input Manual',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isUpload ? Colors.green.shade800 : Colors.pink.shade800,
        ),
      ),
    );
  }
}
