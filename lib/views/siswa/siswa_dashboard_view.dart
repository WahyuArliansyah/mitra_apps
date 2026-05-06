import 'package:flutter/material.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/views/pengaturan_notifikasi_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:firebase_messaging/firebase_messaging.dart'; //[cite: 2]

class SiswaDashboardView extends StatefulWidget {
  final String idSiswa; // Butuh ID Siswa untuk memfilter notifikasi[cite: 2]

  const SiswaDashboardView({super.key, required this.idSiswa});

  @override
  State<SiswaDashboardView> createState() => _SiswaDashboardViewState();
}

class _SiswaDashboardViewState extends State<SiswaDashboardView> {
  final supabase = Supabase.instance.client; //[cite: 2]
  static const _primary = Color(0xFF0EA5E9); //[cite: 2]
  static const _bg = Color(0xFFF4F6FB); //[cite: 2]

  late final Stream<List<Map<String, dynamic>>> _notifikasiStream; //[cite: 2]

  @override
  void initState() {
    super.initState();

    // 1. Jalankan update token FCM ke Supabase saat dashboard dibuka[cite: 2]
    _updateTokenSiswa();

    // 2. Dengarkan perubahan data notifikasi secara real-time[cite: 2]
    _notifikasiStream = supabase
        .from('notifikasi')
        .stream(primaryKey: ['id'])
        .eq('id_siswa', widget.idSiswa)
        .order('created_at', ascending: false);

    print("DEBUG: Mengupdate token untuk ID: ${widget.idSiswa}"); //[cite: 2]
  }

  Future<void> _updateTokenSiswa() async {
    try {
      // Ambil token dari device[cite: 2]
      String? token = await FirebaseMessaging.instance.getToken(); //[cite: 2]
      if (token != null) {
        // Simpan token ke database db_mitra di tabel pengguna[cite: 2]
        final response = await supabase
            .from('pengguna')
            .update({'fcm_token': token})
            .eq('id', widget.idSiswa)
            .select();

        print("FCM Token Siswa berhasil diupdate: $token"); //[cite: 2]
      }
    } on PostgrestException catch (e) {
      // Tangkap error jika ada masalah RLS di Supabase atau kolom tidak ditemukan
      print("Error Database (RLS/Kolom): ${e.message}"); //[cite:
    } catch (e) {
      print("Error Umum: $e"); //[cite: 2]
    }
  }

