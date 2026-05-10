import 'package:flutter/material.dart';
import 'package:mitra_apps/widgets/siswa_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RekapNilaiSiswa extends StatefulWidget {
  final String idSiswa;

  const RekapNilaiSiswa({super.key, required this.idSiswa});

  @override
  State<RekapNilaiSiswa> createState() => _RekapNilaiSiswaViewState();
}

class _RekapNilaiSiswaViewState extends State<RekapNilaiSiswa> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  // Data siswa
  String _idKelas = '';
  String _namaSiswa = '';
  bool _isLoadingSiswa = true;

  // Dropdown mapel
  List<Map<String, dynamic>> _listMapel = [];
  Map<String, dynamic>? _selectedMapel;

  // Dropdown semester & tahun ajaran
  String? _selectedSemester;
  String? _selectedTahunAjaran;
  final List<String> _semesterOptions = ['1', '2'];
  List<String> _tahunAjaranOptions = [];

  // Data nilai
  List<Map<String, dynamic>> _listNilai = [];
  Map<String, dynamic>? _hasilHitung;
  bool _isLoadingNilai = false;

  @override
  void initState() {
    super.initState();
    _loadDataSiswa();
  }

  Future<void> _loadDataSiswa() async {
    try {
      // Ambil data siswa
      final siswaData = await supabase
          .from('siswa')
          .select('nama_siswa, id_kelas')
          .eq('id_siswa', widget.idSiswa)
          .maybeSingle();

      if (siswaData == null) {
        if (mounted) setState(() => _isLoadingSiswa = false);
        return;
      }

      _namaSiswa = siswaData['nama_siswa'] ?? '';
      _idKelas = siswaData['id_kelas']?.toString() ?? '';

      // Ambil daftar mapel yang ada nilainya untuk siswa ini
      final mapelData = await supabase
          .from('nilai')
          .select('tugas(id_mapel, mata_pelajaran(id, nama_mapel))')
          .eq('id_siswa', widget.idSiswa);

      // Ambil daftar tahun ajaran unik dari tugas
      final tugasData = await supabase
          .from('nilai')
          .select('tugas(tahun_ajaran)')
          .eq('id_siswa', widget.idSiswa);

      // Deduplikasi mapel
      final mapelMap = <String, Map<String, dynamic>>{};
      for (final item in mapelData) {
        final mapel = item['tugas']?['mata_pelajaran'];
        if (mapel != null) {
          mapelMap[mapel['id'].toString()] = mapel;
        }
      }

      // Deduplikasi tahun ajaran
      final tahunSet = <String>{};
      for (final item in tugasData) {
        final ta = item['tugas']?['tahun_ajaran']?.toString();
        if (ta != null) tahunSet.add(ta);
      }

      if (!mounted) return;
      setState(() {
        _listMapel = mapelMap.values.toList();
        _tahunAjaranOptions = tahunSet.toList()..sort();
        _isLoadingSiswa = false;
      });
    } catch (e) {
      debugPrint('Error load siswa: $e');
      if (mounted) setState(() => _isLoadingSiswa = false);
    }
  }

  Future<void> _loadNilai() async {
    if (_selectedMapel == null ||
        _selectedSemester == null ||
        _selectedTahunAjaran == null)
      return;

    setState(() {
      _isLoadingNilai = true;
      _listNilai = [];
      _hasilHitung = null;
    });

    try {
      // 1. Ambil list nilai siswa untuk mapel + semester + tahun ajaran
      final nilaiData = await supabase
          .from('nilai')
          .select(
            '*, tugas(judul_tugas, type_tugas, semester, tahun_ajaran, id_mapel)',
          )
          .eq('id_siswa', widget.idSiswa)
          .order('dinilai_at', ascending: true);

      // Filter sesuai mapel, semester, tahun ajaran
      final filtered = (nilaiData as List).where((n) {
        final tugas = n['tugas'];
        return tugas?['id_mapel']?.toString() ==
                _selectedMapel!['id'].toString() &&
            tugas?['semester']?.toString() == _selectedSemester &&
            tugas?['tahun_ajaran']?.toString() == _selectedTahunAjaran;
      }).toList();

      // 2. Panggil RPC hitung_nilai_akhir
      final rpcResult = await supabase.rpc(
        'hitung_nilai_akhir',
        params: {
          'p_id_siswa': widget.idSiswa,
          'p_id_kelas': _idKelas,
          'p_id_mapel': _selectedMapel!['id'].toString(),
          'p_semester': _selectedSemester,
          'p_tahun_ajaran': _selectedTahunAjaran,
        },
      );

      Map<String, dynamic>? hasilHitung;
      if (rpcResult != null && (rpcResult as List).isNotEmpty) {
        hasilHitung = Map<String, dynamic>.from(rpcResult.first);
      }

      if (!mounted) return;
      setState(() {
        _listNilai = List<Map<String, dynamic>>.from(filtered);
        _hasilHitung = hasilHitung;
        _isLoadingNilai = false;
      });
    } catch (e) {
      debugPrint('Error load nilai: $e');
      if (mounted) setState(() => _isLoadingNilai = false);
    }
  }

  Color _nilaiColor(double nilai) {
    if (nilai >= 85) return const Color(0xFF059669);
    if (nilai >= 70) return _primary;
    if (nilai >= 55) return const Color(0xFFD97706);
    return Colors.redAccent;
  }

  String _nilaiGrade(double nilai) {
    if (nilai >= 85) return 'A';
    if (nilai >= 70) return 'B';
    if (nilai >= 55) return 'C';
    if (nilai >= 40) return 'D';
    return 'E';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: SiswaAppBar(namaSiswa: _namaSiswa),
      body: _isLoadingSiswa
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter card nilai
                  Container(
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Filter Nilai',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Dropdown Mata Pelajaran
                        _buildDropdownLabel('Mata Pelajaran'),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<Map<String, dynamic>>(
                          value: _selectedMapel,
                          hint: const Text('Pilih mata pelajaran'),
                          decoration: _dropdownDecoration(),
                          items: _listMapel.map((mapel) {
                            return DropdownMenuItem(
                              value: mapel,
                              child: Text(mapel['nama_mapel'] ?? '-'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedMapel = val;
                              _listNilai = [];
                              _hasilHitung = null;
                            });
                            _loadNilaiIfReady();
                          },
                        ),
                        const SizedBox(height: 12),

                        // Semester & Tahun Ajaran dalam 1 baris
                        Row(
                          children: [
                            // Dropdown Semester
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDropdownLabel('Semester'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedSemester,
                                    hint: const Text('Semester'),
                                    decoration: _dropdownDecoration(),
                                    items: _semesterOptions.map((s) {
                                      return DropdownMenuItem(
                                        value: s,
                                        child: Text('Semester $s'),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedSemester = val;
                                        _listNilai = [];
                                        _hasilHitung = null;
                                      });
                                      _loadNilaiIfReady();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Dropdown Tahun Ajaran
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildDropdownLabel('Tahun Ajaran'),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                    value: _selectedTahunAjaran,
                                    hint: const Text('Tahun'),
                                    decoration: _dropdownDecoration(),
                                    items: _tahunAjaranOptions.map((ta) {
                                      return DropdownMenuItem(
                                        value: ta,
                                        child: Text(ta),
                                      );
                                    }).toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedTahunAjaran = val;
                                        _listNilai = [];
                                        _hasilHitung = null;
                                      });
                                      _loadNilaiIfReady();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tabel nilai & rekap perhitungan
                  if (_isLoadingNilai)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(color: _primary),
                      ),
                    )
                  else if (_selectedMapel == null ||
                      _selectedSemester == null ||
                      _selectedTahunAjaran == null)
                    _buildPlaceholder()
                  else if (_listNilai.isEmpty)
                    _buildKosong()
                  else ...[
                    _buildTabelNilai(),
                    const SizedBox(height: 16),
                    _buildKartuRekap(),
                  ],
                ],
              ),
            ),
    );
  }

  void _loadNilaiIfReady() {
    if (_selectedMapel != null &&
        _selectedSemester != null &&
        _selectedTahunAjaran != null) {
      _loadNilai();
    }
  }

  // Kartu rekap perhitungan nilai
  Widget _buildKartuRekap() {
    if (_hasilHitung == null) return const SizedBox();

    final rataMateri = (_hasilHitung!['rata_materi'] as num?)?.toDouble() ?? 0;
    final rataPraktikum =
        (_hasilHitung!['rata_praktikum'] as num?)?.toDouble() ?? 0;
    final nilaiTugas = (_hasilHitung!['nilai_tugas'] as num?)?.toDouble() ?? 0;
    final nilaiAkhir = (_hasilHitung!['nilai_akhir'] as num?)?.toDouble() ?? 0;

    final akhirColor = _nilaiColor(nilaiAkhir);
    final akhirGrade = _nilaiGrade(nilaiAkhir);

    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: akhirColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: akhirColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: akhirColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: akhirColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Nilai Akhir',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1F36),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  nilaiAkhir.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: akhirColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card tabel nilai
  Widget _buildTabelNilai() {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header tabel
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  flex: 4,
                  child: Text(
                    'Judul Tugas',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Tipe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 45,
                  child: Text(
                    'Nilai',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          // Baris data
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _listNilai.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: Color(0xFFF1F3F9)),
            itemBuilder: (_, i) {
              final item = _listNilai[i];
              final tugas = item['tugas'];
              final isPraktikum = tugas?['type_tugas'] == 'praktikum';
              final nilaiAngka = (item['nilai'] as num).toDouble();
              final nilaiColor = _nilaiColor(nilaiAngka);

              final Color typeColor = isPraktikum
                  ? const Color(0xFFD97706)
                  : const Color(0xFF059669);
              final Color typeBg = isPraktikum
                  ? const Color(0xFFFEF3E0)
                  : const Color(0xFFE6FAF5);

              return Container(
                color: i % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    // No
                    SizedBox(
                      width: 32,
                      child: Text(
                        '${i + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF9AA0B2),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Judul tugas
                    Expanded(
                      flex: 4,
                      child: Text(
                        tugas?['judul_tugas'] ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1A1F36),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Tipe
                    SizedBox(
                      width: 70,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: typeBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isPraktikum ? 'Praktikum' : 'Teori',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: typeColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Nilai
                    SizedBox(
                      width: 45,
                      child: Text(
                        nilaiAngka.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: nilaiColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _rekapRow(
    String label,
    String value,
    Color color,
    Color bg,
    IconData icon, {
    String? subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1F36),
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────────
  Widget _buildPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.filter_list_rounded,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Pilih mata pelajaran, semester,\ndan tahun ajaran',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(
            Icons.assignment_outlined,
            size: 60,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada nilai untuk\nfilter yang dipilih',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: Color(0xFF1A1F36),
      ),
    );
  }

  InputDecoration _dropdownDecoration() {
    return InputDecoration(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: _primary),
      ),
    );
  }
}
