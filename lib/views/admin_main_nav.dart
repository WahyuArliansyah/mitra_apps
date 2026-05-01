import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_bottom_nav.dart';
import 'admin_dashboard_view.dart';
import 'admin_pengguna_view.dart';

class AdminMainNav extends StatefulWidget {
  const AdminMainNav({super.key});

  @override
  State<AdminMainNav> createState() => _AdminMainNavState();
}

class _AdminMainNavState extends State<AdminMainNav> {
  int _currentIndex = 0;

  // ✅ Tidak perlu List<Widget> _pages lagi

  final List<NavItem> _navItems = const [
    NavItem(
      label: 'Dashboard',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard_rounded,
    ),
    NavItem(
      label: 'Pengguna',
      icon: Icons.manage_accounts_outlined,
      activeIcon: Icons.manage_accounts_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setupPushNotification();
  }

  Future<void> _setupPushNotification() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission();
    String? token = await messaging.getToken();
    if (token != null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('pengguna')
            .update({'fcm_token': token})
            .eq('id', user.id);
        print("Token berhasil diupdate: $token");
      }
    }
  }

  // ✅ Fungsi untuk build halaman sesuai index
  Widget _buildPage() {
    switch (_currentIndex) {
      case 0:
        return const AdminDashboardView();
      case 1:
        return const AdminPenggunaView();
      default:
        return const AdminDashboardView();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ Ganti IndexedStack dengan _buildPage()
      // Setiap pindah tab, halaman rebuild & data di-fetch ulang
      body: _buildPage(),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
      ),
    );
  }
}
