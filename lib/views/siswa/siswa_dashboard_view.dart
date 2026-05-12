import 'package:flutter/material.dart';
import 'package:mitra_apps/services/read_status_service.dart';
import 'package:mitra_apps/views/siswa/detail_tugas_siswa.dart';
import 'package:mitra_apps/widgets/siswa/materi_card.dart';
import 'package:mitra_apps/widgets/siswa/siswa_app_bar.dart';
import 'package:mitra_apps/widgets/siswa/tab_badge.dart';
import 'package:mitra_apps/widgets/siswa/tugas_card_siswa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaDashboardView extends StatefulWidget {
  final String idSiswa;

  const SiswaDashboardView({super.key, required this.idSiswa});

  @override
  State<SiswaDashboardView> createState() => _SiswaDashboardViewState();
}

class _SiswaDashboardViewState extends State<SiswaDashboardView>
    with SingleTickerProviderStateMixin {
  final _supabase = Supabase.instance.client;
  late final ReadStatusService _readService;
  late TabController _tabController;

  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  String _namaSiswa = '';
  String _idKelas = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _listTugas = [];
  List<Map<String, dynamic>> _listMateri = [];
  Map<String, Map<String, dynamic>?> _statusPengumpulan = {};

  Set<String> _readTugasIds = {};
  Set<String> _readMateriIds = {};

  // Getter untuk menghitung jumlah tugas dan materi yang belum dibaca

  int get _unreadTugasCount => _listTugas
      .where((t) => !_readTugasIds.contains(t['id'].toString()))
      .length;

  int get _unreadMateriCount => _listMateri
      .where((m) => !_readMateriIds.contains(m['id'].toString()))
      .length;

  // Fungsi untuk menandai tugas atau materi sebagai sudah dibaca

  @override
  void initState() {
    super.initState();
    _readService = ReadStatusService(idSiswa: widget.idSiswa);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Mengambil data tugas, materi, dan status baca dari Supabase

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load status baca
      _readTugasIds = await _readService.getReadTugasIds();
      _readMateriIds = await _readService.getReadMateriIds();

      // Ambil data siswa
      final siswaData = await _supabase
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

      // Ambil tugas
      final tugasData = await _supabase
          .from('tugas')
          .select('*, kelas(nama_kelas), mata_pelajaran(nama_mapel)')
          .eq('id_kelas', _idKelas)
          .eq('type_tugas', 'teori')
          .eq('metode', 'upload')
          .order('created_at', ascending: false);

      final listTugas = List<Map<String, dynamic>>.from(tugasData);

      // Ambil status pengumpulan
      final idTugasList = listTugas.map((t) => t['id']).toList();
      final Map<String, Map<String, dynamic>?> statusMap = {};

      if (idTugasList.isNotEmpty) {
        final pengumpulanData = await _supabase
            .from('pengumpulan')
            .select()
            .eq('id_siswa', widget.idSiswa)
            .inFilter('id_tugas', idTugasList);

        for (final p in pengumpulanData) {
          statusMap[p['id_tugas'].toString()] = Map<String, dynamic>.from(p);
        }
      }
      for (final t in listTugas) {
        statusMap.putIfAbsent(t['id'].toString(), () => null);
      }

      // Ambil materi
      final materiData = await _supabase
          .from('materi')
          .select('*, kelas(nama_kelas), mata_pelajaran(nama_mapel)')
          .eq('id_kelas', _idKelas)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _listTugas = listTugas;
        _listMateri = List<Map<String, dynamic>>.from(materiData);
        _statusPengumpulan = statusMap;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error load data siswa: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Tugas dan Materi Tap Handler

  Future<void> _onTugasTap(Map<String, dynamic> tugas) async {
    await _readService.markTugasAsRead(tugas['id'].toString(), _readTugasIds);
    if (!mounted) return;
    setState(() {});
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailTugasSiswa(tugas: tugas, idSiswa: widget.idSiswa),
      ),
    );
    _loadData();
  }

  Future<void> _onMateriTap(Map<String, dynamic> materi) async {
    await _readService.markMateriAsRead(
      materi['id'].toString(),
      _readMateriIds,
    );
    if (mounted) setState(() {});
  }

  // Build UI

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: SiswaAppBar(namaSiswa: _namaSiswa),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RefreshIndicator(
                        onRefresh: _loadData,
                        color: _primary,
                        child: _buildListTugas(),
                      ),
                      RefreshIndicator(
                        onRefresh: _loadData,
                        color: _primary,
                        child: _buildListMateri(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
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
                if (_unreadTugasCount > 0) ...[
                  const SizedBox(width: 6),
                  TabBadge(count: _unreadTugasCount),
                ],
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
                if (_unreadMateriCount > 0) ...[
                  const SizedBox(width: 6),
                  TabBadge(count: _unreadMateriCount),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

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
      itemBuilder: (_, i) {
        final tugas = _listTugas[i];
        return TugasCard(
          tugas: tugas,
          pengumpulan: _statusPengumpulan[tugas['id'].toString()],
          isUnread: !_readTugasIds.contains(tugas['id'].toString()),
          onTap: () => _onTugasTap(tugas),
        );
      },
    );
  }

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
      itemBuilder: (_, i) {
        final materi = _listMateri[i];
        return MateriCard(
          materi: materi,
          isUnread: !_readMateriIds.contains(materi['id'].toString()),
          onTap: () => _onMateriTap(materi),
        );
      },
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
