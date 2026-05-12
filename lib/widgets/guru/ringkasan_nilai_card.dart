import 'package:flutter/material.dart';

class RingkasanNilaiCard extends StatelessWidget {
  final double rataMateri;
  final double rataPraktikum;
  final double nilaiAkhir;

  static const _primary = Color(0xFF0EA5E9);

  const RingkasanNilaiCard({
    super.key,
    required this.rataMateri,
    required this.rataPraktikum,
    required this.nilaiAkhir,
  });

  Color get _nilaiColor {
    if (nilaiAkhir >= 80) return const Color(0xFF059669);
    if (nilaiAkhir >= 60) return const Color(0xFFD97706);
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          const Text(
            'Ringkasan Nilai',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: Color(0xFF1A1F36),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _item(
                  'Rata-rata Teori',
                  rataMateri.toStringAsFixed(1),
                  '(Bobot 30%)',
                  _primary,
                  const Color(0xFFE0F2FE),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _item(
                  'Rata-rata Praktikum',
                  rataPraktikum.toStringAsFixed(1),
                  '(Bobot 70%)',
                  const Color(0xFFD97706),
                  const Color(0xFFFEF3E0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _item(
                  'Nilai Akhir',
                  nilaiAkhir.toStringAsFixed(1),
                  '(40% tugas)',
                  _nilaiColor,
                  _nilaiColor.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String label, String nilai, String sub, Color color, Color bg) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            nilai,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1A1F36),
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            sub,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
