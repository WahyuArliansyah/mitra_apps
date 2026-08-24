import 'package:flutter/material.dart';
import 'package:mitra_apps/views/admin/admin_dashboard_view.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:mitra_apps/widgets/custom_main_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplashScreenView extends StatefulWidget {
  final bool isLoggedIn;
  const SplashScreenView({super.key, required this.isLoggedIn});

  @override
  State<SplashScreenView> createState() => _SplashScreenViewState();
}

class _SplashScreenViewState extends State<SplashScreenView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnim = Tween<double>(begin: 0.75, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _slideAnim = Tween<double>(begin: 30, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Navigasi ke LoginView setelah 3 detik
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return;

      final session = Supabase.instance.client.auth.currentSession;

      Widget destination = const LoginView();

      if (session != null) {
        try {
          // Ambil peran dari tabel pengguna
          final data = await Supabase.instance.client
              .from('pengguna')
              .select('peran')
              .eq('id', session.user.id)
              .maybeSingle();

          final peran = data?['peran'] ?? '';

          if (peran == 'admin') {
            destination = const AdminDashboardView();
          } else if (peran == 'guru') {
            destination = CustomMainNav(userId: session.user.id, role: 'guru');
          } else if (peran == 'siswa') {
            destination = CustomMainNav(userId: session.user.id, role: 'siswa');
          }
        } catch (e) {
          destination = const LoginView();
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => destination,
          transitionDuration: const Duration(milliseconds: 800),
          reverseTransitionDuration: const Duration(milliseconds: 800),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            final slideTween =
                Tween<Offset>(
                  begin: const Offset(0, 1.0),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                );

            final fadeTween = Tween<double>(
              begin: 0.0,
              end: 1.0,
            ).animate(CurvedAnimation(parent: animation, curve: Curves.easeIn));

            return FadeTransition(
              opacity: fadeTween,
              child: SlideTransition(position: slideTween, child: child),
            );
          },
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A3A8F), Color(0xFF2B5CE6)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (_, __) => FadeTransition(
                      opacity: _fadeAnim,
                      child: Transform.scale(
                        scale: _scaleAnim.value,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo
                            Container(
                              height: 120,
                              width: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.rectangle,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(12),
                              child: Image.asset(
                                'assets/images/logo_splashscreen.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Tagline muncul dengan slide up
                            Transform.translate(
                              offset: Offset(0, _slideAnim.value),
                              child: const Text(
                                'TUGAS TERKELOLA, NILAI TERPANTAU',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 1.8,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Loading Indicator + Footer ─────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => FadeTransition(
                  opacity: _fadeAnim,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            color: const Color(0xFFF97316),
                            strokeWidth: 3,
                            backgroundColor: Colors.white.withOpacity(0.2),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          '© 2026 SMK Mitra Permata',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.45),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
