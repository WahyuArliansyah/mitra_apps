import 'package:flutter/material.dart';
import 'package:mitra_apps/views/guru/ubah_password_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruAppBar extends StatelessWidget {
  final String namaGuru; //[cite: 4]
  final List<Widget>? extraActions; //[cite: 4]

  static const _primary = Color(0xFF0EA5E9); //[cite: 4]

  const GuruAppBar({
    super.key,
    required this.namaGuru,
    this.extraActions,
  }); //[cite: 4]

  // Fungsi cerdas untuk mengambil inisial nama secara otomatis
  String _getInitials(String name) {
    if (name.isEmpty) return "G";
    List<String> words = name.trim().split(RegExp(r'\s+'));
    if (words.length == 1) {
      return words[0][0].toUpperCase();
    } else {
      return (words[0][0] + words[1][0]).toUpperCase();
    }
  }

  Future<void> _logout(BuildContext context) async {
    //[cite: 4]
    final ok = await showDialog<bool>(
      //[cite: 4]
      context: context, //[cite: 4]
      builder: (ctx) => AlertDialog(
        //[cite: 4]
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ), //[cite: 4]
        title: const Text('Konfirmasi Logout'), //[cite: 4]
        content: const Text('Yakin ingin keluar dari akun ini?'), //[cite: 4]
        actions: [
          TextButton(
            //[cite: 4]
            onPressed: () => Navigator.pop(ctx, false), //[cite: 4]
            child: const Text('Batal'), //[cite: 4]
          ),
          ElevatedButton(
            //[cite: 4]
            onPressed: () => Navigator.pop(ctx, true), //[cite: 4]
            style: ElevatedButton.styleFrom(
              //[cite: 4]
              backgroundColor: Colors.redAccent, //[cite: 4]
              shape: RoundedRectangleBorder(
                //[cite: 4]
                borderRadius: BorderRadius.circular(8), //[cite: 4]
              ),
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ), //[cite: 4]
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      //[cite: 4]
      await Supabase.instance.client.auth.signOut(); //[cite: 4]
      if (context.mounted) {
        //[cite: 4]
        Navigator.pushAndRemoveUntil(
          //[cite: 4]
          context, //[cite: 4]
          MaterialPageRoute(builder: (_) => const LoginView()), //[cite: 4]
          (route) => false, //[cite: 4]
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      //[cite: 4]
      expandedHeight: 110,
      floating: false,
      pinned: true,
      backgroundColor: _primary,
      automaticallyImplyLeading: false,
      elevation: 0, //[cite: 4]
      flexibleSpace: FlexibleSpaceBar(
        //[cite: 4]
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              //[cite: 4]
              colors: [Color(0xFF38BDF8), Color(0xFF0284C7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            //[cite: 4]
            child: Padding(
              //[cite: 4]
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20), //[cite: 4]
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end, //[cite: 4]
                children: [
                  Row(
                    //[cite: 4]
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
                                const Icon(
                                  Icons.school,
                                  color: _primary,
                                  size: 24,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        //[cite: 4]
                        child: Column(
                          //[cite: 4]
                          crossAxisAlignment:
                              CrossAxisAlignment.start, //[cite: 4]
                          children: [
                            const Text(
                              'Hello,',
                              style: TextStyle(
                                color: Colors.white70, //[cite: 4]
                                fontSize: 12, //[cite: 4]
                              ),
                            ),
                            Text(
                              namaGuru, //[cite: 4]
                              style: const TextStyle(
                                //[cite: 4]
                                color: Colors.white, //[cite: 4]
                                fontSize: 16, //[cite: 4]
                                fontWeight: FontWeight.bold, //[cite: 4]
                              ),
                              overflow: TextOverflow.ellipsis, //[cite: 4]
                            ),
                          ],
                        ),
                      ),

                      // Extra actions (opsional) bawaan dari code sebelumnya
                      if (extraActions != null) ...extraActions!, //[cite: 4]
                      const SizedBox(width: 8), //[cite: 4]
                      // 3. Popup Menu Button (Dropdown Inisial Nama) di Kanan
                      Theme(
                        // Menghilangkan efek ripple kotak bawaan saat diklik
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
                            if (value == 'ubah_password') {
                              showDialog(
                                context: context,
                                builder: (context) => const UbahPasswordView(),
                              );
                            } else if (value == 'logout') {
                              _logout(context);
                            }
                          },
                          itemBuilder: (BuildContext context) => [
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
                                    'Ubah Kata Sandi',
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
                          // Widget yang terlihat (Badge Profil)
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
                                _getInitials(namaGuru),
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
