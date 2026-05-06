import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:auto_start_flutter/auto_start_flutter.dart'
    as DisableBatteryOptimization2;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PengaturanNotifikasiView extends StatefulWidget {
  const PengaturanNotifikasiView({super.key});

  @override
  State<PengaturanNotifikasiView> createState() =>
      _PengaturanNotifikasiViewState();
}

class _PengaturanNotifikasiViewState extends State<PengaturanNotifikasiView> {
  // get AutoStartFlutter => null;

  // Fungsi sakti untuk melawan OEM Background Restrictions
  Future<void> _perbaikiNotifikasi() async {
    try {
      // 1. Matikan Penghemat Baterai (Battery Optimization)
      bool? isBatteryOptimized =
          await DisableBatteryOptimization2.isBatteryOptimizationDisabled;

      if (isBatteryOptimized != true) {
        // Jika masih dibatasi, arahkan ke pengaturan baterai
        await DisableBatteryOptimization2.disableBatteryOptimization();
      }

      // Beri jeda sedikit agar transisi mulus
      await Future.delayed(const Duration(milliseconds: 500));

      // 2. Buka pengaturan Mulai Otomatis (Autostart)
      // Cek apakah HP ini mendukung fitur Autostart (seperti Xiaomi, Oppo, dkk)
      bool? isAutoStartAvailableCheck = await isAutoStartAvailable;

      if (isAutoStartAvailableCheck == true) {
        await getAutoStartPermission();
      }
    } on PlatformException catch (e) {
      print("Gagal membuka pengaturan: ${e.message}");
      // Tampilkan snackbar jika HP tidak mendukung fitur ini
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengaturan otomatis tidak didukung di HP ini.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Aplikasi'),
        backgroundColor: const Color(0xFF0EA5E9),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notifikasi Sering Terlambat?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Jika kamu menggunakan HP Xiaomi, Oppo, atau Vivo, sistem sering kali mematikan notifikasi tugas latar belakang. Klik tombol di bawah untuk memberikan izin.',
              style: TextStyle(color: Colors.grey, height: 1.5),
            ),
            const SizedBox(height: 20),

            // Tombol Perbaikan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _perbaikiNotifikasi,
                icon: const Icon(
                  Icons.build_circle_outlined,
                  color: Colors.white,
                ),
                label: const Text(
                  'Perbaiki Masalah Notifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
