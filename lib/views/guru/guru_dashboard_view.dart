import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/materi/buat_materi_view.dart';
import 'package:mitra_apps/views/guru/tugas/buat_tugas_view.dart';
import 'package:mitra_apps/views/guru/tugas/detail_tugas_view.dart';
import 'package:mitra_apps/widgets/guru/guru_app_bar.dart';
import 'package:mitra_apps/widgets/guru/tugas_card_guru.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruDashboardView extends StatefulWidget {
  final String idGuru;
  final String namaGuru;

  const GuruDashboardView({
    super.key,
    required this.idGuru,
    required this.namaGuru,
  });

  @override
  State<GuruDashboardView> createState() => _GuruDashboardViewState();
}

class _GuruDashboardViewState extends State<GuruDashboardView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  List<Map<String, dynamic>> _listTugas = [];
  bool _isLoading = true;
  String _filterType = 'Semua';

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _ambilTugas();
      }
    });
  }

  Future<void> _ambilTugas() async {
    // Jika ID kosong, pastikan loading mati dan hentikan proses
    if (widget.idGuru.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    // Nyalakan loading sebelum menarik data
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('tugas')
          .select('*, kelas(nama_kelas), mata_pelajaran(nama_mapel)')
          .eq('id_guru', widget.idGuru)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _listTugas = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      // Menangkap dan mencetak error
      debugPrint('Error ambil data tugas: $e');

      // Matikan loading jika terjadi error
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterType == 'Semua') return _listTugas;
    return _listTugas.where((t) => t['type_tugas'] == _filterType).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: RefreshIndicator(
        onRefresh: _ambilTugas,
        color: _primary,
        child: CustomScrollView(
          slivers: [
            // App`Bar dari widget
            GuruAppBar(namaGuru: widget.namaGuru),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stat cards
                    _buildStatRow(),
                    const SizedBox(height: 20),
                    // Label
                    const Text(
                      'Daftar Tugas',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Filter chip
                    _buildFilterChip(),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // List tugas
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: _primary),
                    ),
                  )
                : _filtered.isEmpty
                ? SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            size: 60,
                            color: Colors.grey.shade300,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada tugas',
                            style: TextStyle(color: Colors.grey.shade400),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (ctx, i) => TugasCard(
                          tugas: _filtered[i],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailTugasView(
                                tugas: _filtered[i],
                                idGuru: widget.idGuru,
                              ),
                            ),
                          ).then((_) => _ambilTugas()),
                        ),
                        childCount: _filtered.length,
                      ),
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: _primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'Tambah',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildStatRow() {
    final totalTugas = _listTugas.length;
    final totalTeori = _listTugas
        .where((t) => t['type_tugas'] == 'teori')
        .length;
    final totalPraktikum = _listTugas
        .where((t) => t['type_tugas'] == 'praktikum')
        .length;

    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Total Tugas',
            totalTugas,
            Icons.assignment_rounded,
            _primary,
            const Color(0xFFE0F2FE),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Teori',
            totalTeori,
            Icons.menu_book_rounded,
            const Color(0xFF059669),
            const Color(0xFFE6FAF5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            'Praktikum',
            totalPraktikum,
            Icons.science_rounded,
            const Color(0xFFD97706),
            const Color(0xFFFEF3E0),
          ),
        ),
      ],
    );
  }

  // Membuat option tombol tambah dengan bottom sheet
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Apa yang ingin Anda tambahkan?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 20),
            // Tombol Buat Tugas
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_rounded, color: _primary),
              ),
              title: const Text(
                'Buat Tugas',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Berikan tugas teori atau praktikum',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuatTugasView(idGuru: widget.idGuru),
                  ),
                ).then((_) => _ambilTugas());
              },
            ),
            const SizedBox(height: 10),
            // Tombol Upload Materi
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FAF5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.menu_book_rounded,
                  color: Color(0xFF059669),
                ),
              ),
              title: const Text(
                'Upload Materi',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Bagikan modul, PDF, atau bahan ajar',
                style: TextStyle(fontSize: 12),
              ),
              onTap: () {
                Navigator.pop(ctx);
                // Navigasi ke halaman Buat Materi (kita buat di bawah)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BuatMateriView(idGuru: widget.idGuru),
                  ),
                ).then((_) => _ambilTugas());
              },
            ),
          ],
        ),
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
      child: Column(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
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

  Widget _buildFilterChip() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['Semua', 'teori', 'praktikum'].map((f) {
          final isSelected = _filterType == f;
          final label = f == 'teori'
              ? 'Teori'
              : f == 'praktikum'
              ? 'Praktikum'
              : 'Semua';
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (_) => setState(() => _filterType = f),
              selectedColor: _primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
