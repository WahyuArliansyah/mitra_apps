import 'package:flutter/material.dart';

class BulkActionDialog {
  static const _primary = Color(0xFF4338CA);

  // Dialog konfirmasi hapus massal
  static Future<bool> konfirmasiHapus(BuildContext context, int jumlah) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus Massal?', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: Text(
              '$jumlah siswa akan dihapus dan tidak dapat dikembalikan.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Hapus Semua'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Dialog pindah kelas massal
  static Future<String?> pilihKelasTujuan(
    BuildContext context,
    int jumlah,
    List<Map<String, dynamic>> listKelas,
  ) async {
    String? idKelasBaru;

    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text('Pindah Kelas $jumlah Siswa'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih kelas tujuan:'),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: idKelasBaru,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.class_rounded, color: _primary),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _primary, width: 2),
                  ),
                ),
                hint: const Text('Pilih kelas tujuan'),
                items: listKelas
                    .map(
                      (k) => DropdownMenuItem<String>(
                        value: k['id'].toString(),
                        child: Text(k['nama_kelas']),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setStateDialog(() => idKelasBaru = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: idKelasBaru == null
                  ? null
                  : () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Pindahkan'),
            ),
          ],
        ),
      ),
    );

    return konfirmasi == true ? idKelasBaru : null;
  }
}
