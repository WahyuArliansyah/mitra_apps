import 'package:flutter/material.dart';
import 'package:mitra_apps/views/admin/admin_dashboard_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/views/splash_screen_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// Fungsi penangkap notifikasi saat aplikasi ditutup (Wajib pakai pragma)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Harus inisialisasi Firebase lagi khusus untuk mode background
  await Firebase.initializeApp();
  print("Notifikasi masuk saat aplikasi mati: ${message.messageId}");
}

// Buat Channel Android berprioritas tinggi (Agar muncul pop-up banner & suara)
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'high_importance_channel', // ID ini wajib sama dengan yang di Edge Function
  'High Importance Notifications',
  description: 'Channel untuk notifikasi tugas penting',
  importance: Importance.max,
);

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi Firebase
  await Firebase.initializeApp();

  // Daftarkan handler background
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Daftarkan channel ke sistem Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // Minta izin notifikasi ke user (Memunculkan pop-up "Allow Notifications")
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://wrunfjffssekkammjnto.supabase.co', //[cite: 3]
    anonKey: 'sb_publishable_OjXUJ_MEClop_5v0xQnVKg_RBFDNmKb', //[cite: 3]
  );

  // Beri waktu Supabase restore session dari local storage
  await Future.delayed(const Duration(milliseconds: 300)); //[cite: 3]

  // menyimpan session login
  final session = Supabase.instance.client.auth.currentSession; //[cite: 3]
  final bool loggedIn = session != null; //[cite: 3]

  runApp(MyApp(isLoggedIn: loggedIn)); //[cite: 3]
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn}); //[cite: 3]

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, //[cite: 3]
      home: SplashScreenView(isLoggedIn: isLoggedIn), //[cite: 3]
      routes: {
        '/splash': (context) =>
            SplashScreenView(isLoggedIn: isLoggedIn), //[cite: 3]
        '/login': (context) => const LoginView(), //[cite: 3]
        '/nav-admin': (context) => const AdminDashboardView(), //[cite: 3]
      },
    );
  }
}
