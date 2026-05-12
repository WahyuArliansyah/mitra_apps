import 'package:flutter/material.dart';

/// Model info visual badge status pengumpulan tugas
class StatusInfo {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final Color stripColor;

  const StatusInfo({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.stripColor,
  });

  /// Factory untuk menentukan status berdasarkan kondisi pengumpulan
  factory StatusInfo.from({
    required bool sudahKumpul,
    required String? statusKumpul,
    required bool isPassed,
  }) {
    const primary = Color(0xFF0EA5E9);

    if (!sudahKumpul) {
      if (isPassed) {
        return StatusInfo(
          label: 'Tidak Dikumpulkan',
          icon: Icons.cancel_rounded,
          color: Colors.redAccent,
          bgColor: const Color(0xFFFFEDED),
          stripColor: Colors.redAccent,
        );
      }
      return const StatusInfo(
        label: 'Belum Dikumpulkan',
        icon: Icons.radio_button_unchecked_rounded,
        color: Color(0xFF6B7280),
        bgColor: Color(0xFFF3F4F6),
        stripColor: Color(0xFFD1D5DB),
      );
    }

    switch (statusKumpul) {
      case 'dinilai':
        return const StatusInfo(
          label: 'Sudah Dinilai',
          icon: Icons.verified_rounded,
          color: Color(0xFF059669),
          bgColor: Color(0xFFE6FAF5),
          stripColor: Color(0xFF059669),
        );
      case 'terlambat':
        return const StatusInfo(
          label: 'Terlambat Dikumpulkan',
          icon: Icons.warning_rounded,
          color: Color(0xFFD97706),
          bgColor: Color(0xFFFEF3E0),
          stripColor: Color(0xFFD97706),
        );
      default:
        return const StatusInfo(
          label: 'Menunggu Penilaian',
          icon: Icons.hourglass_top_rounded,
          color: primary,
          bgColor: Color(0xFFE0F2FE),
          stripColor: primary,
        );
    }
  }
}
