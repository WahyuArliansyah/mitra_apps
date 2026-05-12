import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk menyimpan & mengambil status baca tugas/materi
/// menggunakan SharedPreferences agar persisten antar sesi
class ReadStatusService {
  final String idSiswa;

  ReadStatusService({required this.idSiswa});

  String get _keyTugas => 'read_tugas_$idSiswa';
  String get _keyMateri => 'read_materi_$idSiswa';

  /// Ambil semua ID tugas yang sudah dibaca
  Future<Set<String>> getReadTugasIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyTugas) ?? []).toSet();
  }

  /// Ambil semua ID materi yang sudah dibaca
  Future<Set<String>> getReadMateriIds() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getStringList(_keyMateri) ?? []).toSet();
  }

  /// Tandai tugas sebagai sudah dibaca
  Future<void> markTugasAsRead(String idTugas, Set<String> currentIds) async {
    if (currentIds.contains(idTugas)) return;
    final prefs = await SharedPreferences.getInstance();
    currentIds.add(idTugas);
    await prefs.setStringList(_keyTugas, currentIds.toList());
  }

  /// Tandai materi sebagai sudah dibaca
  Future<void> markMateriAsRead(String idMateri, Set<String> currentIds) async {
    if (currentIds.contains(idMateri)) return;
    final prefs = await SharedPreferences.getInstance();
    currentIds.add(idMateri);
    await prefs.setStringList(_keyMateri, currentIds.toList());
  }
}
