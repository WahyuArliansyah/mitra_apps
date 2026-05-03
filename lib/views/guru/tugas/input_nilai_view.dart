import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class InputNilaiView extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final Map<String, dynamic> siswa;
  final Map<String, dynamic>? pengumpulan;

  const InputNilaiView({
    super.key,
    required this.tugas,
    required this.siswa,
    this.pengumpulan,
  });

  @override
  State<InputNilaiView> createState() => _InputNilaiViewState();
}

class _InputNilaiViewState extends State<InputNilaiView> {
  final supabase = Supabase.instance.client;
  final _nilaiCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  bool _isLoading = false;

  static const _primary = Color(0xFF1A3A8F);
  static const _orange = Color(0xFFF97316);

  double get _nilaiPreview {
    final v = double.tryParse(_nilaiCtrl.text) ?? 0;
    return v.clamp(0, 100);
  }

  Color _nilaiColor(double nilai) {
    if (nilai >= 80) return Colors.green;
    if (nilai >= 65) return _orange;
    return Colors.red;
  }

  Future<void> _simpanNilai() async {
    final nilaiInput = double.tryParse(_nilaiCtrl.text.trim());
    if (nilaiInput == null || nilaiInput < 0 || nilaiInput > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan nilai antara 0 - 100'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final guruId = supabase.auth.currentUser!.id;
      final typePenilaian = widget.pengumpulan != null
          ? 'dari_upload'
          : 'manual';

      await supabase.from('nilai').upsert({
        'id_tugas': widget.tugas['id'],
        'id_siswa': widget.siswa['id_siswa'],
        'id_pengumpulan': widget.pengumpulan?['id'],
        'nilai': nilaiInput,
        'type_penilaian': typePenilaian,
        'umpan_balik': _feedbackCtrl.text.trim().isEmpty
            ? null
            : _feedbackCtrl.text.trim(),
        'id_guru_penilai': guruId,
      }, onConflict: 'id_tugas,id_siswa');

      // Update status pengumpulan jika ada
      if (widget.pengumpulan != null) {
        await supabase
            .from('pengumpulan')
            .update({'status_pengumpulan': 'dinilai'})
            .eq('id', widget.pengumpulan!['id']);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nilai berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal simpan: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nilaiCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final siswa = widget.siswa;
    final tugas = widget.tugas;
    final pengumpulan = widget.pengumpulan;
    final isUpload = pengumpulan != null;
    final isMateri = tugas['type_tugas'] == 'materi';

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        title: const Text(
          'Input Nilai',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Info Siswa ──────────────────────────
            _card(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: const Color(0xFFEEF2FF),
                    child: Text(
                      (siswa['nama_siswa'] as String)
                          .trim()
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join()
                          .toUpperCase(),
                      style: const TextStyle(
                        color: _primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          siswa['nama_siswa'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Color(0xFF1A1F36),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'NIS: ${siswa['nis'] ?? '-'}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Info Tugas ──────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detail Tugas',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    tugas['judul_tugas'] ?? '-',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _smallBadge(
                        isMateri ? 'Materi' : 'Praktikum',
                        isMateri ? _primary : Colors.orange.shade800,
                        isMateri
                            ? const Color(0xFFEEF2FF)
                            : const Color(0xFFFFF3E0),
                      ),
                      const SizedBox(width: 6),
                      _smallBadge(
                        isUpload ? 'Dari Upload' : 'Input Manual',
                        isUpload ? Colors.green.shade800 : Colors.pink.shade800,
                        isUpload
                            ? const Color(0xFFE8F5E9)
                            : const Color(0xFFFCE4EC),
                      ),
                      const SizedBox(width: 6),
                      _smallBadge(
                        'Bobot ${isMateri ? '30%' : '70%'}',
                        Colors.purple.shade800,
                        Colors.purple.shade50,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── File upload siswa (jika ada) ────────
            if (isUpload && pengumpulan['url_file_bukti'] != null) ...[
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'File Pengumpulan Siswa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: Color(0xFF1A1F36),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (pengumpulan['catatan_siswa'] != null) ...[
                      Text(
                        'Catatan: ${pengumpulan['catatan_siswa']}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    GestureDetector(
                      onTap: () async {
                        final url = Uri.parse(pengumpulan['url_file_bukti']);
                        if (await canLaunchUrl(url)) {
                          launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.open_in_new_rounded,
                              color: _primary,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Buka File Tugas Siswa',
                              style: TextStyle(
                                color: _primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Input Nilai ─────────────────────────
            _card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nilai (0 - 100)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Preview nilai besar
                  Center(
                    child: AnimatedBuilder(
                      animation: _nilaiCtrl,
                      builder: (_, __) {
                        final n = _nilaiPreview;
                        return Text(
                          _nilaiCtrl.text.isEmpty ? '-' : n.toStringAsFixed(0),
                          style: TextStyle(
                            fontSize: 56,
                            fontWeight: FontWeight.bold,
                            color: _nilaiCtrl.text.isEmpty
                                ? Colors.grey.shade300
                                : _nilaiColor(n),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  TextField(
                    controller: _nilaiCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Masukkan nilai...',
                      prefixIcon: const Icon(
                        Icons.grade_rounded,
                        color: _primary,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Umpan balik
                  const Text(
                    'Umpan Balik (opsional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _feedbackCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Tulis komentar untuk siswa...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primary, width: 2),
                      ),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Tombol Simpan ───────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpanNilai,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  disabledBackgroundColor: _orange.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        'SIMPAN NILAI',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _smallBadge(String label, Color text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }
}
