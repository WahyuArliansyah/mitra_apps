import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSiswaView extends StatefulWidget {
  const AdminSiswaView({super.key});

  @override
  State<AdminSiswaView> createState() => _AdminSiswaViewState();
}

class _AdminSiswaViewState extends State<AdminSiswaView> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _listSiswa = [];
  List<Map<String, dynamic>> _filteredListSiswa = [];
  List<Map<String, dynamic>> _listKelas = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  static const _primary = Color(0xFF4338CA);
  static const _bgColor = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _ambilDataSiswa();
    _ambilDataKelas();
  }

  // Mengambil Data Siswa beserta nama kelasnya dengan join tabel
  Future<void> _ambilDataSiswa() async {
    try {
      final data = await supabase
          .from('siswa')
          .select('*, kelas(nama_kelas)')
          .order('nama_siswa', ascending: true);
      setState(() {
        _listSiswa = List<Map<String, dynamic>>.from(data);
        _filteredListSiswa = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) _showSnackbar('Error: $e', isError: true);
    }
  }

  Future<void> _ambilDataKelas() async {
    final data = await supabase
        .from('kelas')
        .select('id, nama_kelas')
        .order('nama_kelas');
    setState(() => _listKelas = List<Map<String, dynamic>>.from(data));
  }

  void _jalankanPencarian(String keyword) {
    setState(() {
      _filteredListSiswa = keyword.isEmpty
          ? _listSiswa
          : _listSiswa.where((s) {
              return s['nama_siswa'].toString().toLowerCase().contains(
                    keyword.toLowerCase(),
                  ) ||
                  s['nis'].toString().toLowerCase().contains(
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

  Future<bool> _konfirmasiHapus(String nama) async {
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
            content: Text(
              'Data siswa "$nama" akan dihapus dan tidak dapat dikembalikan.',
            ),
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
  void _tampilkanDialogForm({Map<String, dynamic>? siswa}) {
    final isEdit = siswa != null;
    final nisCtrl = TextEditingController(text: siswa?['nis'] ?? '');
    final namaCtrl = TextEditingController(text: siswa?['nama_siswa'] ?? '');
    String? idKelasTerpilih = isEdit ? siswa['id_kelas']?.toString() : null;

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
            isEdit ? 'Edit Data Siswa' : 'Tambah Siswa Baru',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                _inputField(
                  nisCtrl,
                  'NIS / NISN',
                  'Contoh: 0012345678',
                  Icons.badge_rounded,
                ),
                const SizedBox(height: 16),
                _inputField(
                  namaCtrl,
                  'Nama Lengkap Siswa',
                  'Contoh: Andi Pratama',
                  Icons.person_rounded,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: idKelasTerpilih,
                  decoration: InputDecoration(
                    labelText: 'Pilih Kelas',
                    prefixIcon: const Icon(
                      Icons.class_rounded,
                      color: _primary,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primary, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 12,
                    ),
                  ),
                  items: _listKelas
                      .map(
                        (k) => DropdownMenuItem<String>(
                          value: k['id'].toString(),
                          child: Text(k['nama_kelas']),
                        ),
                      )
                      .toList(),
                  onChanged: (val) =>
                      setStateDialog(() => idKelasTerpilih = val),
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
              onPressed: () async {
                if (nisCtrl.text.isEmpty ||
                    namaCtrl.text.isEmpty ||
                    idKelasTerpilih == null) {
                  _showSnackbar('Semua field wajib diisi!', isError: true);
                  return;
                }
                final data = {
                  'nis': nisCtrl.text.trim(),
                  'nama_siswa': namaCtrl.text.trim(),
                  'id_kelas': idKelasTerpilih,
                };
                if (isEdit) {
                  await supabase
                      .from('siswa')
                      .update(data)
                      .eq('id_siswa', siswa!['id_siswa']);
                } else {
                  final cek = await supabase
                      .from('siswa')
                      .select('id_siswa')
                      .eq('nis', nisCtrl.text.trim());
                  if (cek.isNotEmpty) {
                    if (mounted)
                      _showSnackbar('NIS sudah digunakan!', isError: true);
                    return;
                  }
                  await supabase.from('siswa').insert(data);
                }
                if (mounted) {
                  Navigator.pop(ctx);
                  _ambilDataSiswa();
                  _showSnackbar(
                    isEdit
                        ? 'Data berhasil diperbarui.'
                        : 'Siswa berhasil ditambahkan.',
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
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
    IconData icon,
  ) {
    return TextField(
      controller: ctrl,
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
          'Data Siswa',
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
          'Tambah Siswa',
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
          hintText: 'Cari nama atau NIS...',
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
    if (_filteredListSiswa.isEmpty) {
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
              'Data siswa tidak ditemukan.',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _filteredListSiswa.length,
      itemBuilder: (ctx, i) => _buildSiswaCard(_filteredListSiswa[i]),
    );
  }

  Widget _buildSiswaCard(Map<String, dynamic> siswa) {
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
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
              // Badge NIS
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  siswa['nis'] ?? '-',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Badge Kelas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  namaKelas,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF059669),
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
              () => _tampilkanDialogForm(siswa: siswa),
            ),
            const SizedBox(width: 6),
            _actionBtn(
              Icons.delete_rounded,
              Colors.redAccent,
              const Color(0xFFFFEEEE),
              () async {
                final yakin = await _konfirmasiHapus(siswa['nama_siswa']);
                if (yakin && mounted) {
                  await supabase
                      .from('siswa')
                      .delete()
                      .eq('id_siswa', siswa['id_siswa']);
                  _ambilDataSiswa();
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
