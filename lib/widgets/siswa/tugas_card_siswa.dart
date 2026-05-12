import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mitra_apps/models/status_info.dart';
import 'package:mitra_apps/widgets/siswa/unread_dot.dart';

class TugasCard extends StatelessWidget {
  final Map<String, dynamic> tugas;
  final Map<String, dynamic>? pengumpulan;
  final bool isUnread;
  final VoidCallback onTap;

  static const _primary = Color(0xFF0EA5E9);

  const TugasCard({
    super.key,
    required this.tugas,
    required this.pengumpulan,
    required this.isUnread,
    required this.onTap,
  });

  String _formatTenggat(String? isoDate) {
    if (isoDate == null) return '-';
    try {
      return DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  bool _isDeadlineNear(String? isoDate) {
    if (isoDate == null) return false;
    try {
      final deadline = DateTime.parse(isoDate);
      final diff = deadline.difference(DateTime.now()).inDays;
      return diff <= 2 && deadline.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _isDeadlinePassed(String? isoDate) {
    if (isoDate == null) return false;
    try {
      return DateTime.parse(isoDate).isBefore(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final deadline = tugas['tenggat_waktu']?.toString();
    final isNear = _isDeadlineNear(deadline);
    final isPassed = _isDeadlinePassed(deadline);
    final sudahKumpul = pengumpulan != null;
    final statusKumpul = pengumpulan?['status_pengumpulan'] as String?;

    final statusInfo = StatusInfo.from(
      sudahKumpul: sudahKumpul,
      statusKumpul: statusKumpul,
      isPassed: isPassed,
    );

    Color deadlineColor = const Color(0xFF6B7280);
    if (isPassed) deadlineColor = Colors.redAccent;
    if (isNear && !isPassed) deadlineColor = const Color(0xFFD97706);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Content Card
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
                  decoration: BoxDecoration(
                    color: statusInfo.stripColor,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: icon + judul + mapel
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE0F2FE),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.assignment_rounded,
                              color: _primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tugas['judul_tugas'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1A1F36),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  tugas['mata_pelajaran']?['nama_mapel'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF9AA0B2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Badge status pengumpulan
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 12,
                        ),
                        decoration: BoxDecoration(
                          color: statusInfo.bgColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: statusInfo.color.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              statusInfo.icon,
                              size: 16,
                              color: statusInfo.color,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              statusInfo.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: statusInfo.color,
                              ),
                            ),
                            if (sudahKumpul &&
                                pengumpulan?['waktu_pengumpulan'] != null) ...[
                              const Spacer(),
                              Text(
                                _formatTenggat(
                                  pengumpulan!['waktu_pengumpulan'],
                                ),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: statusInfo.color,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Deskripsi
                      if (tugas['deskripsi'] != null &&
                          tugas['deskripsi'].toString().isNotEmpty) ...[
                        Text(
                          tugas['deskripsi'],
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 12),
                      ],

                      const Divider(height: 1, color: Color(0xFFF1F3F9)),
                      const SizedBox(height: 10),

                      // Footer: kelas + tenggat
                      Row(
                        children: [
                          Icon(
                            Icons.class_rounded,
                            size: 14,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            tugas['kelas']?['nama_kelas'] ?? '-',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            isPassed
                                ? Icons.warning_rounded
                                : Icons.access_time_rounded,
                            size: 14,
                            color: deadlineColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _formatTenggat(deadline),
                            style: TextStyle(
                              fontSize: 11,
                              color: deadlineColor,
                              fontWeight: isNear || isPassed
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Tombol aksi
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: (isPassed && !sudahKumpul) ? null : onTap,
                          icon: Icon(
                            (isPassed && !sudahKumpul)
                                ? Icons.block_rounded
                                : sudahKumpul
                                ? Icons.visibility_rounded
                                : Icons.upload_file_rounded,
                            size: 16,
                          ),
                          label: Text(
                            (isPassed && !sudahKumpul)
                                ? 'Waktu Pengumpulan Berakhir'
                                : sudahKumpul
                                ? 'Lihat Detail'
                                : 'Kumpulkan Tugas',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: (isPassed && !sudahKumpul)
                                ? Colors.grey
                                : statusInfo.color,
                            side: BorderSide(
                              color: (isPassed && !sudahKumpul)
                                  ? Colors.grey.shade300
                                  : statusInfo.color,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            textStyle: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
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
