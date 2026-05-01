class GuruModel {
  String? idGuru;
  String? userId;
  String? nip;
  String namaLengkap;
  String email;

  GuruModel({
    this.idGuru,
    this.userId,
    this.nip,
    required this.namaLengkap,
    required this.email,
  });

  // Mengubah data JSON dari Supabase menjadi Object Flutter[cite: 3]
  factory GuruModel.fromJson(Map<String, dynamic> json) {
    return GuruModel(
      idGuru: json['id_guru'] as String?,
      userId: json['user_id'] as String?,
      nip: json['nip'] as String?,
      namaLengkap: json['nama_lengkap'] as String? ?? 'Tanpa Nama',
      email: json['email'] as String? ?? 'Tidak ada email',
    );
  }

  // Mengubah Object Flutter menjadi Map untuk disimpan ke Supabase[cite: 3]
  Map<String, dynamic> toMap() {
    return {
      if (idGuru != null) 'id_guru': idGuru,
      'user_id': userId, // Digunakan untuk relasi ke tabel pengguna[cite: 3]
      'nip': nip,
      'nama_lengkap': namaLengkap,
      'email': email,
    };
  }
}
