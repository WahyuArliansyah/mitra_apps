import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitra_apps/services/rekap_kelas_service.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/widgets/guru/detail_nilai_rekap.dart';
import 'package:open_filex/open_filex.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminRekapNilaiView extends StatefulWidget {
  const AdminRekapNilaiView({super.key});

  @override
  State<AdminRekapNilaiView> createState() => _AdminRekapNilaiViewState();
}

class _AdminRekapNilaiViewState extends State<AdminRekapNilaiView> {
  final supabase = Supabase.instance.client;
  static const _bg = Color(0xFFF4F6FB);
  static const _blue = Color(0xFF4E73DF);
  String namaAdmin = "Admin";

  List<Map<String, dynamic>> _guruList = [];
  Map<String, dynamic>? _guruTerpilih;

  List<Map<String, dynamic>> _penugasanList = [];
  Map<String, dynamic>? _penugasanTerpilih;

  List<Map<String, dynamic>> _rekapList = [];

  String _semester = '1';
  String _tahunAjaran = '${DateTime.now().year}/${DateTime.now().year + 1}';
  String _namaKelasTerpilih = '';
  String _namaMapelTerpilih = '';
  String _nipGuru = '';

  bool _isLoadingGuru = true;
  bool _isLoadingPenugasan = false;
  bool _isLoadingRekap = false;
  bool _isDownloading = false;

  final _rekapKelasService = RekapKelasService();

  @override
  void initState() {
    super.initState();
    _ambilGuru();
  }

  // ── Ambil semua guru ─────────────────────────────────────────
  Future<void> _ambilGuru() async {
    setState(() => _isLoadingGuru = true);
    try {
      final data = await supabase
          .from('guru')
          .select('id_guru, nama_lengkap, nip')
          .order('nama_lengkap', ascending: true);

      if (!mounted) return;
      setState(() {
        _guruList = List<Map<String, dynamic>>.from(data);
        _isLoadingGuru = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingGuru = false);
    }
  }

  // ── Ambil penugasan berdasarkan guru terpilih ────────────────
  Future<void> _ambilPenugasan(String idGuru) async {
    setState(() {
      _isLoadingPenugasan = true;
      _penugasanTerpilih = null;
      _penugasanList = [];
      _rekapList = [];
    });
    try {
      final data = await supabase
          .from('penugasan_guru')
          .select('*, kelas(id, nama_kelas), mata_pelajaran(id, nama_mapel)')
          .eq('id_guru', idGuru);

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

  // ── Ambil rekap nilai ────────────────────────────────────────
  Future<void> _ambilRekap() async {
    if (_penugasanTerpilih == null || _guruTerpilih == null) return;
    setState(() => _isLoadingRekap = true);

    try {
      final idKelas = _penugasanTerpilih!['kelas']['id'].toString();
      final idMapel = _penugasanTerpilih!['mata_pelajaran']['id'].toString();

      final siswaList = await supabase
          .from('siswa')
          .select('id_siswa, nama_siswa, nis')
          .eq('id_kelas', idKelas)
          .order('nama_siswa', ascending: true);

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
        _namaKelasTerpilih = _penugasanTerpilih!['kelas']['nama_kelas'];
        _namaMapelTerpilih =
            _penugasanTerpilih!['mata_pelajaran']['nama_mapel'];
        _nipGuru = _guruTerpilih!['nip']?.toString() ?? '';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingRekap = false);
    }
  }

  // Fungsi Logout
  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
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
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await supabase.auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  // Fungsi Download rekap
  Future<void> _downloadRekap() async {
    if (_rekapList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tampilkan data dulu sebelum download')),
      );
      return;
    }

    setState(() => _isDownloading = true);

    final path = await _rekapKelasService.downloadRekapKelas(
      namaGuru: _guruTerpilih!['nama_lengkap'],
      nip: _nipGuru,
      namaKelas: _namaKelasTerpilih,
      namaMapel: _namaMapelTerpilih,
      semester: _semester,
      tahunAjaran: _tahunAjaran,
      rekapList: _rekapList,
    );

    setState(() => _isDownloading = false);
    if (!mounted) return;

    if (path != null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  color: Color(0xFF059669),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Berhasil Diunduh!',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'File tersimpan di:\n$path',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                OpenFilex.open(path);
              },
              child: const Text(
                'Buka File',
                style: TextStyle(
                  color: Color(0xFF0F2D5C),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_rounded,
                color: Colors.redAccent,
                size: 56,
              ),
              const SizedBox(height: 12),
              const Text(
                'Gagal',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1F36),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gagal mengunduh file. Coba lagi.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F2D5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 100,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF4E73DF),
              elevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C8EF5), Color(0xFF3A5BD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: Text(
                                  namaAdmin.isNotEmpty
                                      ? namaAdmin[0].toUpperCase()
                                      : 'A',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Selamat Datang',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      namaAdmin,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _logout,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white30),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.logout_rounded,
                                        color: Colors.white,
                                        size: 15,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        'Logout',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            //
            SliverToBoxAdapter(
              child: Container(
                color: _bg,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    // Dropdown Guru
                    _isLoadingGuru
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              color: _blue,
                              strokeWidth: 2,
                            ),
                          )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            isExpanded: true,
                            value: _guruTerpilih,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              prefixIcon: const Icon(
                                Icons.person_rounded,
                                color: _blue,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            hint: const Text('Pilih Guru'),
                            items: _guruList
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(
                                      g['nama_lengkap'],
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              setState(() {
                                _guruTerpilih = v;
                                _penugasanTerpilih = null;
                                _rekapList = [];
                              });
                              if (v != null) {
                                _ambilPenugasan(v['id_guru'].toString());
                              }
                            },
                          ),
                    const SizedBox(height: 10),

                    // Dropdown Kelas & Mapel
                    _isLoadingPenugasan
                        ? const Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(
                              color: _blue,
                              strokeWidth: 2,
                            ),
                          )
                        : DropdownButtonFormField<Map<String, dynamic>>(
                            isExpanded: true,
                            value: _penugasanTerpilih,
                            dropdownColor: Colors.white,
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              prefixIcon: const Icon(
                                Icons.class_rounded,
                                color: _blue,
                                size: 20,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            hint: Text(
                              _guruTerpilih == null
                                  ? 'Pilih guru dulu'
                                  : 'Pilih Kelas & Mapel',
                            ),
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
                            onChanged: _guruTerpilih == null
                                ? null
                                : (v) => setState(() => _penugasanTerpilih = v),
                          ),
                    const SizedBox(height: 10),

                    // Semester + Tombol
                    Row(
                      children: [
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
                              fillColor: Colors.white,
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
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _ambilRekap,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _blue,
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
                        const SizedBox(width: 8),
                        _isDownloading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: _blue,
                                  strokeWidth: 2,
                                ),
                              )
                            : ElevatedButton(
                                onPressed: _downloadRekap,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.download_rounded,
                                  size: 18,
                                ),
                              ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Rekap List ───────────────────────────────────────────
            if (_isLoadingRekap)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: _blue)),
              )
            else if (_rekapList.isEmpty)
              SliverFillRemaining(
                child: Center(
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
                            ? 'Pilih guru, kelas & mapel dulu'
                            : 'Belum ada data nilai',
                        style: TextStyle(color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (ctx, i) => _buildRekapCard(_rekapList[i], i + 1),
                    childCount: _rekapList.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
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
            namaKelas: _namaKelasTerpilih,
            namaMapel: _namaMapelTerpilih,
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
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '$no',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _blue,
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
                      _miniInfo('Teori', rataMateri, const Color(0xFF0EA5E9)),
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
