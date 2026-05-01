import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaDashboardView extends StatefulWidget {
  const SiswaDashboardView({super.key});

  @override
  State<SiswaDashboardView> createState() => _SiswaDashboardViewState();
}

class _SiswaDashboardViewState extends State<SiswaDashboardView> {
  @override
  void initState() {
    super.initState();
    _setupPushNotification();
  }

  // memmanggil token FCM dan menyimpannya ke database
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

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
