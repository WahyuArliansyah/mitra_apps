import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/ubah_password_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/views/pengaturan_notifikasi_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String namaSiswa;
  final String namaKelas;
  final bool compact;
  final List<Widget>? extraActions;

  static const _navyDark = Color(0xFF1A3FA8);

  const SiswaAppBar({
    super.key,
    required this.namaSiswa,
    this.namaKelas = '',
    this.compact = false,
    this.extraActions,
  });

  String _getInitials(String name) {
    if (name.isEmpty) return 'S';
    final words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) return words[0][0].toUpperCase();
    return (words[0][0] + words[1][0]).toUpperCase();
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
  Size get preferredSize => const Size.fromHeight(170);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: 170,
      elevation: 0,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F2D5C), // navy
              Color(0xFF4F46E5), // ungu
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Logo
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(3),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(7),
                        child: Image.asset(
                          'assets/images/logo_login.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.school,
                            color: _navyDark,
                            size: 20,
                          ),
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        if (extraActions != null) ...extraActions!,
                        const SizedBox(width: 8),
                        // Avatar popup menu
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
                            onSelected: (value) {
                              if (value == 'notifikasi') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        const PengaturanNotifikasiView(),
                                  ),
                                );
                              } else if (value == 'ubah_password') {
                                showDialog(
                                  context: context,
                                  builder: (_) => const UbahPasswordView(),
                                );
                              } else if (value == 'logout') {
                                _logout(context);
                              }
                            },
                            itemBuilder: (_) => [
                              const PopupMenuItem<String>(
                                value: 'notifikasi',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.notifications_outlined,
                                      color: _navyDark,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Pengaturan Notifikasi',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'ubah_password',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.vpn_key_outlined,
                                      color: _navyDark,
                                      size: 20,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      'Ganti Password',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const PopupMenuDivider(),
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
                            child: Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1.5,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(namaSiswa),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Selamat datang kembali',
                  style: TextStyle(color: Colors.white60, fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  namaSiswa,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (namaKelas.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$namaKelas · SMK Mitra Permata',
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
