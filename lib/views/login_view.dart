import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mitra_apps/views/admin/admin_dashboard_view.dart';
import 'package:mitra_apps/widgets/custom_main_nav.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AppColors {
  static const Color navy = Color(0xFF0F2D5C);
  static const Color navyMid = Color(0xFF1A4080);
  static const Color accent = Color(0xFF3B82F6);
  static const Color white = Colors.white;
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color border = Color(0xFFE2E8F0);
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  Future<void> _updateFCMToken(String idPengguna, String role) async {
    if (role != 'siswa') return;
    final supabase = Supabase.instance.client;
    await Future.delayed(const Duration(seconds: 2));
    try {
      String? fcmToken = await FirebaseMessaging.instance.getToken();
      NotificationSettings settings = await FirebaseMessaging.instance
          .requestPermission();

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        String? fcmToken = await FirebaseMessaging.instance.getToken();
        if (fcmToken != null) {
          await supabase
              .from('pengguna')
              .update({'fcm_token': fcmToken})
              .eq('id', idPengguna);
          debugPrint('FCM Token Siswa berhasil diupdate: $fcmToken');
        }
      } else {
        debugPrint('Siswa menolak izin notifikasi');
      }
    } catch (e) {
      debugPrint("Error FCM Xiaomi: $e");
    }
  }

  // Logic login
  Future<void> _prosesLogin() async {
    setState(() => _isLoading = true);

    try {
      final inputText = _emailController.text.trim();
      final password = _passwordController.text.trim();

      String emailLogin = inputText;
      if (!inputText.contains('@')) {
        emailLogin = '$inputText@mitra.com';
      }

      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: emailLogin, password: password);

      if (res.session != null) {
        final userId = res.session!.user.id;

        final userData = await Supabase.instance.client
            .from('pengguna')
            .select('peran')
            .eq('id', userId)
            .maybeSingle();

        if (userData == null) {
          if (mounted) {
            _showErrorDialog(
              icon: Icons.error_outline,
              iconColor: Colors.orange,
              title: 'Profil Tidak Ditemukan',
              message:
                  'Akun Anda belum terdaftar di data profil sistem. Hubungi Administrator.',
            );
          }
          return;
        }

        final peran = userData['peran'];
        await _updateFCMToken(userId, peran);

        if (mounted) {
          if (peran == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CustomMainNav(userId: userId, role: 'admin'),
              ),
            );
          } else if (peran == 'guru') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CustomMainNav(userId: userId, role: 'guru'),
              ),
            );
          } else if (peran == 'siswa') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CustomMainNav(userId: userId, role: 'siswa'),
              ),
            );
          } else {
            _showErrorDialog(
              icon: Icons.lock_outline,
              iconColor: Colors.red,
              title: 'Akses Ditolak',
              message: 'Akun Anda tidak memiliki hak akses yang valid.',
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorDialog(
          icon: Icons.warning_amber_rounded,
          iconColor: Colors.red,
          title: 'Login Gagal',
          message:
              'NIS/NIP atau Password yang Anda masukkan salah. Silakan periksa kembali.',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showErrorDialog({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String message,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Text(message, style: const TextStyle(fontSize: 15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Tutup',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: AppColors.navy,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeroSection(),
                _buildLoginForm(),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.navyMid, AppColors.accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Image.asset(
              'assets/images/logo_login.png',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 24),

          // Welcome Text
          const Text(
            'MitraTaskly',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Transform.translate(
      offset: const Offset(0, -30),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title Section
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Selamat Datang',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan masuk dengan akun Anda',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              _buildModernTextField(
                controller: _emailController,
                label: 'NIS / NIP',
                hint: 'Contoh: 12345678',
                icon: Icons.school_outlined,
                isFocused: _emailFocused,
                onFocusChange: (focused) =>
                    setState(() => _emailFocused = focused),
              ),
              const SizedBox(height: 20),

              _buildModernPasswordField(),
              const SizedBox(height: 32),

              _buildLoginButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isFocused,
    required Function(bool) onFocusChange,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        onTap: () => onFocusChange(true),
        onEditingComplete: () => onFocusChange(false),
        onTapOutside: (_) => onFocusChange(false),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontWeight: FontWeight.normal,
          ),
          labelStyle: TextStyle(
            color: isFocused ? AppColors.accent : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: isFocused ? AppColors.accent : AppColors.textSecondary,
              size: 22,
            ),
          ),
          filled: true,
          fillColor: isFocused
              ? AppColors.accent.withOpacity(0.04)
              : AppColors.lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildModernPasswordField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: _passwordFocused
            ? [
                BoxShadow(
                  color: AppColors.accent.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        onTap: () => setState(() => _passwordFocused = true),
        onEditingComplete: () => setState(() => _passwordFocused = false),
        onTapOutside: (_) => setState(() => _passwordFocused = false),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppColors.navy,
        ),
        decoration: InputDecoration(
          labelText: 'Password',
          hintText: 'Masukkan password',
          hintStyle: TextStyle(
            color: AppColors.textSecondary.withOpacity(0.6),
            fontWeight: FontWeight.normal,
          ),
          labelStyle: TextStyle(
            color: _passwordFocused
                ? AppColors.accent
                : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            child: Icon(
              Icons.lock_outline,
              color: _passwordFocused
                  ? AppColors.accent
                  : AppColors.textSecondary,
              size: 22,
            ),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: _passwordFocused
                  ? AppColors.accent
                  : AppColors.textSecondary,
            ),
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
          ),
          filled: true,
          fillColor: _passwordFocused
              ? AppColors.accent.withOpacity(0.04)
              : AppColors.lightBackground,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.border, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.accent, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 18,
            horizontal: 16,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.navy, AppColors.accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isLoading ? null : _prosesLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'MASUK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.only(top: 40, bottom: 24),
      child: Column(
        children: [
          Text(
            '© 2026 SMK Mitra Permata',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'versi 1.0.0',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}
