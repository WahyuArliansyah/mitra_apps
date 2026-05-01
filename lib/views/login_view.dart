import 'package:flutter/material.dart';
import 'package:mitra_apps/views/admin_dashboard_view.dart';
import 'package:mitra_apps/views/guru_dashboard_view.dart';
import 'package:mitra_apps/views/siswa_dashboard_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  // Controller untuk mengambil teks yang diketik pengguna
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  // Fungsi untuk memproses login berdasarkan role pengguna
  Future<void> _prosesLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final inputText = _emailController.text.trim();
      final password = _passwordController.text.trim();

      // Logika pengecekan role
      String emailLogin = inputText;

      // Jika input tidak menggunakan @ maka otomatis ditambahkan @mitra.com
      if (!inputText.contains('@')) {
        emailLogin = '$inputText@mitra.com';
      }

      // Memanggil fungsi login bawaan Supabase
      final AuthResponse res = await Supabase.instance.client.auth
          .signInWithPassword(email: emailLogin, password: password);

      // Login sesuai dengan role
      if (res.session != null) {
        final userId = res.session!.user.id;

        // Autentikasi data role yang login
        final userData = await Supabase.instance.client
            .from('pengguna')
            .select('peran')
            .eq('id', userId)
            .maybeSingle(); //maybeSingle() agar tidak error/crash jika data tidak ditemukan

        if (userData == null) {
          if (mounted) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.orange, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Profil Tidak Ditemukan',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Akun Anda belum terdaftar di data profil sistem. Hubungi Administrator.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Supabase.instance.client.auth.signOut();
                      Navigator.of(context).pop();
                    },
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }
          return;
        }

        final peran = userData['peran'];

        // Login sesuai dengan rolenya
        if (mounted) {
          if (peran == 'admin') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboardView(),
              ),
            );
          } else if (peran == 'guru') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const GuruDashboardView(),
              ),
            );
          } else if (peran == 'siswa') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const SiswaDashboardView(),
              ),
            );
          } else {
            // Jika rolenya tidak valid muncul alert tidak memiliki akses
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Akses Ditolak'),
                content: const Text(
                  'Akun Anda tidak memiliki hak akses yang valid.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }
        }
      }
    } on AuthException catch (e) {
      // Jika password/email salah muncul alert dialog
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red,
                    size: 28,
                  ), // Ikon peringatan
                  SizedBox(width: 8),
                  Text(
                    'Login Gagal',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Text(
                'NISN/NUPTK atau Password yang Anda masukkan salah. Silakan periksa kembali.',
                style: TextStyle(fontSize: 16),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).pop(); // Menutup Pop-up Alert saat diklik
                  },
                  child: const Text(
                    'Tutup',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blueAccent,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      // Jika terjadi error lain seperti masalah jaringan atau server
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Logo atau Icon Aplikasi
                const Icon(
                  Icons.school_rounded,
                  size: 100,
                  color: Colors.blueAccent,
                ),
                const SizedBox(height: 24),

                // Judul
                const Text(
                  'E-Learning\nMitra Permata',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 40),

                // Form Email
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'NISN/NUPTK',
                    prefixIcon: const Icon(Icons.person_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Form Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Login
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _prosesLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'MASUK',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
