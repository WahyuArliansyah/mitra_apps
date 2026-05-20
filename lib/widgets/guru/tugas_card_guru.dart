import 'package:flutter/material.dart';

class TugasCard extends StatelessWidget {
  final Map<String, dynamic> tugas;
  final VoidCallback onTap;

  static const _navy = Color(0xFF0F2D5C);

  const TugasCard({super.key, required this.tugas, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPraktikum = tugas['type_tugas'] == 'praktikum';
    final isUpload = tugas['metode'] == 'upload';
    final deadline = tugas['tenggat_waktu'] != null
        ? DateTime.parse(tugas['tenggat_waktu'])
        : null;
    final isLewat = deadline != null && deadline.isBefore(DateTime.now());

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icon type tugas
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: isPraktikum
                        ? const Color(0xFFFEF3E0)
                        : const Color(0xFFE0F2FE),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isPraktikum
                        ? Icons.science_rounded
                        : Icons.menu_book_rounded,
                    color: isPraktikum ? const Color(0xFFD97706) : _navy,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tugas['judul_tugas'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1A1F36),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${tugas['mata_pelajaran']?['nama_mapel'] ?? '-'} • ${tugas['kelas']?['nama_kelas'] ?? '-'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Badge type
                _badge(
                  isPraktikum ? 'Praktikum' : 'Materi',
                  isPraktikum ? const Color(0xFFD97706) : _navy,
                  isPraktikum
                      ? const Color(0xFFFEF3E0)
                      : const Color(0xFFE0F2FE),
                ),
                const SizedBox(width: 6),
                // Badge metode
                _badge(
                  isUpload ? 'Upload' : 'Manual',
                  isUpload ? const Color(0xFF059669) : const Color(0xFF7C3AED),
                  isUpload ? const Color(0xFFE6FAF5) : const Color(0xFFF0EBFF),
                ),
                const Spacer(),
                // Deadline
                if (deadline != null)
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: isLewat
                            ? Colors.redAccent
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${deadline.day}/${deadline.month}/${deadline.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isLewat
                              ? Colors.redAccent
                              : Colors.grey.shade400,
                          fontWeight: isLewat
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color, Color bg) {
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
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
