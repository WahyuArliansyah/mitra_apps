import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mitra_apps/widgets/siswa/unread_dot.dart';

class MateriCard extends StatelessWidget {
  final Map<String, dynamic> materi;
  final bool isUnread;
  final VoidCallback onTap;

  static const _purple = Color(0xFF7C3AED);
  static const _purpleBg = Color(0xFFF5F3FF);

  const MateriCard({
    super.key,
    required this.materi,
    required this.isUnread,
    required this.onTap,
  });

  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return DateFormat(
        'dd MMM yyyy',
      ).format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Bar kiri ungu
                    Container(width: 4, color: _purple),

                    // Konten
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: _purpleBg,
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.menu_book_rounded,
                                    color: _purple,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        materi['judul_materi'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1F36),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        materi['mata_pelajaran']?['nama_mapel'] ??
                                            '-',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9AA0B2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Badge Materi
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _purpleBg,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text(
                                    'Materi',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: _purple,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Deskripsi
                            if (materi['deskripsi'] != null &&
                                materi['deskripsi'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              Text(
                                materi['deskripsi'],
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF4B5563),
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],

                            const SizedBox(height: 10),
                            const Divider(height: 1, color: Color(0xFFF3F4F6)),
                            const SizedBox(height: 10),

                            // Footer
                            Row(
                              children: [
                                const Icon(
                                  Icons.business_rounded,
                                  size: 13,
                                  color: Color(0xFF9AA0B2),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  materi['kelas']?['nama_kelas'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const Spacer(),
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 13,
                                  color: Color(0xFF9AA0B2),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _formatTanggal(materi['created_at']),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                              ],
                            ),

                            // Tombol buka file
                            if (materi['url_file'] != null &&
                                materi['url_file'].toString().isNotEmpty) ...[
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: TextButton.icon(
                                  onPressed: () async {
                                    onTap();
                                    final url = Uri.parse(materi['url_file']);
                                    if (await canLaunchUrl(url)) {
                                      await launchUrl(
                                        url,
                                        mode: LaunchMode.externalApplication,
                                      );
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.open_in_new_rounded,
                                    size: 15,
                                  ),
                                  label: const Text('Buka File Materi'),
                                  style: TextButton.styleFrom(
                                    backgroundColor: _purpleBg,
                                    foregroundColor: _purple,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 9,
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        if (isUnread) const Positioned(top: -3, right: -3, child: UnreadDot()),
      ],
    );
  }
}
