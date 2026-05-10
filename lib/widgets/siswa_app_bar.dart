import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/ubah_password_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/views/pengaturan_notifikasi_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String namaSiswa;
  final List<Widget>? extraActions;

  static const _primary = Color(0xFF0EA5E9);

  const SiswaAppBar({super.key, required this.namaSiswa, this.extraActions});

  /// Mengambil inisial nama secara otomatis (1 atau 2 huruf)
  String _getInitials(String name) {
    if (name.isEmpty) return "S";
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (ok == true && context.mounted) {
      // Hapus FCM token sebelum logout
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client
            .from('pengguna')
            .update({'fcm_token': null})
            .eq('id', user.id);
      }

      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 80,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: Row(
              children: [
                // 1. Logo Aplikasi Bulat di Kiri
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo_login.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.school, color: _primary, size: 24),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Nama Siswa di Tengah
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Hello,',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                      Text(
                        namaSiswa,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Extra actions (opsional)
                if (extraActions != null) ...extraActions!,
                const SizedBox(width: 8),

                // 3. Popup Menu Button (Badge Inisial Nama) di Kanan
                Theme(
                  data: Theme.of(context).copyWith(
                    splashColor: Colors.transparent,
                    highlightColor: Colors.transparent,
                  ),
                  child: PopupMenuButton<String>(
                    offset: const Offset(0, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    color: Colors.white,
                    tooltip: 'Profil & Pengaturan',
                    onSelected: (String value) {
                      if (value == 'notifikasi') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PengaturanNotifikasiView(),
                          ),
                        );
                      } else if (value == 'ubah_password') {
                        showDialog(
                          context: context,
                          builder: (context) => const UbahPasswordView(),
                        );
                      } else if (value == 'logout') {
                        _logout(context);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      // Menu 1: Pengaturan Notifikasi
                      const PopupMenuItem<String>(
                        value: 'notifikasi',
                        child: Row(
                          children: [
                            Icon(
                              Icons.notifications_outlined,
                              color: _primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Pengaturan Notifikasi',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),

                      // Menu 2: Ganti Password
                      const PopupMenuItem<String>(
                        value: 'ubah_password',
                        child: Row(
                          children: [
                            Icon(
                              Icons.vpn_key_outlined,
                              color: _primary,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Ganti Password',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const PopupMenuDivider(),

                      // Menu 3: Logout
                      const PopupMenuItem<String>(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(
                              Icons.logout_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Logout',
                              style: TextStyle(
                                color: Colors.redAccent,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    // Widget yang terlihat (Badge Inisial Nama)
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.white,
                        child: Text(
                          _getInitials(namaSiswa),
                          style: const TextStyle(
                            color: _primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
