import 'package:flutter/material.dart';
import 'package:mitra_apps/views/siswa/detail_tugas_siswa.dart';
import 'package:mitra_apps/widgets/siswa_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class SiswaDashboardView extends StatefulWidget {
  final String idSiswa;

  const SiswaDashboardView({super.key, required this.idSiswa});

  @override
  State<SiswaDashboardView> createState() => _SiswaDashboardViewState();
}

class _SiswaDashboardViewState extends State<SiswaDashboardView>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  String _namaSiswa = '';
  String _idKelas = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _listTugas = [];
  List<Map<String, dynamic>> _listMateri = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // 1. Ambil data siswa
      final siswaData = await supabase
          .from('siswa')
          .select('nama_siswa, id_kelas')
          .eq('id_siswa', widget.idSiswa)
          .maybeSingle();

      if (siswaData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _namaSiswa = siswaData['nama_siswa'] ?? 'Siswa';
      _idKelas = siswaData['id_kelas']?.toString() ?? '';

      // 2. Ambil tugas: hanya type_tugas=teori & metode=upload
      final tugasData = await supabase
          .from('tugas')
          .select('*, kelas(nama_kelas), mata_pelajaran(nama_mapel)')
          .eq('id_kelas', _idKelas)
          .eq('type_tugas', 'teori')
          .eq('metode', 'upload')
          .order('created_at', ascending: false);

      // 3. Ambil semua materi sesuai kelas
      final materiData = await supabase
          .from('materi')
          .select('*, kelas(nama_kelas), mata_pelajaran(nama_mapel)')
          .eq('id_kelas', _idKelas)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _listTugas = List<Map<String, dynamic>>.from(tugasData);
        _listMateri = List<Map<String, dynamic>>.from(materiData);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load data siswa: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  String _formatTenggat(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return DateFormat(
        'dd MMM yyyy, HH:mm',
      ).format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  bool _isDeadlineNear(String? isoDate) {
    if (isoDate == null) return false;
    try {
      final deadline = DateTime.parse(isoDate).toLocal();
      final diff = deadline.difference(DateTime.now()).inDays;
      return diff <= 2 && deadline.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _isDeadlinePassed(String? isoDate) {
    if (isoDate == null) return false;
    try {
      return DateTime.parse(isoDate).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: _isLoading
          ? AppBar(
              backgroundColor: _primary,
              elevation: 0,
              title: const Text(
                'Loading...',
                style: TextStyle(color: Colors.white),
              ),
            )
          : SiswaAppBar(namaSiswa: _namaSiswa),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                // TabBar
                Container(
                  color: Colors.white,
                  child: TabBar(
                    controller: _tabController,
                    labelColor: _primary,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _primary,
                    indicatorWeight: 3,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.assignment_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text('Tugas (${_listTugas.length})'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.menu_book_rounded, size: 18),
                            const SizedBox(width: 6),
                            Text('Materi (${_listMateri.length})'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // TabBarView
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadData,
                    color: _primary,
                    child: TabBarView(
                      controller: _tabController,
                      children: [_buildListTugas(), _buildListMateri()],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── LIST TUGAS ─────────────────────────────────────────────────────────────
  Widget _buildListTugas() {
    if (_listTugas.isEmpty) {
      return _buildKosong(
        icon: Icons.assignment_outlined,
        pesan: 'Belum ada tugas',
        sub: 'Tugas dari guru akan muncul di sini',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _listTugas.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildTugasCard(_listTugas[i]),
    );
  }

  Widget _buildTugasCard(Map<String, dynamic> tugas) {
    final deadline = tugas['tenggat_waktu']?.toString();
    final isNear = _isDeadlineNear(deadline);
    final isPassed = _isDeadlinePassed(deadline);

    Color deadlineColor = const Color(0xFF6B7280);
    if (isPassed) deadlineColor = Colors.redAccent;
    if (isNear && !isPassed) deadlineColor = const Color(0xFFD97706);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              DetailTugasSiswa(tugas: tugas, idSiswa: widget.idSiswa),
        ),
      ).then((_) => _loadData()),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Strip biru (teori)
            Container(
              height: 5,
              decoration: const BoxDecoration(
                color: _primary,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2FE),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment_rounded,
                          color: _primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tugas['judul_tugas'] ?? '-',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1F36),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              tugas['mata_pelajaran']?['nama_mapel'] ?? '-',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF9AA0B2),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Badge status tenggat
                      if (isPassed)
                        _badge(
                          'Terlambat',
                          Colors.redAccent,
                          const Color(0xFFFFEDED),
                        )
                      else if (isNear)
                        _badge(
                          'Segera',
                          const Color(0xFFD97706),
                          const Color(0xFFFEF3E0),
                        )
                      else
                        _badge('Aktif', _primary, const Color(0xFFE0F2FE)),
                    ],
                  ),
                  if (tugas['deskripsi'] != null &&
                      tugas['deskripsi'].toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      tugas['deskripsi'],
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF4B5563),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xFFF1F3F9)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(
                        Icons.class_rounded,
                        size: 14,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        tugas['kelas']?['nama_kelas'] ?? '-',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isPassed
                            ? Icons.warning_rounded
                            : Icons.access_time_rounded,
                        size: 14,
                        color: deadlineColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTenggat(deadline),
                        style: TextStyle(
                          fontSize: 11,
                          color: deadlineColor,
                          fontWeight: isNear || isPassed
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DetailTugasSiswa(
                            tugas: tugas,
                            idSiswa: widget.idSiswa,
                          ),
                        ),
                      ).then((_) => _loadData()),
                      icon: const Icon(Icons.upload_file_rounded, size: 16),
                      label: const Text('Lihat & Kumpulkan'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── LIST MATERI ────────────────────────────────────────────────────────────
  Widget _buildListMateri() {
    if (_listMateri.isEmpty) {
      return _buildKosong(
        icon: Icons.library_books_outlined,
        pesan: 'Belum ada materi',
        sub: 'Materi dari guru akan muncul di sini',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      itemCount: _listMateri.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _buildMateriCard(_listMateri[i]),
    );
  }

  Widget _buildMateriCard(Map<String, dynamic> materi) {
    const Color color = Color(0xFF7C3AED);
    const Color bg = Color(0xFFF3F0FF);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Strip ungu
          Container(
            height: 5,
            decoration: const BoxDecoration(
              color: color,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            materi['judul_materi'] ?? '-',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1F36),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            materi['mata_pelajaran']?['nama_mapel'] ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF9AA0B2),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _badge('Materi', color, bg),
                  ],
                ),
                if (materi['deskripsi'] != null &&
                    materi['deskripsi'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    materi['deskripsi'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                const Divider(height: 1, color: Color(0xFFF1F3F9)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.class_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      materi['kelas']?['nama_kelas'] ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Smt ${materi['semester'] ?? '-'}  •  ${materi['tahun_ajaran'] ?? '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatTanggal(materi['created_at']),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
                if (materi['url_file'] != null &&
                    materi['url_file'].toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse(materi['url_file']);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 16),
                      label: const Text('Buka File Materi'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────
  Widget _badge(String label, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildKosong({
    required IconData icon,
    required String pesan,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            pesan,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }
}
