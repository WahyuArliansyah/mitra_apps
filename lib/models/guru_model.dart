class GuruModel {
  String? idGuru;
  String? userId;
  String? nip;
  String namaLengkap;
  String email;
  String? jenisKelamin;
  String? noHp;

  GuruModel({
    this.idGuru,
    this.userId,
    this.nip,
    required this.namaLengkap,
    required this.email,
    this.jenisKelamin,
    this.noHp,
  });

  factory GuruModel.fromJson(Map<String, dynamic> json) {
    return GuruModel(
      idGuru:
          json['id_guru']
              as String?, // <-- Menyesuaikan dengan nama kolom di Supabase
      userId: json['user_id'] as String?,
      nip: json['nip'] as String?,
      namaLengkap: json['nama_lengkap'] as String? ?? 'Tanpa Nama',
      email: json['email'] as String? ?? 'Tidak ada email',
      jenisKelamin: json['jenis_kelamin'] as String?,
      noHp: json['no_hp'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nip': nip,
      'nama_lengkap': namaLengkap,
      'email': email,
      'jenis_kelamin': jenisKelamin,
      'no_hp': noHp,
    };
  }
}
