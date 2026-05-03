import 'package:flutter/material.dart';

class TabelHistoryNilai extends StatelessWidget {
  final List<Map<String, dynamic>> historyNilai;

  static const _primary = Color(0xFF0EA5E9);

  const TabelHistoryNilai({super.key, required this.historyNilai});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, color: _primary, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'History Nilai',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const Spacer(),
                Text(
                  '${historyNilai.length} tugas',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ],
            ),
          ),

          // Header kolom
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: const Row(
              children: [
                SizedBox(width: 30, child: Text('No', style: _headerStyle)),
                Expanded(
                  flex: 3,
                  child: Text('Judul Tugas', style: _headerStyle),
                ),
                SizedBox(
                  width: 70,
                  child: Text(
                    'Tipe',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 50,
                  child: Text(
                    'Nilai',
                    style: _headerStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Isi tabel
          historyNilai.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Text(
                      'Belum ada nilai',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: historyNilai.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) => _buildRow(historyNilai[i], i + 1),
                ),
        ],
      ),
    );
  }

  Widget _buildRow(Map<String, dynamic> item, int no) {
    final tugas = item['tugas'];
    final isPraktikum = tugas?['type_tugas'] == 'praktikum';
    final nilai = (item['nilai'] as num).toDouble();

    Color nilaiColor;
    if (nilai >= 80) {
      nilaiColor = const Color(0xFF059669);
    } else if (nilai >= 60) {
      nilaiColor = const Color(0xFFD97706);
    } else {
      nilaiColor = Colors.redAccent;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // No
          SizedBox(
            width: 30,
            child: Text(
              '$no',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
          // Judul
          Expanded(
            flex: 3,
            child: Text(
              tugas?['judul_tugas'] ?? '-',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
          // Tipe badge
          SizedBox(
            width: 70,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: isPraktikum
                      ? const Color(0xFFFEF3E0)
                      : const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPraktikum ? 'Praktikum' : 'Materi',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: isPraktikum ? const Color(0xFFD97706) : _primary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          // Nilai
          SizedBox(
            width: 50,
            child: Text(
              nilai.toStringAsFixed(0),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: nilaiColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  static const _headerStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: Color(0xFF9AA0B2),
  );
}
