import 'package:auto_start_flutter/auto_start_flutter.dart';
import 'package:flutter/material.dart';

class PengaturanNotifikasiView extends StatefulWidget {
  const PengaturanNotifikasiView({super.key});

  @override
  State<PengaturanNotifikasiView> createState() =>
      _PengaturanNotifikasiViewState();
}

class _PengaturanNotifikasiViewState extends State<PengaturanNotifikasiView> {
  static const _primary = Color(0xFF0EA5E9);

  Future<void> _perbaikiNotifikasi() async {
    try {
      bool? isAutoStartAvailable = await getAutoStartPermission();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Membuka pengaturan sistem...")),
      );
    } catch (e) {
      debugPrint("Gagal membuka pengaturan: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          "Optimasi Notifikasi",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildLanguageCard(
              title: "Instruksi Penting (ID)",
              desc:
                  "Agar notifikasi tugas tidak terlambat di HP Xiaomi/Oppo/Vivo, silakan klik tombol di bawah lalu aktifkan 'Mulai Otomatis' (Autostart) dan ubah Penghemat Baterai menjadi 'Tidak Ada Pembatasan'.",
              icon: Icons.notifications_active,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildLanguageCard(
              title: "Important Instructions (EN)",
              desc:
                  "To ensure task notifications arrive on time on Xiaomi/Oppo/Vivo devices, please click the button below then enable 'Autostart' and set Battery Saver to 'No Restrictions'.",
              icon: Icons.language,
              color: Colors.orange,
            ),
            const SizedBox(height: 30),

            // Tombol Utama
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: _perbaikiNotifikasi,
                icon: const Icon(Icons.settings_suggest, color: Colors.white),
                label: const Text(
                  "BUKA PENGATURAN / OPEN SETTINGS",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  elevation: 4,
                ),
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              "*Aplikasi akan mengarahkanmu ke pengaturan sistem Android.",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
    required String title,
    required String desc,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
