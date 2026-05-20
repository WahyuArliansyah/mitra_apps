import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitra_apps/views/guru/ubah_password_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruAppBar extends StatelessWidget {
  final String namaGuru;
  final List<Widget>? extraActions;

  // ─── Design Tokens (sama persis dengan GuruDashboardView) ─────────────────
  static const _navy = Color(0xFF0F2D5C);
  static const _navyMid = Color(0xFF1A4080);
  static const _accent = Color(0xFF3B82F6);
  static const _white = Colors.white;

  const GuruAppBar({super.key, required this.namaGuru, this.extraActions});

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 11) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
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
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _navy,
      elevation: 0,
      automaticallyImplyLeading: false,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      flexibleSpace: FlexibleSpaceBar(
        background: _buildHeaderBackground(context),
        collapseMode: CollapseMode.pin,
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(
          height: 24,
          decoration: const BoxDecoration(
            color: Color(0xFFF0F4FA),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderBackground(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_navy, _navyMid, Color(0xFF2563EB)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // ── Decorative circles ──────────────────────────────────────────
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _white.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            top: 40,
            right: 60,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: 30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _white.withOpacity(0.04),
              ),
            ),
          ),

          // ── Content ─────────────────────────────────────────────────────
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF60A5FA), Color(0xFF3B82F6)],
                      ),
                      border: Border.all(
                        color: _white.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _navy.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitials(namaGuru),
                        style: const TextStyle(
                          color: _white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Greeting + nama + role badge
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _getGreeting(),
                          style: TextStyle(
                            color: _white.withOpacity(0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          namaGuru,
                          style: const TextStyle(
                            color: _white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: _white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _white.withOpacity(0.2)),
                          ),
                          child: const Text(
                            'Guru',
                            style: TextStyle(
                              color: _white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Extra actions (opsional)
                  if (extraActions != null) ...extraActions!,

                  // Popup menu (ubah password & logout) dikemas dalam bell-style button
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
                        if (value == 'ubah_password') {
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
                          value: 'ubah_password',
                          child: Row(
                            children: [
                              Icon(
                                Icons.vpn_key_outlined,
                                color: _accent,
                                size: 20,
                              ),
                              SizedBox(width: 12),
                              Text(
                                'Ubah Kata Sandi',
                                style: TextStyle(fontWeight: FontWeight.w500),
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
                      // Tombol berbentuk kotak mirip notification bell di dashboard
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _white.withOpacity(0.2)),
                        ),
                        child: const Icon(
                          Icons.more_vert_rounded,
                          color: _white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
