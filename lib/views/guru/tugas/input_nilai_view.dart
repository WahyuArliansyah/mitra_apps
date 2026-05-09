import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InputNilaiView extends StatefulWidget {
  final Map<String, dynamic> siswa;
  final Map<String, dynamic> tugas;
  final Map<String, dynamic>? pengumpulan;
  final Map<String, dynamic>? nilaiExisting;
  final String idGuru;

  const InputNilaiView({
    super.key,
    required this.siswa,
    required this.tugas,
    required this.idGuru,
    this.pengumpulan,
    this.nilaiExisting,
  });

  @override
  State<InputNilaiView> createState() => _InputNilaiViewState();
}

class _InputNilaiViewState extends State<InputNilaiView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);

  late TextEditingController _nilaiCtrl;
  late TextEditingController _umpanBalikCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nilaiCtrl = TextEditingController(
      text: widget.nilaiExisting?['nilai']?.toString() ?? '',
    );
    _umpanBalikCtrl = TextEditingController(
      text: widget.nilaiExisting?['umpan_balik'] ?? '',
    );
  }

  @override
  void dispose() {
    _nilaiCtrl.dispose();
    _umpanBalikCtrl.dispose();
    super.dispose();
  }

  Future<void> _simpanNilai() async {
    final nilaiStr = _nilaiCtrl.text.trim();
    if (nilaiStr.isEmpty) {
      _showSnackbar('Nilai wajib diisi!', isError: true);
      return;
    }

    final nilai = double.tryParse(nilaiStr);
    if (nilai == null || nilai < 0 || nilai > 100) {
      _showSnackbar('Nilai harus antara 0 - 100!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final isEdit = widget.nilaiExisting != null;
      final typePenilaian = widget.pengumpulan != null
          ? 'dari_upload'
          : 'manual';

      if (isEdit) {
        // Update nilai yang sudah ada
        await supabase
            .from('nilai')
            .update({
              'nilai': nilai,
              'umpan_balik': _umpanBalikCtrl.text.trim(),
              'dinilai_at': DateTime.now().toIso8601String(),
            })
            .eq('id', widget.nilaiExisting!['id']);
      } else {
        // Insert nilai baru
        await supabase.from('nilai').insert({
          'id_tugas': widget.tugas['id'],
          'id_siswa': widget.siswa['id_siswa'],
          'id_pengumpulan': widget.pengumpulan?['id'],
          'nilai': nilai,
          'type_penilaian': typePenilaian,
          'umpan_balik': _umpanBalikCtrl.text.trim(),
          'id_guru_penilai': widget.idGuru,
          'dinilai_at': DateTime.now().toIso8601String(),
        });

        // Update status pengumpulan jika ada
        if (widget.pengumpulan != null) {
          await supabase
              .from('pengumpulan')
              .update({'status_pengumpulan': 'dinilai'})
              .eq('id', widget.pengumpulan!['id']);
        }
      }

      if (mounted) {
        Navigator.pop(context);
        _showSnackbar('Nilai berhasil disimpan!');
      }
    } catch (e) {
      _showSnackbar('Gagal menyimpan nilai: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPraktikum = widget.tugas['type_tugas'] == 'praktikum';
    final isEdit = widget.nilaiExisting != null;
    final inisial = widget.siswa['nama_siswa'].toString().isNotEmpty
        ? widget.siswa['nama_siswa']
              .toString()
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
        : '?';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Nilai' : 'Beri Nilai',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info siswa
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE0F2FE),
                    child: Text(
                      inisial.toUpperCase(),
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.siswa['nama_siswa'],
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.siswa['nis'] ?? '-',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info tugas
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isPraktikum
                    ? const Color(0xFFFEF3E0)
                    : const Color(0xFFE0F2FE),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    isPraktikum
                        ? Icons.science_rounded
                        : Icons.menu_book_rounded,
                    color: isPraktikum ? const Color(0xFFD97706) : _primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.tugas['judul_tugas'] ?? '-',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          '${isPraktikum ? 'Praktikum' : 'Materi'} • Bobot ${isPraktikum ? '70%' : '30%'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Bukti pengumpulan (jika ada)
            if (widget.pengumpulan != null) ...[
              const Text(
                'Bukti Pengumpulan',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.pengumpulan!['url_file_bukti'] != null)
                      GestureDetector(
                        onTap: () async {
                          final url = Uri.parse(
                            widget.pengumpulan!['url_file_bukti'],
                          );
                          try {
                            final launched = await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                            if (!launched && context.mounted) {
                              await launchUrl(
                                url,
                                mode: LaunchMode.inAppWebView,
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tidak bisa membuka file: $e'),
                                  backgroundColor: Colors.redAccent,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 12,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _primary.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.open_in_new_rounded,
                                color: _primary,
                                size: 16,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Buka File Jawaban Siswa',
                                style: TextStyle(
                                  color: _primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (widget.pengumpulan!['catatan_siswa'] != null &&
                        widget.pengumpulan!['catatan_siswa']
                            .toString()
                            .isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Catatan: ${widget.pengumpulan!['catatan_siswa']}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      'Dikumpulkan: ${_formatTanggal(widget.pengumpulan!['waktu_pengumpulan'])}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Input nilai
            const Text(
              'Nilai (0 - 100)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nilaiCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Masukkan nilai...',
                prefixIcon: const Icon(Icons.grade_rounded, color: _primary),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Umpan balik
            const Text(
              'Umpan Balik (opsional)',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _umpanBalikCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Tulis komentar atau masukan untuk siswa...',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _primary, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanNilai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
                    : Text(
                        isEdit ? 'Simpan Perubahan' : 'Simpan Nilai',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTanggal(String? tanggal) {
    if (tanggal == null) return '-';
    final dt = DateTime.parse(tanggal);
    return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
