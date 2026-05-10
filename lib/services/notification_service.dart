import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Handler untuk notifikasi saat app di background/terminated
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await _showLocalNotification(message);
}

// Plugin instance (global agar bisa diakses dari background handler)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// Channel Android
const AndroidNotificationChannel _channel = AndroidNotificationChannel(
  'mitra_high_importance', // id channel
  'Notifikasi Mitra', // nama channel
  description: 'Notifikasi tugas dan materi dari aplikasi Mitra',
  importance: Importance.high,
  playSound: true,
  enableVibration: true,
  showBadge: true,
  sound: RawResourceAndroidNotificationSound(
    'notifikasi',
  ), // file di res/raw/notifikasi.mp3
);

// Fungsi tampilkan notifikasi lokal (dipanggil dari background & foreground)
Future<void> _showLocalNotification(RemoteMessage message) async {
  final notification = message.notification;
  if (notification == null) return;

  final androidDetails = AndroidNotificationDetails(
    _channel.id,
    _channel.name,
    channelDescription: _channel.description,
    importance: Importance.high,
    priority: Priority.high,
    playSound: true,
    enableVibration: true,
    sound: const RawResourceAndroidNotificationSound('notifikasi'),
    icon: '@mipmap/ic_launcher',
    // Style BigText agar pesan panjang tetap terbaca
    styleInformation: BigTextStyleInformation(
      notification.body ?? '',
      contentTitle: notification.title,
      summaryText: 'Mitra App',
    ),
  );

  const iosDetails = DarwinNotificationDetails(
    presentAlert: true,
    presentBadge: true,
    presentSound: true,
  );

  final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

  await flutterLocalNotificationsPlugin.show(
    id: notification.hashCode,
    title: notification.title,
    body: notification.body,
    notificationDetails: details,
  );
}

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initNotification() async {
    // 1. Minta izin notifikasi
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      return; // User tolak izin, hentikan
    }

    // 2. Buat channel Android (wajib untuk Android 8+)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(_channel);

    // 3. Inisialisasi flutter_local_notifications
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await flutterLocalNotificationsPlugin.initialize(
      settings: const InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      ),
      onDidReceiveNotificationResponse: (response) {
        // TODO: navigasi ke halaman tertentu saat notifikasi diklik
      },
    );

    // 4. Ambil & simpan FCM token
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await _updateTokenToDatabase(token);
      }
    } catch (e) {
      debugPrint('FCM token gagal diambil: $e');
      // Tidak crash, lanjut saja
    }

    // 5. Refresh token otomatis jika berubah
    _fcm.onTokenRefresh.listen(
      _updateTokenToDatabase,
      onError: (e) => debugPrint('Token refresh error: $e'),
    );

    // 6. Tampilkan notifikasi saat app di FOREGROUND
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // 7. Handle notifikasi saat app dibuka dari background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // TODO: navigasi ke halaman tertentu berdasarkan data notifikasi
      // Contoh: if (message.data['type'] == 'tugas') { navigasi ke tugas }
    });

    // 8. Cek apakah app dibuka dari notifikasi saat terminated
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      // TODO: navigasi ke halaman tertentu
    }
  }

  // Simpan FCM token ke Supabase
  Future<void> _updateTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase
          .from('pengguna')
          .update({'fcm_token': token})
          .eq('id', user.id);
    }
  }
}
