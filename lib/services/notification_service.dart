import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final _supabase = Supabase.instance.client;

  Future<void> initNotification() async {
    // Meminta Izin ke Pengguna
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      // Mengambil Token Perangkat
      String? token = await _fcm.getToken();

      if (token != null) {
        print("FCM Token: $token");
        _updateTokenToDatabase(token);
      }
    }
  }

  // Menyimpan Token ke Tabel Pengguna (Supabase)
  Future<void> _updateTokenToDatabase(String token) async {
    final user = _supabase.auth.currentUser;
    if (user != null) {
      await _supabase
          .from('pengguna')
          .update({'fcm_token': token}) // Sesuai field di database kamu
          .eq('id', user.id);
    }
  }
}
