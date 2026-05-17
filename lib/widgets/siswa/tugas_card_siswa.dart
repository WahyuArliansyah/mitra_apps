import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mitra_apps/models/status_info.dart';
import 'package:mitra_apps/widgets/siswa/unread_dot.dart';

class TugasCard extends StatelessWidget {
  final Map<String, dynamic> tugas;
  final Map<String, dynamic>? pengumpulan;
  final bool isUnread;
  final VoidCallback onTap;

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
      return DateFormat(
        'dd MMM, HH:mm',
      ).format(DateTime.parse(isoDate).toLocal());
    } catch (_) {
      return isoDate;
    }
  }

  bool _isDeadlineNear(String? isoDate) {
    if (isoDate == null) return false;
    try {
      final deadline = DateTime.parse(isoDate).toLocal();
      final diff = deadline.difference(DateTime.now()).inDays;
      return diff <= 2 && deadline.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }

  bool _isDeadlinePassed(String? isoDate) {
    if (isoDate == null) return false;
    try {
      return DateTime.parse(isoDate).toUtc().isBefore(DateTime.now().toUtc());
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
    if (isPassed) deadlineColor = const Color(0xFFE24B4A);
    if (isNear && !isPassed) deadlineColor = const Color(0xFFD97706);

    // Warna bar kiri berdasarkan status
    Color barColor = const Color(0xFF2563EB);
    if (isPassed && !sudahKumpul) barColor = const Color(0xFFE24B4A);
    if (statusKumpul == 'dinilai') barColor = const Color(0xFF059669);
    if (statusKumpul == 'terlambat') barColor = const Color(0xFFD97706);

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
                    // Bar kiri
                    Container(width: 4, color: barColor),

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
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(11),
                                  ),
                                  child: const Icon(
                                    Icons.assignment_rounded,
                                    color: Color(0xFF2563EB),
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
                                        tugas['judul_tugas'] ?? '-',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1A1F36),
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        tugas['mata_pelajaran']?['nama_mapel'] ??
                                            '-',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFF9AA0B2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 10),

                            // Status pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusInfo.bgColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    statusInfo.icon,
                                    size: 12,
                                    color: statusInfo.color,
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    statusInfo.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: statusInfo.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),

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
                                  tugas['kelas']?['nama_kelas'] ?? '-',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  isPassed
                                      ? Icons.warning_rounded
                                      : Icons.access_time_rounded,
                                  size: 13,
                                  color: deadlineColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  isPassed && !sudahKumpul
                                      ? 'Waktu habis'
                                      : _formatTenggat(deadline),
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
                              child: TextButton.icon(
                                onPressed: (isPassed && !sudahKumpul)
                                    ? null
                                    : onTap,
                                icon: Icon(
                                  (isPassed && !sudahKumpul)
                                      ? Icons.block_rounded
                                      : sudahKumpul
                                      ? Icons.visibility_rounded
                                      : Icons.upload_file_rounded,
                                  size: 15,
                                ),
                                label: Text(
                                  (isPassed && !sudahKumpul)
                                      ? 'Waktu Pengumpulan Berakhir'
                                      : sudahKumpul
                                      ? 'Lihat Detail'
                                      : 'Kumpulkan Tugas',
                                ),
                                style: TextButton.styleFrom(
                                  backgroundColor: (isPassed && !sudahKumpul)
                                      ? const Color(0xFFF9FAFB)
                                      : const Color(0xFFEFF6FF),
                                  foregroundColor: (isPassed && !sudahKumpul)
                                      ? const Color(0xFF6B7280)
                                      : const Color(0xFF2563EB),
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