  // Fungsi untuk memformat tanggal (misal: 24 Des 2026, 14:30)[cite: 2]
  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return ''; //[cite: 2]
    try {
      final date = DateTime.parse(isoDate).toLocal(); //[cite: 2]
      return DateFormat('dd MMM yyyy, HH:mm').format(date); //[cite: 2]
    } catch (e) {
      return isoDate; //[cite: 2]
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ), //[cite: 2]
        title: const Text('Konfirmasi Logout'), //[cite: 2]
        content: const Text('Yakin ingin keluar dari akun ini?'), //[cite: 2]
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), //[cite: 2]
            child: const Text('Batal'), //[cite: 2]
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), //[cite: 2]
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent, //[cite: 2]
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8), //[cite: 2]
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ), //[cite: 2]
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      //[cite: 2]
      await Supabase.instance.client.auth.signOut(); //[cite: 2]
      if (context.mounted) {
        //[cite: 2]
        Navigator.pushAndRemoveUntil(
          context, //[cite: 2]
          MaterialPageRoute(builder: (_) => const LoginView()), //[cite: 2]
          (route) => false, //[cite: 2]
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg, //[cite: 2]
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween, //[cite: 1]
          children: [
            // --- BAGIAN KIRI: Judul & Tombol Testing Pengaturan ---
            Row(
              children: [
                const Text(
                  'Notifikasi', //[cite: 1]
                  style: TextStyle(fontWeight: FontWeight.bold), //[cite: 1]
                ),
                const SizedBox(width: 10), // Jarak spasi
                // Tombol akses ke Pengaturan Notifikasi
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PengaturanNotifikasiView(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.settings_suggest,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            // --- BAGIAN KANAN: Tombol Logout Asli ---
            GestureDetector(
              onTap: () => _logout(context), //[cite: 1]
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12, //[cite: 1]
                  vertical: 7, //[cite: 1]
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15), //[cite: 1]
                  borderRadius: BorderRadius.circular(20), //[cite: 1]
                  border: Border.all(color: Colors.white30), //[cite: 1]
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 15,
                    ), //[cite: 1]
                    SizedBox(width: 5), //[cite: 1]
                    Text(
                      'Logout', //[cite: 1]
                      style: TextStyle(
                        color: Colors.white, //[cite: 1]
                        fontSize: 12, //[cite: 1]
                        fontWeight: FontWeight.w600, //[cite: 1]
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _primary, //[cite: 1]
        foregroundColor: Colors.white, //[cite: 1]
        elevation: 0, //[cite: 1]
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _notifikasiStream, //[cite: 2]
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            //[cite: 2]
            return const Center(
              child: CircularProgressIndicator(color: _primary), //[cite: 2]
            );
          }

          if (snapshot.hasError) {
            //[cite: 2]
            return Center(child: Text('Error: ${snapshot.error}')); //[cite: 2]
          }

          final listNotifikasi = snapshot.data ?? []; //[cite: 2]

          if (listNotifikasi.isEmpty) {
            //[cite: 2]
            return _buildKosong(); //[cite: 2]
          }

          return ListView.separated(
            padding: const EdgeInsets.all(20), //[cite: 2]
            itemCount: listNotifikasi.length, //[cite: 2]
            separatorBuilder: (context, index) =>
                const SizedBox(height: 12), //[cite: 2]
            itemBuilder: (context, index) {
              //[cite: 2]
              final notif = listNotifikasi[index]; //[cite: 2]
              final isRead = notif['is_read'] ?? true; //[cite: 2]
              return _buildKartuNotifikasi(notif, isRead); //[cite: 2]
            },
          );
        },
      ),
    );
  }

  Widget _buildKartuNotifikasi(Map<String, dynamic> notif, bool isRead) {
    //[cite: 2]
    return Container(
      padding: const EdgeInsets.all(16), //[cite: 2]
      decoration: BoxDecoration(
        color: isRead
            ? Colors.white
            : const Color(0xFFE0F2FE).withOpacity(0.5), //[cite: 2]
        borderRadius: BorderRadius.circular(14), //[cite: 2]
        border: Border.all(
          color: isRead
              ? Colors.grey.shade200
              : _primary.withOpacity(0.3), //[cite: 2]
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03), //[cite: 2]
            blurRadius: 8, //[cite: 2]
            offset: const Offset(0, 2), //[cite: 2]
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start, //[cite: 2]
        children: [
          Container(
            padding: const EdgeInsets.all(10), //[cite: 2]
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1), //[cite: 2]
              shape: BoxShape.circle, //[cite: 2]
            ),
            child: const Icon(
              Icons.notifications_active_rounded, //[cite: 2]
              color: _primary, //[cite: 2]
              size: 24, //[cite: 2]
            ),
          ),
          const SizedBox(width: 16), //[cite: 2]
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start, //[cite: 2]
              children: [
                Text(
                  notif['judul'] ?? 'Informasi Baru', //[cite: 2]
                  style: const TextStyle(
                    fontWeight: FontWeight.bold, //[cite: 2]
                    fontSize: 14, //[cite: 2]
                    color: Color(0xFF1A1F36), //[cite: 2]
                  ),
                ),
                const SizedBox(height: 4), //[cite: 2]
                Text(
                  notif['pesan'] ?? '', //[cite: 2]
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                  ), //[cite: 2]
                ),
                const SizedBox(height: 8), //[cite: 2]
                Text(
                  _formatTanggal(notif['created_at']), //[cite: 2]
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                  ), //[cite: 2]
                ),
              ],
            ),
          ),
          if (!isRead) //[cite: 2]
            const Padding(
              padding: EdgeInsets.only(top: 6), //[cite: 2]
              child: CircleAvatar(
                radius: 4,
                backgroundColor: Colors.redAccent,
              ), //[cite: 2]
            ),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    //[cite: 2]
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), //[cite: 2]
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7, //[cite: 2]
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, //[cite: 2]
            children: [
              Icon(
                Icons.notifications_off_rounded, //[cite: 2]
                size: 80, //[cite: 2]
                color: Colors.grey.shade300, //[cite: 2]
              ),
              const SizedBox(height: 16), //[cite: 2]
              const Text(
                'Belum ada notifikasi', //[cite: 2]
                style: TextStyle(
                  fontSize: 16, //[cite: 2]
                  fontWeight: FontWeight.bold, //[cite: 2]
                  color: Colors.grey, //[cite: 2]
                ),
              ),
              const SizedBox(height: 8), //[cite: 2]
              Text(
                'Notifikasi tugas atau materi baru\nakan muncul di sini.', //[cite: 2]
                textAlign: TextAlign.center, //[cite: 2]
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                ), //[cite: 2]
              ),
            ],
          ),
        ),
      ),
    );
  }
}
