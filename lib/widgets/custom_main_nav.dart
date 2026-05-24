import 'package:flutter/material.dart';
import 'package:mitra_apps/views/admin/admin_dashboard_view.dart';
import 'package:mitra_apps/views/admin/admin_rekap_nilai_view.dart';
import 'package:mitra_apps/views/siswa/rekap_nilai_siswa.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mitra_apps/views/guru/guru_dashboard_view.dart';
import 'package:mitra_apps/views/guru/guru_kelas_view.dart';
import 'package:mitra_apps/views/guru/guru_rekap_nilai_view.dart';
import 'package:mitra_apps/views/siswa/siswa_dashboard_view.dart';

class CustomMainNav extends StatefulWidget {
  final String userId;
  final String role;
  const CustomMainNav({super.key, required this.userId, required this.role});

  @override
  State<CustomMainNav> createState() => _CustomMainNavState();
}

class _CustomMainNavState extends State<CustomMainNav> {
  int _currentIndex = 0;

  String _peran = '';
  String _idProfile = '';
  String _namaProfile = '';
  String _idKelas = '';
  bool _isLoading = true;

  static const _guruColor = Color(0xFF4F46E5);
  static const _siswaColor = Color(0xFF1D9E75);

  Color get _activeColor => _peran == 'guru' ? _guruColor : _siswaColor;

  Color get _activeBg =>
      _peran == 'guru' ? const Color(0xFFEEF2FF) : const Color(0xFFE1F5EE);

  @override
  void initState() {
    super.initState();
    _ambilDataUser();
  }

  Future<void> _ambilDataUser() async {
    try {
      final dataPengguna = await Supabase.instance.client
          .from('pengguna')
          .select('peran')
          .eq('id', widget.userId)
          .maybeSingle();

      if (dataPengguna != null && mounted) {
        _peran = dataPengguna['peran'] ?? '';

        if (_peran == 'guru') {
          final data = await Supabase.instance.client
              .from('guru')
              .select('id_guru, nama_lengkap')
              .eq('user_id', widget.userId)
              .maybeSingle();
          if (data != null) {
            _idProfile = data['id_guru'];
            _namaProfile = data['nama_lengkap'];
          }
        } else if (_peran == 'siswa') {
          final data = await Supabase.instance.client
              .from('siswa')
              .select('id_siswa, nama_siswa, id_kelas')
              .eq('id_siswa', widget.userId)
              .maybeSingle();
          if (data != null) {
            _idProfile = data['id_siswa'].toString();
            _namaProfile = data['nama_siswa'];
            _idKelas = data['id_kelas'] ?? '';
          }
        } else if (_peran == 'admin') {
          // ← tambah
          _idProfile = widget.userId;
          final data = await Supabase.instance.client
              .from('pengguna')
              .select('nama_lengkap')
              .eq('id', widget.userId)
              .maybeSingle();
          if (data != null) _namaProfile = data['nama_lengkap'];
        }
      }
    } catch (e) {
      debugPrint('Error ambil data user: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPage() {
    if (_idProfile.isEmpty) {
      return const Center(child: Text('Data profil tidak ditemukan.'));
    }

    if (_peran == 'guru') {
      switch (_currentIndex) {
        case 0:
          return GuruDashboardView(idGuru: _idProfile, namaGuru: _namaProfile);
        case 1:
          return GuruKelasView(idGuru: _idProfile, namaGuru: _namaProfile);
        case 2:
          return GuruRekapNilaiView(idGuru: _idProfile, namaGuru: _namaProfile);
        default:
          return GuruDashboardView(idGuru: _idProfile, namaGuru: _namaProfile);
      }
    } else if (_peran == 'siswa') {
      switch (_currentIndex) {
        case 0:
          return SiswaDashboardView(idSiswa: _idProfile);
        case 1:
          return RekapNilaiSiswa(idSiswa: _idProfile);
        default:
          return SiswaDashboardView(idSiswa: _idProfile);
      }
    } else if (_peran == 'admin') {
      switch (_currentIndex) {
        case 0:
          return const AdminDashboardView();
        case 1:
          return const AdminRekapNilaiView();
        default:
          return const AdminDashboardView();
      }
    }

    return const Center(child: Text('Akses ditolak.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: _activeColor))
          : _buildPage(),
      bottomNavigationBar:
          _isLoading || (_idProfile.isEmpty && _peran != 'admin')
          ? null
          : _buildNavbar(),
    );
  }

  // ── Navbar ────────────────────────────────────────────────
  Widget _buildNavbar() {
    final items = _peran == 'guru'
        ? const [
            _NavItem(
              icon: Icons.space_dashboard_outlined,
              activeIcon: Icons.space_dashboard_rounded,
              label: 'Dashboard',
            ),
            _NavItem(
              icon: Icons.school_outlined,
              activeIcon: Icons.school_rounded,
              label: 'Kelas',
            ),
            _NavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Rekap Nilai',
            ),
          ]
        : _peran == 'admin'
        ? const [
            _NavItem(
              icon: Icons.space_dashboard_outlined,
              activeIcon: Icons.space_dashboard_rounded,
              label: 'Dashboard',
            ),
            _NavItem(
              icon: Icons.bar_chart_outlined,
              activeIcon: Icons.bar_chart_rounded,
              label: 'Rekap Nilai',
            ),
          ]
        : const [
            _NavItem(
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              label: 'Beranda',
            ),
            _NavItem(
              icon: Icons.insert_chart_outlined_rounded,
              activeIcon: Icons.insert_chart_rounded,
              label: 'Nilai Saya',
            ),
          ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF0F0F5), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              items.length,
              (i) => _buildTab(i, items[i]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(int index, _NavItem item) {
    final isActive = _currentIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill indicator di atas
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: isActive ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _activeColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Icon container
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isActive ? _activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isActive ? item.activeIcon : item.icon,
                color: isActive ? _activeColor : const Color(0xFFC4C8D4),
                size: 22,
              ),
            ),

            const SizedBox(height: 5),

            // Label
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? _activeColor : const Color(0xFFC4C8D4),
              ),
              child: Text(item.label, textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
