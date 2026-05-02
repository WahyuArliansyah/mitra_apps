import 'package:flutter/material.dart';
import 'package:mitra_apps/views/admin/admin_kelas_view.dart';
import 'package:mitra_apps/views/admin/admin_mapel_view.dart';
import 'package:mitra_apps/views/admin/admin_siswa_view.dart';
import 'package:mitra_apps/views/admin/kelola_guru_view.dart';
import 'package:mitra_apps/views/admin/kelola_mapping_guru_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/widgets/menu_tile.dart';
import 'package:mitra_apps/widgets/stat_card.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  final supabase = Supabase.instance.client;
  String namaAdmin = "Admin";
  int totalGuru = 0;
  int totalSiswa = 0;
  bool _isCounting = true;

  @override
  void initState() {
    super.initState();
    _getProfile();
    _hitungDataReal();
  }

  Future<void> _hitungDataReal() async {
    try {
      final guruData = await supabase.from('guru').select('id_guru');
      final siswaData = await supabase.from('siswa').select('id_siswa');
      if (!mounted) return;
      setState(() {
        totalGuru = (guruData as List).length;
        totalSiswa = (siswaData as List).length;
        _isCounting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isCounting = false);
    }
  }

  Future<void> _getProfile() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final data = await supabase
          .from('pengguna')
          .select('nama_lengkap')
          .eq('id', user.id)
          .maybeSingle();
      if (!mounted) return;
      if (data != null) setState(() => namaAdmin = data['nama_lengkap']);
    }
  }

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

  void _navigateTo(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    ).then((_) => _hitungDataReal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() => _isCounting = true);
          await _hitungDataReal();
          await _getProfile();
        },
        color: const Color(0xFF4E73DF),
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionLabel('Statistik Cepat'),
                    const SizedBox(height: 12),
                    // ✅ Pakai StatCard dari widgets/
                    Row(
                      children: [
                        Expanded(
                          child: StatCard(
                            label: 'Total Guru',
                            value: totalGuru,
                            icon: Icons.person_rounded,
                            color: const Color(0xFF4E73DF),
                            bg: const Color(0xFFEEF2FF),
                            isLoading: _isCounting,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: StatCard(
                            label: 'Total Siswa',
                            value: totalSiswa,
                            icon: Icons.groups_rounded,
                            color: const Color(0xFF1CC88A),
                            bg: const Color(0xFFE8FBF4),
                            isLoading: _isCounting,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Menu Utama'),
                    const SizedBox(height: 12),
                    // ✅ Pakai MenuTile dari widgets/
                    MenuTile(
                      title: 'Data Kelas',
                      icon: Icons.class_rounded,
                      color: const Color(0xFF7C3AED),
                      bg: const Color(0xFFF0EBFF),
                      onTap: () => _navigateTo(const AdminKelasView()),
                    ),
                    MenuTile(
                      title: 'Mata Pelajaran',
                      icon: Icons.menu_book_rounded,
                      color: const Color(0xFF059669),
                      bg: const Color(0xFFE6FAF5),
                      onTap: () => _navigateTo(const AdminMapelView()),
                    ),
                    MenuTile(
                      title: 'Data Guru',
                      icon: Icons.school_rounded,
                      color: const Color(0xFFDC2626),
                      bg: const Color(0xFFFEECEC),
                      onTap: () => _navigateTo(const KelolaGuruView()),
                    ),
                    MenuTile(
                      title: 'Data Siswa',
                      icon: Icons.face_rounded,
                      color: const Color(0xFFD97706),
                      bg: const Color(0xFFFEF3E0),
                      onTap: () => _navigateTo(const AdminSiswaView()),
                    ),
                    MenuTile(
                      title: 'Penugasan Guru',
                      icon: Icons.assignment_rounded,
                      color: const Color(0xFF0EA5E9),
                      bg: const Color(0xFFE0F2FE),
                      onTap: () => _navigateTo(const KelolaMapingGuruView()),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
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
                              'Selamat Datang 👋',
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
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1F36),
        letterSpacing: 0.2,
      ),
    );
  }
}
