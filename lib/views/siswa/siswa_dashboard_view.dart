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

  static const _primary = Color(0xFF1A3FA8);
  static const _bg = Color(0xFFF0F4FB);

  String _namaSiswa = '';
  String _namaKelas = '';
  String _idKelas = '';
  bool _isLoading = true;

  List<Map<String, dynamic>> _listTugas = [];
  List<Map<String, dynamic>> _listMateri = [];
  Map<String, Map<String, dynamic>?> _statusPengumpulan = {};

  Set<String> _readTugasIds = {};
  Set<String> _readMateriIds = {};

  int get _unreadTugasCount => _listTugas
      .where((t) => !_readTugasIds.contains(t['id'].toString()))
      .length;

  int get _unreadMateriCount => _listMateri
      .where((m) => !_readMateriIds.contains(m['id'].toString()))
      .length;

  int get _belumKumpulCount => _listTugas.where((t) {
    final status = _statusPengumpulan[t['id'].toString()];
    return status == null;
  }).length;

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

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _readTugasIds = await _readService.getReadTugasIds();
      _readMateriIds = await _readService.getReadMateriIds();

      final siswaData = await _supabase
          .from('siswa')
          .select('nama_siswa, id_kelas, kelas(nama_kelas)')
          .eq('id_siswa', widget.idSiswa)
          .maybeSingle();

      if (siswaData == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      _namaSiswa = siswaData['nama_siswa'] ?? 'Siswa';
      _idKelas = siswaData['id_kelas']?.toString() ?? '';
      _namaKelas = siswaData['kelas']?['nama_kelas'] ?? '';

      final tugasData = await _supabase
          .from('tugas')
          .select('*, kelas(nama_kelas), mata_pelajaran(nama_mapel)')
          .eq('id_kelas', _idKelas)
          .eq('type_tugas', 'teori')
          .eq('metode', 'upload')
          .order('created_at', ascending: false);

      final listTugas = List<Map<String, dynamic>>.from(tugasData);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : Stack(
              children: [
                Column(
                  children: [
                    SiswaAppBar(namaSiswa: _namaSiswa, namaKelas: _namaKelas),
                    // Tab bar
                    Transform.translate(
                      offset: const Offset(0, -20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: _buildTabBar(),
                      ),
                    ),
                    Expanded(
                      child: Transform.translate(
                        offset: const Offset(0, -20),
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
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(9),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: const Color(0xFF6B7280),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 13,
        ),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.assignment_rounded, size: 16),
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
                const Icon(Icons.menu_book_rounded, size: 16),
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
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
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 32),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, size: 36, color: const Color(0xFFD1D5DB)),
          ),
          const SizedBox(height: 16),
          Text(
            pesan,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9CA3AF),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(fontSize: 13, color: Color(0xFFD1D5DB)),
          ),
        ],
      ),
    );
  }
}
