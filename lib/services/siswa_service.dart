import 'package:mitra_apps/models/siswa_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SiswaService {
  final supabase = Supabase.instance.client;

  // READ: Ambil semua data siswa
  Future<List<SiswaModel>> getSemuaSiswa() async {
    try {
      final response = await supabase
          .from('siswa')
          .select()
          .order('nama_siswa', ascending: true);
      return (response as List)
          .map((data) => SiswaModel.fromJson(data))
          .toList();
    } catch (e) {
      print('Error Get: $e');
      return [];
    }
  }

  // READ: Ambil siswa berdasarkan kelas
  Future<List<SiswaModel>> getSiswaByKelas(String idKelas) async {
    try {
      final response = await supabase
          .from('siswa')
          .select()
          .eq('id_kelas', idKelas)
          .order('nama_siswa', ascending: true);
      return (response as List)
          .map((data) => SiswaModel.fromJson(data))
          .toList();
    } catch (e) {
      print('Error Get By Kelas: $e');
      return [];
    }
  }

  // Tambah Data Siswa
  Future<bool> tambahSiswa(SiswaModel siswa) async {
    try {
      final String emailLogin = '${siswa.nis}@mitra.com';

      // Simpan session admin sebelum signUp
      final accessToken = supabase.auth.currentSession?.accessToken;
      final refreshToken = supabase.auth.currentSession?.refreshToken;

      // Daftarkan ke Supabase Auth
      final AuthResponse res = await supabase.auth.signUp(
        email: emailLogin,
        password: siswa.nis!,
        data: {'nama_lengkap': siswa.namaSiswa},
      );

      if (res.user != null) {
        final String uidBaru = res.user!.id;

        await Future.delayed(const Duration(milliseconds: 500));
        try {
          // 1. Hash password
          final hashedPassword = await supabase.rpc(
            'hash_password',
            params: {'plain_password': siswa.nis!},
          );
          print('Hash berhasil: $hashedPassword');

          // 2. Update pengguna yang sudah dibuat trigger (bukan insert!)
          await supabase
              .from('pengguna')
              .update({
                'nim_nuptk': siswa.nis,
                'kata_sandi': hashedPassword,
                'peran': 'siswa',
              })
              .eq('id', uidBaru);
          print('Update pengguna berhasil');

          // 3. Insert ke tabel siswa
          await supabase.from('siswa').insert({
            'id_siswa': uidBaru,
            'nis': siswa.nis,
            'nama_siswa': siswa.namaSiswa,
            if (siswa.idKelas != null) 'id_kelas': siswa.idKelas,
          });
          print('Insert siswa berhasil');
        } catch (e) {
          print('Error step insert/hash: $e');
        }
        try {
          if (accessToken != null && refreshToken != null) {
            await supabase.auth.setSession(refreshToken);
          }
        } catch (e) {
          print('Restore session error: $e');
          // Fallback: tidak perlu panic, admin akan redirect ke login
        }
        return true;
      }
      return false;
    } catch (e) {
      print('Error Detail: $e');
      return false;
    }
  }

  // Update data siswa
  Future<bool> updateSiswa(String idSiswa, Map<String, dynamic> data) async {
    try {
      // Update tabel siswa
      await supabase.from('siswa').update(data).eq('id_siswa', idSiswa);

      // Jika NIS berubah
      if (data.containsKey('nis')) {
        final nis = data['nis'];

        // Hash password baru
        final hashedPassword = await supabase.rpc(
          'hash_password',
          params: {'plain_password': nis},
        );

        // Update tabel pengguna
        await supabase
            .from('pengguna')
            .update({'nim_nuptk': nis, 'kata_sandi': hashedPassword})
            .eq('id', idSiswa);

        // Update email di auth.users via RPC
        await supabase.rpc(
          'update_auth_email',
          params: {'uid': idSiswa, 'new_email': '$nis@mitra.com'},
        );
      }

      return true;
    } catch (e) {
      print('Error Update Siswa: $e');
      return false;
    }
  }

  // Hapus Data Siswa
  Future<bool> hapusSiswa(String idSiswa) async {
    try {
      // 1. Hapus dari tabel siswa
      await supabase.from('siswa').delete().eq('id_siswa', idSiswa);

      // 2. Hapus dari tabel pengguna
      await supabase.from('pengguna').delete().eq('id', idSiswa);

      // 3. Hapus dari auth.users via RPC (sama seperti guru)
      await supabase.rpc('hapus_auth_user', params: {'uid': idSiswa});

      return true;
    } catch (e) {
      print('Error Hapus Siswa: $e');
      return false;
    }
  }

  // Validasi agar tidak ada data ganda
  Future<String?> cekDataDuplikat(String nis, String namaSiswa) async {
    try {
      if (nis.isNotEmpty) {
        final cekNis = await supabase
            .from('siswa')
            .select('id_siswa')
            .eq('nis', nis);
        if (cekNis.isNotEmpty) return 'NIS';
      }
      return null;
    } catch (e) {
      return 'Sistem';
    }
  }

  // Ganti Password Siswa
  Future<bool> gantiPassword(String passwordBaru) async {
    try {
      // 1. Update password di Supabase Auth (user yang sedang login)
      await supabase.auth.updateUser(UserAttributes(password: passwordBaru));

      // 2. Hash password baru
      final hashedPassword = await supabase.rpc(
        'hash_password',
        params: {'plain_password': passwordBaru},
      );

      // 3. Update kata_sandi di tabel pengguna
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

  // Reset Password Siswa (admin)
  Future<bool> resetPasswordSiswa(String idSiswa, String nis) async {
    try {
      // 1. Hash password (NIS sebagai password default)
      final hashedPassword = await supabase.rpc(
        'hash_password',
        params: {'plain_password': nis},
      );

      // 2. Update kata_sandi di tabel pengguna
      await supabase
          .from('pengguna')
          .update({'kata_sandi': hashedPassword})
          .eq('id', idSiswa);

      // 3. Reset password di auth.users via RPC
      await supabase.rpc(
        'reset_user_password',
        params: {'uid': idSiswa, 'new_password': nis},
      );

      return true;
    } catch (e) {
      print('Error Reset Password Siswa: $e');
      return false;
    }
  }
}
