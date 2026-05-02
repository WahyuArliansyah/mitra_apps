import 'package:flutter/material.dart';

class SiswaCard extends StatelessWidget {
  final Map<String, dynamic> siswa;
  final bool isSelecting;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onEdit;
  final VoidCallback onHapus;

  static const _primary = Color(0xFF4338CA);

  const SiswaCard({
    super.key,
    required this.siswa,
    required this.isSelecting,
    required this.isSelected,
    required this.onTap,
    required this.onLongPress,
    required this.onEdit,
    required this.onHapus,
  });

  @override
  Widget build(BuildContext context) {
    final idSiswa = siswa['id_siswa'].toString();
    final inisial = siswa['nama_siswa'].toString().isNotEmpty
        ? siswa['nama_siswa']
              .toString()
              .trim()
              .split(' ')
              .map((e) => e[0])
              .take(2)
              .join()
        : '?';
    final namaKelas = siswa['kelas']?['nama_kelas'] ?? '-';

    return GestureDetector(
      onLongPress: onLongPress,
      onTap: isSelecting ? onTap : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEEF2FF) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: isSelected ? Border.all(color: _primary, width: 2) : null,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: isSelecting
              ? Checkbox(
                  value: isSelected,
                  activeColor: _primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  onChanged: (_) => onTap(),
                )
              : CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFFEEF2FF),
                  child: Text(
                    inisial.toUpperCase(),
                    style: const TextStyle(
                      color: _primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
          title: Text(
            siswa['nama_siswa'],
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1A1F36),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                _badge(siswa['nis'] ?? '-', _primary, const Color(0xFFEEF2FF)),
                const SizedBox(width: 6),
                _badge(
                  namaKelas,
                  const Color(0xFF059669),
                  const Color(0xFFF0FDF4),
                ),
              ],
            ),
          ),
          trailing: isSelecting
              ? null
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _actionBtn(
                      Icons.edit_rounded,
                      const Color(0xFF4E73DF),
                      const Color(0xFFEEF2FF),
                      onEdit,
                    ),
                    const SizedBox(width: 6),
                    _actionBtn(
                      Icons.delete_rounded,
                      Colors.redAccent,
                      const Color(0xFFFFEEEE),
                      onHapus,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _actionBtn(IconData icon, Color color, Color bg, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 17),
      ),
    );
  }
}
