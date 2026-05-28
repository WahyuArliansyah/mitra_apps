import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminMapelView extends StatefulWidget {
  const AdminMapelView({super.key});

  @override
  State<AdminMapelView> createState() => _AdminMapelViewState();
}

class _AdminMapelViewState extends State<AdminMapelView> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _listMapel = [];
  List<Map<String, dynamic>> _filteredListMapel = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  static const _primary = Color(0xFF059669);
  static const _bgColor = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _ambilDataMapel();
  }

  // ── Data ────────────────────────────────────────────────
  Future<void> _ambilDataMapel() async {
    try {
      final data = await supabase
          .from('mata_pelajaran')
          .select()
          .order('nama_mapel', ascending: true);
      setState(() {
        _listMapel = List<Map<String, dynamic>>.from(data);
        _filteredListMapel = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showSnackbar('Error: $e', isError: true);
    }
  }

  void _jalankanPencarian(String keyword) {
    setState(() {
      _filteredListMapel = keyword.isEmpty
          ? _listMapel
          : _listMapel.where((m) {
              return m['nama_mapel'].toString().toLowerCase().contains(
                    keyword.toLowerCase(),
                  ) ||
                  m['kode_mapel'].toString().toLowerCase().contains(
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
        backgroundColor: isError ? Colors.redAccent : _primary,
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

  // ── Dialog Form ─────────────────────────────────────────
  void _tampilkanDialogForm({Map<String, dynamic>? mapel}) {
    final isEdit = mapel != null;
    final namaCtrl = TextEditingController(text: mapel?['nama_mapel'] ?? '');
    final kodeCtrl = TextEditingController(text: mapel?['kode_mapel'] ?? '');

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
            isEdit ? 'Edit Mata Pelajaran' : 'Tambah Mata Pelajaran',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _inputField(
                  kodeCtrl,
                  'Kode Mapel',
                  'Contoh: MTK-01',
                  Icons.qr_code_rounded,
                  onChanged: (_) => setStateDialog(() {}),
                ),
                const SizedBox(height: 16),
                _inputField(
                  namaCtrl,
                  'Nama Mata Pelajaran',
                  'Contoh: Matematika',
                  Icons.menu_book_rounded,
                  onChanged: (_) => setStateDialog(() {}),
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
              onPressed:
                  kodeCtrl.text.trim().isEmpty || namaCtrl.text.trim().isEmpty
                  ? null
                  : () async {
                      try {
                        // Cek duplikat kode (hanya tambah baru atau kode diubah)
                        if (!isEdit ||
                            kodeCtrl.text.trim() != mapel!['kode_mapel']) {
                          final cek = await supabase
                              .from('mata_pelajaran')
                              .select('id')
                              .ilike('kode_mapel', kodeCtrl.text.trim());
                          if (cek.isNotEmpty) {
                            if (mounted)
                              _showSnackbar(
                                'Kode mapel sudah terdaftar!',
                                isError: true,
                              );
                            return;
                          }
                        }
                        final data = {
                          'nama_mapel': namaCtrl.text.trim(),
                          'kode_mapel': kodeCtrl.text.trim(),
                        };
                        if (isEdit) {
                          await supabase
                              .from('mata_pelajaran')
                              .update(data)
                              .eq('id', mapel!['id']);
                        } else {
                          await supabase.from('mata_pelajaran').insert(data);
                        }
                        if (mounted) {
                          Navigator.pop(ctx);
                          _ambilDataMapel();
                          _showSnackbar(
                            isEdit
                                ? 'Data berhasil diperbarui.'
                                : 'Mapel berhasil ditambahkan.',
                          );
                        }
                      } catch (e) {
                        if (mounted) _showSnackbar('Error: $e', isError: true);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    kodeCtrl.text.trim().isEmpty || namaCtrl.text.trim().isEmpty
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
          'Mata Pelajaran',
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
        onPressed: () => _tampilkanDialogForm(),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Tambah Mapel',
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
          hintText: 'Cari nama atau kode mapel...',
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
    if (_filteredListMapel.isEmpty) {
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
              'Data mata pelajaran tidak ditemukan.',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _filteredListMapel.length,
      itemBuilder: (ctx, i) => _buildMapelCard(_filteredListMapel[i]),
    );
  }

  Widget _buildMapelCard(Map<String, dynamic> mapel) {
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
            color: const Color(0xFFE6FAF5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.menu_book_rounded, color: _primary, size: 22),
        ),
        title: Text(
          mapel['nama_mapel'],
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1A1F36),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FAF5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  mapel['kode_mapel'],
                  style: const TextStyle(
                    fontSize: 11,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBtn(
              Icons.edit_rounded,
              const Color(0xFF4E73DF),
              const Color(0xFFEEF2FF),
              () => _tampilkanDialogForm(mapel: mapel),
            ),
            const SizedBox(width: 6),
            _actionBtn(
              Icons.delete_rounded,
              Colors.redAccent,
              const Color(0xFFFFEEEE),
              () async {
                final yakin = await _konfirmasiHapus();
                if (yakin && mounted) {
                  await supabase
                      .from('mata_pelajaran')
                      .delete()
                      .eq('id', mapel['id']);
                  _ambilDataMapel();
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
