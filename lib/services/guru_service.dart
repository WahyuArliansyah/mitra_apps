import 'package:mitra_apps/models/guru_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GuruService {
  // Memanggil mesin Supabase
  final supabase = Supabase.instance.client;

  // 1. FUNGSI READ: Mengambil daftar semua guru dari database
  Future<List<GuruModel>> getSemuaGuru() async {
    try {
      // Minta data dari tabel 'guru' urutkan berdasarkan nama
      final response = await supabase
          .from('guru')
          .select()
          .order('nama_lengkap', ascending: true);

      // Ubah data mentah (JSON) menjadi list cetakan GuruModel
      return (response as List)
          .map((data) => GuruModel.fromJson(data))
          .toList();
    } catch (e) {
      print('Error saat mengambil data guru: $e');
      return []; // Jika error, kembalikan list kosong agar aplikasi tidak crash
    }
  }

  // Menambah guru baru ke database
  Future<bool> tambahGuru(GuruModel guru) async {
    try {
      await supabase.from('guru').insert(guru.toJson());
      return true; // Berhasil
    } catch (e) {
      print('Error saat menambah guru: $e');
      return false; // Gagal
    }
  }

  // Menghapus data guru berdasarkan ID
  Future<bool> hapusGuru(String idGuru) async {
    // <-- Parameternya saya ubah namanya agar lebih jelas
    try {
      // PERHATIKAN BARIS INI: 'id' diubah menjadi 'id_guru' menyesuaikan kolom di Supabase
      await supabase.from('guru').delete().eq('id_guru', idGuru);
      return true; // Berhasil
    } catch (e) {
      print('Error saat menghapus guru: $e');
      return false; // Gagal
    }
  }

  // Memastikan tidak ada NIP, Nama, atau Email yang sama
  Future<String?> cekDataDuplikat(String nip, String nama, String email) async {
    try {
      // Cek Email terlebih dahulu
      final cekEmail = await supabase
          .from('guru')
          .select('id_guru')
          .eq('email', email);
      if (cekEmail.isNotEmpty) return 'Email';

      // Cek NIP
      if (nip.isNotEmpty) {
        final cekNip = await supabase
            .from('guru')
            .select('id_guru')
            .eq('nip', nip);
        if (cekNip.isNotEmpty) return 'NIP';
      }

      // Cek Nama
      final cekNama = await supabase
          .from('guru')
          .select('id_guru')
          .ilike('nama_lengkap', nama);
      if (cekNama.isNotEmpty) return 'Nama Lengkap';

      return null; // Jika lolos semua pengecekan, kembalikan null (aman)
    } catch (e) {
      print('Error saat cek duplikat: $e');
      return 'Sistem'; // Jika terjadi error jaringan/sistem
    }
  }
}
