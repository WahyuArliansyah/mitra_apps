import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/guru_dashboard_view.dart';
import 'package:mitra_apps/views/guru/guru_kelas_view.dart';
import 'package:mitra_apps/views/guru/guru_rekap_nilai_view.dart';
// import 'package:mitra_apps/views/guru/guru_rekap_nilai_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruMainNav extends StatefulWidget {
  const GuruMainNav({super.key});

  @override
  State<GuruMainNav> createState() => _GuruMainNavState();
}

class _GuruMainNavState extends State<GuruMainNav> {
  int _currentIndex = 0;
  static const _primary = Color(0xFF0EA5E9);
  String _namaGuru = '';
  String _idGuru = '';

  @override
  void initState() {
    super.initState();
    _ambilDataGuru();
  }

  Future<void> _ambilDataGuru() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final data = await Supabase.instance.client
          .from('guru')
          .select('id_guru, nama_lengkap')
          .eq('user_id', user.id)
          .maybeSingle();
      if (data != null && mounted) {
        setState(() {
          _idGuru = data['id_guru'];
          _namaGuru = data['nama_lengkap'];
        });
      }
    }
  }

  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return GuruDashboardView(idGuru: _idGuru, namaGuru: _namaGuru);
      case 1:
        return GuruKelasView(idGuru: _idGuru);
      case 2:
        return GuruRekapNilaiView(idGuru: _idGuru);
      default:
        return GuruDashboardView(idGuru: _idGuru, namaGuru: _namaGuru);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  0,
                  Icons.dashboard_outlined,
                  Icons.dashboard_rounded,
                  'Dashboard',
                ),
                _navItem(1, Icons.class_outlined, Icons.class_rounded, 'Kelas'),
                _navItem(
                  2,
                  Icons.bar_chart_outlined,
                  Icons.bar_chart_rounded,
                  'Rekap Nilai',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData icon, IconData activeIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? _primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : icon,
              color: isActive ? _primary : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? _primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
