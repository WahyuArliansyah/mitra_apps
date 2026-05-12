import 'package:flutter/material.dart';

class MappingCard extends StatelessWidget {
  final Map<String, dynamic> mapping;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  static const _primary = Color(0xFF7C3AED);

  const MappingCard({
    super.key,
    required this.mapping,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final kelas = mapping['kelas'];
    final mapel = mapping['mata_pelajaran'];

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.assignment_rounded,
            color: _primary,
            size: 22,
          ),
        ),
        title: Text(
          mapel?['nama_mapel'] ?? '-',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.class_rounded, size: 13, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    '${kelas?['nama_kelas'] ?? '-'} • ${kelas?['jurusan'] ?? '-'}',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  '${mapping['tahun_ajaran']} • Semester ${mapping['semester']}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.edit_note_rounded,
                color: Colors.blueAccent,
              ),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              onPressed: onHapus,
            ),
          ],
        ),
      ),
    );
  }
}
