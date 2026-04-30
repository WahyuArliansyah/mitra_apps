import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/custom_bottom_nav.dart'; // Impor widget baru
import 'admin_dashboard_view.dart';
import 'admin_pengguna_view.dart';

class AdminMainNav extends StatefulWidget {
  const AdminMainNav({super.key});

  @override
  State<AdminMainNav> createState() => _AdminMainNavState();
}

class _AdminMainNavState extends State<AdminMainNav> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const AdminDashboardView(),
    const AdminPenggunaView(),
  ];

  // Daftar item navigasi menggunakan model NavItem dari file widget
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

  void initState() {
    super.initState();
    _setupPushNotification();
  }

  Future<void> _setupPushNotification() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // 1. Minta Izin
    await messaging.requestPermission();

    // 2. Ambil Token unik perangkat
    String? token = await messaging.getToken();

    if (token != null) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        // 3. Simpan ke Supabase agar admin bisa memantau di AdminPenggunaView[cite: 2, 4]
        await Supabase.instance.client
            .from('pengguna')
            .update({'fcm_token': token})
            .eq('id', user.id);
        print("Token berhasil diupdate: $token");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack menjaga posisi scroll di setiap halaman
      body: IndexedStack(index: _currentIndex, children: _pages),

      // Menggunakan widget yang sudah dipisah
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
