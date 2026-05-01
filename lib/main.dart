import 'package:flutter/material.dart';
import 'package:mitra_apps/views/admin_dashboard_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  await Supabase.initialize(
    url: 'https://wrunfjffssekkammjnto.supabase.co',
    anonKey: 'sb_publishable_OjXUJ_MEClop_5v0xQnVKg_RBFDNmKb',
  );

  // menyimpan session login
  final session = Supabase.instance.client.auth.currentSession;
  final bool loggedIn = session != null;
  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      // Jika isLoggedIn true, langsung ke nav-admin, jika tidak ke login
      initialRoute: isLoggedIn ? '/nav-admin' : '/login',
      routes: {
        '/login': (context) => const LoginView(),
        '/nav-admin': (context) => const AdminDashboardView(),
      },
    );
  }
}
