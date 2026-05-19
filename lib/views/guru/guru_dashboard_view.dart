import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _GuruDashboardViewState extends State<GuruDashboardView>
    with SingleTickerProviderStateMixin {
  final supabase = Supabase.instance.client;

  // ─── Design Tokens ─────────────────────────────────────────────────────────
  static const _accent = Color(0xFF3B82F6);
  static const _accentSoft = Color(0xFFEFF6FF);
  static const _bg = Color(0xFFF0F4FA);
  static const _white = Colors.white;
  static const _textDark = Color(0xFF0F172A);
  static const _textMuted = Color(0xFF64748B);

  List<Map<String, dynamic>> _listTugas = [];
  bool _isLoading = true;
  String _filterType = 'Semua';

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _ambilTugas();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _ambilTugas() async {
    if (widget.idGuru.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
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
      _fadeCtrl.forward(from: 0);
    } catch (e) {
      debugPrint('Error ambil data tugas: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterType == 'Semua') return _listTugas;
    return _listTugas.where((t) => t['type_tugas'] == _filterType).toList();
  }

  // ─── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _bg,
        body: RefreshIndicator(
          onRefresh: _ambilTugas,
          color: _accent,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ← Pakai GuruAppBar langsung, tidak perlu build header sendiri
              GuruAppBar(namaGuru: widget.namaGuru),
              SliverToBoxAdapter(child: _buildStatsSection()),
              SliverToBoxAdapter(child: _buildSectionHeader()),
              SliverToBoxAdapter(child: _buildFilterChips()),
              _buildTugasList(),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  // ─── Stats Section ──────────────────────────────────────────────────────────
  Widget _buildStatsSection() {
    final total = _listTugas.length;
    final teori = _listTugas.where((t) => t['type_tugas'] == 'teori').length;
    final praktikum = _listTugas
        .where((t) => t['type_tugas'] == 'praktikum')
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              label: 'Total Tugas',
              value: total,
              icon: Icons.assignment_rounded,
              iconColor: _accent,
              iconBg: _accentSoft,
              valueColor: _accent,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Teori',
              value: teori,
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFFECFDF5),
              valueColor: const Color(0xFF059669),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              label: 'Praktikum',
              value: praktikum,
              icon: Icons.science_rounded,
              iconColor: const Color(0xFFD97706),
              iconBg: const Color(0xFFFFFBEB),
              valueColor: const Color(0xFFD97706),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Section Header ─────────────────────────────────────────────────────────
  Widget _buildSectionHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Daftar Tugas',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: _textDark,
              letterSpacing: -0.3,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _accentSoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_filtered.length} tugas',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Filter Chips ───────────────────────────────────────────────────────────
  Widget _buildFilterChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _FilterChip(
              label: 'Semua',
              isSelected: _filterType == 'Semua',
              onTap: () => setState(() => _filterType = 'Semua'),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Teori',
              icon: Icons.menu_book_rounded,
              isSelected: _filterType == 'teori',
              onTap: () => setState(() => _filterType = 'teori'),
              selectedColor: const Color(0xFF059669),
              selectedBg: const Color(0xFFECFDF5),
            ),
            const SizedBox(width: 8),
            _FilterChip(
              label: 'Praktikum',
              icon: Icons.science_rounded,
              isSelected: _filterType == 'praktikum',
              onTap: () => setState(() => _filterType = 'praktikum'),
              selectedColor: const Color(0xFFD97706),
              selectedBg: const Color(0xFFFFFBEB),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tugas List ─────────────────────────────────────────────────────────────
  Widget _buildTugasList() {
    if (_isLoading) {
      return const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator(color: _accent)),
      );
    }

    if (_filtered.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: _accentSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.assignment_outlined,
                  size: 38,
                  color: _accent,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada tugas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tap tombol Tambah untuk membuat\ntugas baru',
                style: TextStyle(fontSize: 13, color: _textMuted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (ctx, i) => FadeTransition(
            opacity: _fadeAnim,
            child: TugasCard(
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
          ),
          childCount: _filtered.length,
        ),
      ),
    );
  }

  // ─── FAB ────────────────────────────────────────────────────────────────────
  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _accent.withOpacity(0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: FloatingActionButton.extended(
        onPressed: () => _showAddOptions(context),
        backgroundColor: Colors.transparent,
        elevation: 0,
        icon: const Icon(Icons.add_rounded, color: _white, size: 22),
        label: const Text(
          'Tambah',
          style: TextStyle(
            color: _white,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  // ─── Bottom Sheet ────────────────────────────────────────────────────────────
  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: _white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Apa yang ingin ditambahkan?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: _textDark,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Pilih jenis konten yang ingin Anda buat',
              style: TextStyle(fontSize: 13, color: _textMuted),
            ),
            const SizedBox(height: 24),
            _BottomSheetOption(
              icon: Icons.assignment_rounded,
              iconColor: _accent,
              iconBg: _accentSoft,
              title: 'Buat Tugas',
              subtitle: 'Berikan tugas teori atau praktikum kepada siswa',
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
            const SizedBox(height: 12),
            _BottomSheetOption(
              icon: Icons.menu_book_rounded,
              iconColor: const Color(0xFF059669),
              iconBg: const Color(0xFFECFDF5),
              title: 'Upload Materi',
              subtitle: 'Bagikan modul, PDF, atau bahan ajar',
              onTap: () {
                Navigator.pop(ctx);
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
}

// ─── Reusable Widgets ───────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final Color valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: valueColor,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color selectedColor;
  final Color selectedBg;

  const _FilterChip({
    required this.label,
    this.icon,
    required this.isSelected,
    required this.onTap,
    this.selectedColor = const Color(0xFF3B82F6),
    this.selectedBg = const Color(0xFFEFF6FF),
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? selectedColor.withOpacity(0.4)
                : const Color(0xFFE2E8F0),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: selectedColor.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 15,
                color: isSelected ? selectedColor : const Color(0xFF94A3B8),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? selectedColor : const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomSheetOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
