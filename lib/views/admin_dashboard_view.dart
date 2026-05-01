import 'package:flutter/material.dart';
import 'package:mitra_apps/views/admin_kelas_view.dart';
import 'package:mitra_apps/views/admin_mapel_view.dart';
import 'package:mitra_apps/views/admin_siswa_view.dart';
import 'package:mitra_apps/views/kelola_guru_view.dart';
import 'package:mitra_apps/views/kelola_mapping_guru_view.dart';
import 'package:mitra_apps/views/login_view.dart';
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
      setState(() {
        totalGuru = (guruData as List).length;
        totalSiswa = (siswaData as List).length;
        _isCounting = false;
      });
    } catch (e) {
      setState(() => _isCounting = false);
    }
  }

  Future<void> _getProfile() async {
    final user = supabase.auth.currentUser;
    print('Current user ID: ${user?.id}'); // ← cek di console

    if (user != null) {
      final data = await supabase
          .from('pengguna')
          .select('nama_lengkap, peran') // ← tambah peran untuk verifikasi
          .eq('id', user.id)
          .maybeSingle();

      print('Profile data: $data'); // ← cek hasilnya

      if (data != null) {
        setState(() => namaAdmin = data['nama_lengkap']);
      }
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
      if (ok == true && mounted) {
        await supabase.auth.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: RefreshIndicator(
        // ← wrap di sini
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
                    _buildStatRow(),
                    const SizedBox(height: 28),
                    _buildSectionLabel('Menu Utama'),
                    const SizedBox(height: 12),
                    _buildMenuGrid(),
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
                      // Avatar inisial
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

                      // Tombol logout
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

  // ── Label Section ────────────────────────────────────────
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

  // ── Stat Row ─────────────────────────────────────────────
  Widget _buildStatRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            'Total Guru',
            totalGuru,
            Icons.person_rounded,
            const Color(0xFF4E73DF),
            const Color(0xFFEEF2FF),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            'Total Siswa',
            totalSiswa,
            Icons.groups_rounded,
            const Color(0xFF1CC88A),
            const Color(0xFFE8FBF4),
          ),
        ),
      ],
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
      padding: const EdgeInsets.all(18),
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
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isCounting ? '...' : '$value',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0B2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Menu Grid ────────────────────────────────────────────
  Widget _buildMenuGrid() {
    final menus = [
      _Menu(
        'Data Kelas',
        Icons.class_rounded,
        const Color(0xFF7C3AED),
        const Color(0xFFF0EBFF),
        const AdminKelasView(),
      ),
      _Menu(
        'Mata Pelajaran',
        Icons.menu_book_rounded,
        const Color(0xFF059669),
        const Color(0xFFE6FAF5),
        const AdminMapelView(),
      ),
      _Menu(
        'Data Guru',
        Icons.school_rounded,
        const Color(0xFFDC2626),
        const Color(0xFFFEECEC),
        const KelolaGuruView(),
      ),
      _Menu(
        'Data Siswa',
        Icons.face_rounded,
        const Color(0xFFD97706),
        const Color(0xFFFEF3E0),
        const AdminSiswaView(),
      ),
      _Menu(
        'Penugasan Guru',
        Icons.assignment_rounded,
        const Color(0xFF7C3AED),
        const Color(0xFFF0EBFF),
        const KelolaMapingGuruView(),
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 14,
      mainAxisSpacing: 14,
      childAspectRatio: 1.05,
      children: menus.map((m) => _menuCard(m)).toList(),
    );
  }

  Widget _menuCard(_Menu m) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => m.page),
      ).then((_) => _hitungDataReal()),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: m.bg,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(m.icon, color: m.color, size: 24),
            ),
            const Spacer(),
            Text(
              m.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1F36),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'Kelola data',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 11,
                  color: Colors.grey.shade300,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Menu {
  final String title;
  final IconData icon;
  final Color color, bg;
  final Widget page;
  const _Menu(this.title, this.icon, this.color, this.bg, this.page);
}
