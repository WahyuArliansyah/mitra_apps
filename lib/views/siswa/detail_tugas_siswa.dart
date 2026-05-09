import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailTugasSiswa extends StatefulWidget {
  final Map<String, dynamic> tugas;
  final String idSiswa;

  const DetailTugasSiswa({
    super.key,
    required this.tugas,
    required this.idSiswa,
  });

  @override
  State<DetailTugasSiswa> createState() => _DetailTugasSiswaViewState();
}

class _DetailTugasSiswaViewState extends State<DetailTugasSiswa> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);

  final _catatanController = TextEditingController();

  Map<String, dynamic>? _pengumpulan;
  bool _isLoadingPengumpulan = true;
  bool _isUploading = false;

  File? _filePicked;
  String? _filePickedName;

  @override
  void initState() {
    super.initState();
    debugPrint('Data tugas: ${widget.tugas}');
    debugPrint('url_file_materi: ${widget.tugas['url_file_materi']}');
    _cekPengumpulan();
  }

  @override
  void dispose() {
    _catatanController.dispose();
    super.dispose();
  }

  bool get _deadlinePassed {
    final deadline = widget.tugas['tenggat_waktu'];
    if (deadline == null) return false;
    try {
      return DateTime.parse(deadline).toLocal().isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  /// Status yang akan disimpan ke DB berdasarkan kondisi tenggat
  String get _statusPengumpulan => _deadlinePassed ? 'terlambat' : 'menunggu';

  Future<void> _cekPengumpulan() async {
    setState(() => _isLoadingPengumpulan = true);
    try {
      final data = await supabase
          .from('pengumpulan')
          .select()
          .eq('id_tugas', widget.tugas['id'])
          .eq('id_siswa', widget.idSiswa)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _pengumpulan = data;
          if (data != null) {
            _catatanController.text = data['catatan_siswa'] ?? '';
          }
          _isLoadingPengumpulan = false;
        });
      }
    } catch (e) {
      debugPrint('Error cek pengumpulan: $e');
      if (mounted) setState(() => _isLoadingPengumpulan = false);
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _filePicked = File(result.files.single.path!);
        _filePickedName = result.files.single.name;
      });
    }
  }

  Future<void> _kumpulkanTugas() async {
    // Jika belum pernah kumpul, wajib pilih file
    if (_pengumpulan == null && _filePicked == null) {
      _showSnackbar('Pilih file jawaban terlebih dahulu', isError: true);
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? urlFileBukti = _pengumpulan?['url_file_bukti'];

      // Upload file baru jika ada
      if (_filePicked != null) {
        final ext = _filePickedName!.split('.').last;
        final fileName =
            'pengumpulan/${widget.idSiswa}_${widget.tugas['id']}_${DateTime.now().millisecondsSinceEpoch}.$ext';

        await supabase.storage
            .from('tugas-bucket')
            .upload(fileName, _filePicked!);

        urlFileBukti = supabase.storage
            .from('tugas-bucket')
            .getPublicUrl(fileName);
      }

      final now = DateTime.now().toIso8601String();

      if (_pengumpulan == null) {
        // INSERT — status: 'menunggu' atau 'terlambat'
        await supabase.from('pengumpulan').insert({
          'id_tugas': widget.tugas['id'],
          'id_siswa': widget.idSiswa,
          'url_file_bukti': urlFileBukti,
          'catatan_siswa': _catatanController.text.trim(),
          'waktu_pengumpulan': now,
          'status_pengumpulan': _statusPengumpulan,
        });
      } else {
        // UPDATE — status tetap 'dinilai' jika sudah dinilai guru,
        // jika belum dinilai update sesuai kondisi tenggat
        final statusLama = _pengumpulan!['status_pengumpulan'];
        final statusBaru = statusLama == 'dinilai'
            ? 'dinilai'
            : _statusPengumpulan;

        await supabase
            .from('pengumpulan')
            .update({
              'url_file_bukti': urlFileBukti,
              'catatan_siswa': _catatanController.text.trim(),
              'waktu_pengumpulan': now,
              'status_pengumpulan': statusBaru,
            })
            .eq('id', _pengumpulan!['id']);
      }

      if (!mounted) return;
      _showSnackbar('Tugas berhasil dikumpulkan!');
      setState(() {
        _filePicked = null;
        _filePickedName = null;
      });
      await _cekPengumpulan();
    } catch (e) {
      debugPrint('Error kumpulkan tugas: $e');
      if (mounted) {
        _showSnackbar('Gagal mengumpulkan tugas: $e', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return DateFormat(
        'dd MMM yyyy, HH:mm',
      ).format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  // Warna & label badge status pengumpulan
  Color _statusColor(String status) {
    switch (status) {
      case 'dinilai':
        return const Color(0xFF059669);
      case 'terlambat':
        return Colors.redAccent;
      default: // menunggu
        return const Color(0xFFD97706);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'dinilai':
        return const Color(0xFFE6FAF5);
      case 'terlambat':
        return const Color(0xFFFFEDED);
      default:
        return const Color(0xFFFEF3E0);
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'dinilai':
        return Icons.check_circle_rounded;
      case 'terlambat':
        return Icons.warning_rounded;
      default:
        return Icons.hourglass_top_rounded;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'dinilai':
        return 'Sudah Dinilai';
      case 'terlambat':
        return 'Terlambat';
      default:
        return 'Menunggu Penilaian';
    }
  }

  @override
  Widget build(BuildContext context) {
    final tugas = widget.tugas;
    final sudahKumpul = _pengumpulan != null;
    final statusPengumpulan = _pengumpulan?['status_pengumpulan'] ?? 'menunggu';
    final sudahDinilai = statusPengumpulan == 'dinilai';

    // Tidak bisa update jika sudah dinilai
    final bisaEdit = !sudahDinilai;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: _primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Tugas',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: _isLoadingPengumpulan
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Card Info Tugas ────────────────────────────────────
                  _buildCardInfoTugas(tugas),
                  const SizedBox(height: 16),

                  // ── Banner Status Pengumpulan ──────────────────────────
                  if (sudahKumpul) ...[
                    _buildBannerStatus(statusPengumpulan),
                    const SizedBox(height: 16),
                  ],

                  // ── Form Upload ────────────────────────────────────────
                  if (bisaEdit) _buildFormUpload(sudahKumpul),

                  // ── Info sudah dinilai, tidak bisa edit ────────────────
                  if (sudahDinilai)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6FAF5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF059669).withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.lock_rounded,
                            color: Color(0xFF059669),
                            size: 20,
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Tugas ini sudah dinilai oleh guru dan tidak dapat diubah lagi.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF059669),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
    );
  }

  Widget _buildCardInfoTugas(Map<String, dynamic> tugas) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 5,
            decoration: const BoxDecoration(
              color: _primary,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tugas['judul_tugas'] ?? '-',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tugas['mata_pelajaran']?['nama_mapel'] ?? '-',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF9AA0B2),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0xFFF1F3F9)),
                const SizedBox(height: 12),
                _infoRow(
                  Icons.class_rounded,
                  'Kelas',
                  tugas['kelas']?['nama_kelas'] ?? '-',
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.access_time_rounded,
                  'Tenggat',
                  _formatTanggal(tugas['tenggat_waktu']),
                  valueColor: _deadlinePassed
                      ? Colors.redAccent
                      : const Color(0xFF1A1F36),
                ),
                const SizedBox(height: 8),
                _infoRow(
                  Icons.school_rounded,
                  'Semester',
                  'Semester ${tugas['semester'] ?? '-'}  •  ${tugas['tahun_ajaran'] ?? '-'}',
                ),
                if (tugas['deskripsi'] != null &&
                    tugas['deskripsi'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi Tugas',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1F36),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    tugas['deskripsi'],
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF4B5563),
                      height: 1.5,
                    ),
                  ),
                ],
                // Tombol lihat file soal
                if (tugas['url_file_materi'] != null &&
                    tugas['url_file_materi'].toString().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      // SESUDAH
                      onPressed: () async {
                        final url = Uri.parse(tugas['url_file_materi']);
                        try {
                          final launched = await launchUrl(
                            url,
                            mode: LaunchMode.externalApplication,
                          );
                          if (!launched && context.mounted) {
                            await launchUrl(url, mode: LaunchMode.inAppWebView);
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
                      icon: const Icon(Icons.attach_file_rounded, size: 16),
                      label: const Text('Lihat File Soal'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _primary,
                        side: const BorderSide(color: _primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerStatus(String status) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusColor(status).withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(_statusIcon(status), color: _statusColor(status), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _statusLabel(status),
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _statusColor(status),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'Dikumpulkan: ${_formatTanggal(_pengumpulan!['waktu_pengumpulan'])}',
                  style: TextStyle(fontSize: 11, color: _statusColor(status)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormUpload(bool sudahKumpul) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            sudahKumpul ? 'Perbarui Jawaban' : 'Upload Jawaban',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            sudahKumpul
                ? 'Kamu sudah mengumpulkan. Bisa diperbarui selama belum dinilai.'
                : _deadlinePassed
                ? 'Tenggat sudah lewat. Jawaban tetap bisa dikumpulkan namun ditandai terlambat.'
                : 'Upload file jawaban kamu (PDF, Word, atau gambar)',
            style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0B2)),
          ),
          const SizedBox(height: 16),

          // Area pilih file
          GestureDetector(
            onTap: _pickFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _filePicked != null
                    ? const Color(0xFFF0F9FF)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _filePicked != null ? _primary : Colors.grey.shade300,
                  width: _filePicked != null ? 1.5 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    _filePicked != null
                        ? Icons.insert_drive_file_rounded
                        : Icons.cloud_upload_rounded,
                    size: 40,
                    color: _filePicked != null
                        ? _primary
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _filePicked != null
                        ? _filePickedName!
                        : 'Ketuk untuk pilih file',
                    style: TextStyle(
                      fontSize: 13,
                      color: _filePicked != null
                          ? _primary
                          : Colors.grey.shade500,
                      fontWeight: _filePicked != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_filePicked == null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'PDF, DOC, DOCX, JPG, PNG',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ),
                  // Tampilkan file lama jika sudah pernah kumpul
                  if (_filePicked == null &&
                      sudahKumpul &&
                      _pengumpulan?['url_file_bukti'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: TextButton.icon(
                        onPressed: () async {
                          final url = Uri.parse(
                            _pengumpulan!['url_file_bukti'],
                          );
                          if (await canLaunchUrl(url)) {
                            await launchUrl(
                              url,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        icon: const Icon(Icons.open_in_new_rounded, size: 14),
                        label: const Text('Lihat file yang sudah dikumpulkan'),
                        style: TextButton.styleFrom(
                          foregroundColor: _primary,
                          textStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Catatan siswa
          const Text(
            'Catatan (opsional)',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _catatanController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Tulis catatan untuk guru...',
              hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: _primary),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Tombol kumpulkan
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _kumpulkanTugas,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(
                      sudahKumpul ? Icons.update_rounded : Icons.send_rounded,
                      size: 18,
                    ),
              label: Text(
                _isUploading
                    ? 'Mengupload...'
                    : sudahKumpul
                    ? 'Perbarui Jawaban'
                    : 'Kumpulkan Tugas',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
          ),

          // Warning jika terlambat
          if (_deadlinePassed)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 13,
                    color: Colors.redAccent.shade200,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tenggat sudah lewat — akan ditandai terlambat',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.redAccent.shade200,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: const Color(0xFF9AA0B2)),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF9AA0B2)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: valueColor ?? const Color(0xFF1A1F36),
            ),
          ),
        ),
      ],
    );
  }
}
