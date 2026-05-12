import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mitra_apps/widgets/siswa/unread_dot.dart';

class MateriCard extends StatelessWidget {
  final Map<String, dynamic> materi;
  final bool isUnread;
  final VoidCallback onTap;

  static const _color = Color(0xFF7C3AED);
  static const _bg = Color(0xFFF3F0FF);

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
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // ── Card Utama ──────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: isUnread
                  ? Border.all(
                      color: Colors.redAccent.withOpacity(0.4),
                      width: 1.5,
                    )
                  : null,
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
                // Strip warna atas
                Container(
                  height: 5,
                  decoration: const BoxDecoration(
                    color: _color,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: icon + judul + badge "Materi"
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.menu_book_rounded,
                              color: _color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  materi['judul_materi'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1F36),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  materi['mata_pelajaran']?['nama_mapel'] ??
                                      '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9AA0B2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Materi',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: _color,
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
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),
                      const Divider(height: 1, color: Color(0xFFF1F3F9)),
                      const SizedBox(height: 10),

                      // Footer: kelas + semester + tanggal
                      Row(
                        children: [
                          Icon(
                            Icons.class_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            materi['kelas']?['nama_kelas'] ?? '-',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Smt ${materi['semester'] ?? '-'}  •  ${materi['tahun_ajaran'] ?? '-'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.access_time_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTanggal(materi['created_at']),
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
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
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              onTap(); // tandai sebagai dibaca
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
                              size: 16,
                            ),
                            label: const Text('Buka File Materi'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _color,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              textStyle: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
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
          ),

          // ── Unread Dot ──────────────────────────────────────────────────
          if (isUnread)
            const Positioned(top: -5, right: -5, child: UnreadDot()),
        ],
      ),
    );
  }
}
