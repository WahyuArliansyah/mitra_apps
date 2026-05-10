import 'package:flutter/material.dart';
import 'package:mitra_apps/services/notification_service.dart';
import 'package:mitra_apps/views/admin/admin_dashboard_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/views/splash_screen_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

// ── Background handler (pakai dari notification_service.dart) ──────────────
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  await firebaseMessagingBackgroundHandler(message);
}

// ── Channel Android prioritas tinggi ──────────────────────────────────────
const AndroidNotificationChannel channel = AndroidNotificationChannel(
  'mitra_high_importance',
  'Notifikasi Mitra',
  description: 'Notifikasi tugas dan materi dari aplikasi Mitra',
  importance: Importance.max,
  playSound: true,
  enableVibration: true,
  showBadge: true,
  sound: RawResourceAndroidNotificationSound('notifikasi'),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Inisialisasi Firebase
  await Firebase.initializeApp();

  // 2. Daftarkan background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // 3. Buat channel Android
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >()
      ?.createNotificationChannel(channel);

  // 4. Inisialisasi flutter_local_notifications
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosInit = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );
  await flutterLocalNotificationsPlugin.initialize(
    settings: const InitializationSettings(android: androidInit, iOS: iosInit),
  );

  // 5. Minta izin notifikasi
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // 6. Inisialisasi Supabase
  await Supabase.initialize(
    url: 'https://wrunfjffssekkammjnto.supabase.co',
    anonKey: 'sb_publishable_OjXUJ_MEClop_5v0xQnVKg_RBFDNmKb',
  );

  // 7. Beri waktu Supabase restore session
  await Future.delayed(const Duration(milliseconds: 300));

  // 8. Cek session login
  final session = Supabase.instance.client.auth.currentSession;
  final bool loggedIn = session != null;

  // 9. Inisialisasi NotificationService (foreground listener, token, dll)
  await NotificationService().initNotification();

  runApp(MyApp(isLoggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreenView(isLoggedIn: isLoggedIn),
      routes: {
        '/splash': (context) => SplashScreenView(isLoggedIn: isLoggedIn),
        '/login': (context) => const LoginView(),
        '/nav-admin': (context) => const AdminDashboardView(),
      },
    );
  }
}
