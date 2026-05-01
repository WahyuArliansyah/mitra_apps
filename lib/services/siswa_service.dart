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

      // 1. Daftarkan ke Supabase Auth (email = nis@mitra.com, password = nis)
      final AuthResponse res = await supabase.auth.signUp(
        email: emailLogin,
        password: siswa.nis!,
        data: {'nama_siswa': siswa.namaSiswa},
      );

      if (res.user != null) {
        final String uidBaru = res.user!.id;

        await Future.delayed(const Duration(milliseconds: 500));

        try {
          // 2. Hash password via RPC
          final hashedPassword = await supabase.rpc(
            'hash_password',
            params: {'plain_password': siswa.nis!},
          );

          // 3. Insert ke tabel siswa
          await supabase.from('siswa').insert({
            'id_siswa': uidBaru,
            'nis': siswa.nis,
            'nama_siswa': siswa.namaSiswa,
            if (siswa.idKelas != null) 'id_kelas': siswa.idKelas,
          });

          // 4. Update kata_sandi di tabel pengguna
          await supabase
              .from('pengguna')
              .update({'kata_sandi': hashedPassword})
              .eq('id', uidBaru);
        } catch (e) {
          print('Error step insert/hash: $e');
        }

        // Restore session admin
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

  // Update data siswa
  Future<bool> updateSiswa(String id, Map<String, dynamic> data) async {
    try {
      await supabase.from('siswa').update(data).eq('id_siswa', id);
      return true;
    } catch (e) {
      print('Error Update: $e');
      return false;
    }
  }

  // Hapus Data Siswa
  Future<bool> hapusSiswa(String idSiswa) async {
    try {
      // 1. Ambil uid dari auth (id_siswa = uid di auth)
      final data = await supabase
          .from('siswa')
          .select('id_siswa')
          .eq('id_siswa', idSiswa)
          .single();

      final userId = data['id_siswa'];

      // 2. Hapus dari tabel siswa
      await supabase.from('siswa').delete().eq('id_siswa', idSiswa);

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

  Future<Object?> getSemuaKelas() async {}
}
