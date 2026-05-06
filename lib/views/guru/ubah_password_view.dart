import 'package:flutter/material.dart';
// Sesuaikan path import ini dengan struktur folder kamu
import 'package:mitra_apps/services/guru_service.dart';

class UbahPasswordView extends StatefulWidget {
  const UbahPasswordView({super.key});

  @override
  State<UbahPasswordView> createState() => _UbahPasswordDialogState();
}

class _UbahPasswordDialogState extends State<UbahPasswordView> {
  final _passwordController = TextEditingController();
  final _konfirmasiController = TextEditingController();

  // Panggil service yang sudah kamu buat
  final GuruService _guruService = GuruService();

  bool _isLoading = false;
  bool _obscureText1 = true;
  bool _obscureText2 = true;

  static const _primary = Color(0xFF0EA5E9);

  Future<void> _simpanPassword() async {
    final pass = _passwordController.text.trim();
    final konfirm = _konfirmasiController.text.trim();

    // Validasi Input
    if (pass.isEmpty || konfirm.isEmpty) {
      _showToast('Password tidak boleh kosong!');
      return;
    }
    if (pass.length < 6) {
      _showToast('Password minimal 6 karakter!');
      return;
    }
    if (pass != konfirm) {
      _showToast('Konfirmasi password tidak cocok!');
      return;
    }

    setState(() => _isLoading = true);

    // Menggunakan fungsi gantiPassword dari GuruService
    final bool berhasil = await _guruService.gantiPassword(pass);

    if (mounted) {
      setState(() => _isLoading = false);

      if (berhasil) {
        Navigator.pop(context); // Tutup dialog jika berhasil
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password berhasil diubah!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _showToast('Gagal mengubah password. Silakan coba lagi.');
      }
    }
  }

  void _showToast(String pesan) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(pesan), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _konfirmasiController.dispose();
    super.dispose();
  }

  // Fungsi bantuan untuk membuat label di atas textfield
  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1A1F36),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      // Mengubah warna dan padding title agar terlihat seperti header pop-up modern
      titlePadding: EdgeInsets.zero,
      title: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _primary.withOpacity(0.1),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: const Row(
          children: [
            Icon(Icons.lock_reset_rounded, color: _primary, size: 28),
            SizedBox(width: 12),
            Text(
              'Ubah Kata Sandi',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: _primary,
              ),
            ),
          ],
        ),
      ),
      contentPadding: const EdgeInsets.all(24),
      // Membungkus content dengan SizedBox agar lebarnya maksimal (besar)
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Dinamis menyesuaikan tinggi isinya
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- FIELD 1: PASSWORD BARU ---
            _buildLabel('Password Baru'),
            TextField(
              controller: _passwordController,
              obscureText: _obscureText1,
              decoration: InputDecoration(
                hintText: 'Minimal 6 Karakter',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText1 ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscureText1 = !_obscureText1),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- FIELD 2: KONFIRMASI PASSWORD ---
            _buildLabel('Konfirmasi Password Baru'),
            TextField(
              controller: _konfirmasiController,
              obscureText: _obscureText2,
              decoration: InputDecoration(
                hintText: 'Minimal 6 Karakter',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: const Icon(
                  Icons.check_circle_outline,
                  color: Colors.grey,
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText2 ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () =>
                      setState(() => _obscureText2 = !_obscureText2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 2),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isLoading ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanPassword,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: _primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Simpan',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
