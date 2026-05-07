import 'package:flutter/material.dart';

class RekapNilaiSiswa extends StatelessWidget {
  final String idSiswa;
  final String namaSiswa;
  final String idKelas;

  const RekapNilaiSiswa({
    super.key,
    required this.idSiswa,
    required this.namaSiswa,
    required this.idKelas,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F8),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.insert_chart_rounded,
                  size: 40,
                  color: Color(0xFF0EA5E9),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Rekap Nilai Saya',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                namaSiswa,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'ID Siswa: $idSiswa',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                'ID Kelas: $idKelas',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
