class SiswaModel {
  String? idSiswa;
  String? nis;
  String namaSiswa;
  String? idKelas;
  DateTime? createdAt;

  SiswaModel({
    this.idSiswa,
    this.nis,
    required this.namaSiswa,
    this.idKelas,
    this.createdAt,
  });

  factory SiswaModel.fromJson(Map<String, dynamic> json) {
    return SiswaModel(
      idSiswa: json['id_siswa'] as String?,
      nis: json['nis'] as String?,
      namaSiswa: json['nama_siswa'] as String? ?? 'Tanpa Nama',
      idKelas: json['id_kelas'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idSiswa != null) 'id_siswa': idSiswa,
      'nis': nis,
      'nama_siswa': namaSiswa,
      if (idKelas != null) 'id_kelas': idKelas,
    };
  }
}
