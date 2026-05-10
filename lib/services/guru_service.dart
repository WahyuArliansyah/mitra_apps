import 'package:mitra_apps/models/guru_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruService {
  final supabase = Supabase.instance.client;

  // READ: Ambil semua data guru
  Future<List<GuruModel>> getSemuaGuru() async {
    try {
      final response = await supabase
          .from('guru')
          .select()
          .order('nama_lengkap', ascending: true);
      return (response as List)
          .map((data) => GuruModel.fromJson(data))
          .toList();
    } catch (e) {
      print('Error Get: $e');
      return [];
    }
  }

  // Tambah Data Guru
  Future<bool> tambahGuru(GuruModel guru) async {
    try {
      final String emailLogin = '${guru.nip}@mitra.com';

      // Simpan access token & refresh token admin sebelum signUp
      final accessToken = supabase.auth.currentSession?.accessToken;
      final refreshToken = supabase.auth.currentSession?.refreshToken;

      // 1. Daftarkan ke Supabase Auth
      final AuthResponse res = await supabase.auth.signUp(
        email: emailLogin,
        password: guru.nip!,
        data: {'nama_lengkap': guru.namaLengkap},
      );

      if (res.user != null) {
        final String uidBaru = res.user!.id;

        await Future.delayed(const Duration(milliseconds: 500));

        try {
          // Hash password via RPC
          final hashedPassword = await supabase.rpc(
            'hash_password',
            params: {'plain_password': guru.nip!},
          );

          // Insert ke tabel guru
          await Future.wait([
            // Hash & update pengguna
            supabase
                .rpc('hash_password', params: {'plain_password': guru.nip!})
                .then(
                  (hashedPassword) => supabase
                      .from('pengguna')
                      .update({'kata_sandi': hashedPassword})
                      .eq('id', uidBaru),
                ),

            supabase.from('guru').insert({
              'id_guru': uidBaru,
              'user_id': uidBaru,
              'nip': guru.nip,
              'nama_lengkap': guru.namaLengkap,
              'email': guru.email,
            }),
            supabase
                .from('pengguna')
                .update({'nim_nuptk': guru.nip, 'peran': 'guru'})
                .eq('id', uidBaru),
          ]);
        } catch (e) {
          print('Error step insert/hash: $e');
        }

        // Restore session admin dengan setSession langsung
        if (accessToken != null && refreshToken != null) {
          await supabase.auth.setSession(refreshToken);
        }

        return true;
      }
      return false;
    } catch (e) {
      print('Error Detail: $e');
      return false;
    }
  }

  // Update data guru
  Future<bool> updateGuru(String id, Map<String, dynamic> data) async {
    try {
      // 1. Update tabel guru
      await supabase.from('guru').update(data).eq('id_guru', id);

      // 2. Jika NIP berubah
      if (data.containsKey('nip')) {
        final nip = data['nip'];

        // Hash password baru
        final hashedPassword = await supabase.rpc(
          'hash_password',
          params: {'plain_password': nip},
        );

        // Update tabel pengguna
        await supabase
            .from('pengguna')
            .update({'nim_nuptk': nip, 'kata_sandi': hashedPassword})
            .eq('id', id);

        // Update email di auth.users via RPC
        await supabase.rpc(
          'update_auth_email',
          params: {'uid': id, 'new_email': '$nip@mitra.com'},
        );
      }

      return true;
    } catch (e) {
      print('Error Update Guru: $e');
      return false;
    }
  }

  // Delete Data Guru
  Future<bool> hapusGuru(String idGuru) async {
    try {
      // 1. Ambil user_id dulu sebelum dihapus
      final data = await supabase
          .from('guru')
          .select('user_id')
          .eq('id_guru', idGuru)
          .single();

      final userId = data['user_id'];

      // 2. Hapus dari tabel guru
      await Future.wait([
        supabase.from('guru').delete().eq('id_guru', idGuru),
        if (userId != null) supabase.from('pengguna').delete().eq('id', userId),
      ]);

      // 3. Hapus dari tabel pengguna
      if (userId != null) {
        await supabase.from('pengguna').delete().eq('id', userId);

        // 4. Hapus dari Supabase Auth
        await supabase.rpc('hapus_auth_user', params: {'uid': userId});
      }

      return true;
    } catch (e) {
      print('Error Delete: $e');
      return false;
    }
  }

  // Validasi agar tidak ada data ganda
  Future<String?> cekDataDuplikat(String nip, String nama, String email) async {
    try {
      final cekEmail = await supabase
          .from('guru')
          .select('id_guru')
          .eq('email', email);
      if (cekEmail.isNotEmpty) return 'Email';

      if (nip.isNotEmpty) {
        final cekNip = await supabase
            .from('guru')
            .select('id_guru')
            .eq('nip', nip);
        if (cekNip.isNotEmpty) return 'NIP';
      }
      return null;
    } catch (e) {
      return 'Sistem';
    }
  }

  // Ganti Password Guru (untuk guru yang sudah login)
  Future<bool> gantiPassword(String passwordBaru) async {
    try {
      // 1. Update password di Supabase Auth (user yang sedang login)
      await supabase.auth.updateUser(UserAttributes(password: passwordBaru));

      // 2. Hash password baru
      final hashedPassword = await supabase.rpc(
        'hash_password',
        params: {'plain_password': passwordBaru},
      );

      // Update kata_sandi di tabel pengguna
      final user = supabase.auth.currentUser;
      if (user != null) {
        await supabase
            .from('pengguna')
            .update({'kata_sandi': hashedPassword})
            .eq('id', user.id);
      }

      return true;
    } catch (e) {
      print('Error Ganti Password: $e');
      return false;
    }
  }

  // Reset Password Guru (admin yang melakukan reset untuk guru lain)
  Future<bool> resetPasswordGuru(String idGuru, String nip) async {
    try {
      // 1. Hash password (NIP sebagai password default)
      final hashedPassword = await supabase.rpc(
        'hash_password',
        params: {'plain_password': nip},
      );

      // 2. Update kata_sandi di tabel pengguna
      await supabase
          .from('pengguna')
          .update({'kata_sandi': hashedPassword})
          .eq('id', idGuru);

      // 3. Reset password di auth.users via RPC
      await supabase.rpc(
        'reset_user_password',
        params: {'uid': idGuru, 'new_password': nip},
      );

      return true;
    } catch (e) {
      print('Error Reset Password Guru: $e');
      return false;
    }
  }
}
