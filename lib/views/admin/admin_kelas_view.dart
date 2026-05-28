import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminKelasView extends StatefulWidget {
  const AdminKelasView({super.key});

  @override
  State<AdminKelasView> createState() => _AdminKelasViewState();
}

class _AdminKelasViewState extends State<AdminKelasView> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _listKelas = [];
  List<Map<String, dynamic>> _filteredListKelas = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  // ── Warna tema ──────────────────────────────────────────
  static const _primary = Color(0xFF4E73DF);
  static const _bgColor = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _ambilDataKelas();
  }

  // ── Data ────────────────────────────────────────────────
  Future<void> _ambilDataKelas() async {
    try {
      final data = await supabase
          .from('kelas')
          .select()
          .order('nama_kelas', ascending: true);
      setState(() {
        _listKelas = List<Map<String, dynamic>>.from(data);
        _filteredListKelas = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showSnackbar('Error: $e', isError: true);
    }
  }

  void _jalankanPencarian(String keyword) {
    setState(() {
      _filteredListKelas = keyword.isEmpty
          ? _listKelas
          : _listKelas.where((k) {
              return k['nama_kelas'].toString().toLowerCase().contains(
                    keyword.toLowerCase(),
                  ) ||
                  k['jurusan'].toString().toLowerCase().contains(
                    keyword.toLowerCase(),
                  );
            }).toList();
    });
  }

  // ── Helpers ─────────────────────────────────────────────
  void _showSnackbar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future<bool> _konfirmasiHapus() async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.red),
                SizedBox(width: 8),
                Text('Hapus Data?', style: TextStyle(fontSize: 16)),
              ],
            ),
            content: const Text('Data yang dihapus tidak dapat dikembalikan.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  // Digunakan untuk menampilkan form tambah/edit kelas.
  void _tampilkanForm({Map<String, dynamic>? kelas}) {
    final isEdit = kelas != null;
    final namaCtrl = TextEditingController(text: kelas?['nama_kelas'] ?? '');
    final jurusanCtrl = TextEditingController(text: kelas?['jurusan'] ?? '');

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          title: Text(
            isEdit ? 'Edit Data Kelas' : 'Tambah Kelas Baru',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _inputField(
                  namaCtrl,
                  'Nama Kelas',
                  'Contoh: XII TKJ 1',
                  Icons.class_outlined,
                  onChanged: (_) => setStateDialog(() {}), // ← tambah
                ),
                const SizedBox(height: 16),
                _inputField(
                  jurusanCtrl,
                  'Jurusan',
                  'Contoh: Teknik Komputer Jaringan',
                  Icons.account_tree_outlined,
                  onChanged: (_) => setStateDialog(() {}), // ← tambah
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              // ← disabled jika ada field yang kosong
              onPressed:
                  namaCtrl.text.trim().isEmpty ||
                      jurusanCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      try {
                        if (!isEdit) {
                          final cek = await supabase
                              .from('kelas')
                              .select('id')
                              .ilike('nama_kelas', namaCtrl.text.trim());
                          if (cek.isNotEmpty) {
                            if (mounted)
                              _showSnackbar(
                                'Nama kelas sudah terdaftar!',
                                isError: true,
                              );
                            return;
                          }
                          await supabase.from('kelas').insert({
                            'nama_kelas': namaCtrl.text.trim(),
                            'jurusan': jurusanCtrl.text.trim(),
                          });
                        } else {
                          await supabase
                              .from('kelas')
                              .update({
                                'nama_kelas': namaCtrl.text.trim(),
                                'jurusan': jurusanCtrl.text.trim(),
                              })
                              .eq('id', kelas!['id']);
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          _ambilDataKelas();
                          _showSnackbar(
                            isEdit
                                ? 'Data berhasil diperbarui.'
                                : 'Kelas berhasil ditambahkan.',
                          );
                        }
                      } catch (e) {
                        if (mounted) _showSnackbar('Error: $e', isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    namaCtrl.text.trim().isEmpty ||
                        jurusanCtrl.text.trim().isEmpty
                    ? Colors
                          .grey
                          .shade400 // ← abu-abu jika belum lengkap
                    : _primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: ctrl,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 14,
          horizontal: 12,
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Data Kelas',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilkanForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Kelas',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: _primary,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: TextField(
        controller: _searchController,
        onChanged: _jalankanPencarian,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Cari nama kelas atau jurusan...',
          hintStyle: const TextStyle(color: Colors.white60),
          prefixIcon: const Icon(Icons.search_rounded, color: Colors.white70),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white70),
                  onPressed: () {
                    _searchController.clear();
                    _jalankanPencarian('');
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white.withOpacity(0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading)
      return const Center(child: CircularProgressIndicator(color: _primary));
    if (_filteredListKelas.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 60,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 12),
            Text(
              'Data kelas tidak ditemukan.',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _filteredListKelas.length,
      itemBuilder: (ctx, i) => _buildKelasCard(_filteredListKelas[i]),
    );
  }

  Widget _buildKelasCard(Map<String, dynamic> kelas) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFEEF2FF),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.class_rounded, color: _primary, size: 22),
        ),
        title: Text(
          kelas['nama_kelas'],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1A1F36),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            kelas['jurusan'],
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBtn(
              Icons.edit_rounded,
              const Color(0xFF4E73DF),
              const Color(0xFFEEF2FF),
              () => _tampilkanForm(kelas: kelas),
            ),
            const SizedBox(width: 6),
            _actionBtn(
              Icons.delete_rounded,
              Colors.redAccent,
              const Color(0xFFFFEEEE),
              () async {
                final yakin = await _konfirmasiHapus();
                if (yakin && mounted) {
                  await supabase.from('kelas').delete().eq('id', kelas['id']);
                  _ambilDataKelas();
                  _showSnackbar('Data berhasil dihapus.');
                }
              },
            ),
          ],
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
