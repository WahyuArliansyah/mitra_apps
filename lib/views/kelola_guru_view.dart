import 'package:flutter/material.dart';
import 'package:mitra_apps/models/guru_model.dart';
import 'package:mitra_apps/services/guru_service.dart';

class KelolaGuruView extends StatefulWidget {
  const KelolaGuruView({super.key});

  @override
  State<KelolaGuruView> createState() => _KelolaGuruViewState();
}

class _KelolaGuruViewState extends State<KelolaGuruView> {
  final GuruService _guruService = GuruService();

  List<GuruModel> _listGuru = [];
  List<GuruModel> _filteredListGuru = [];
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  static const _primary = Color(0xFFDC2626);
  static const _bgColor = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _ambilDataGuru();
  }

  // ── Data ────────────────────────────────────────────────
  Future<void> _ambilDataGuru() async {
    setState(() => _isLoading = true);
    final data = await _guruService.getSemuaGuru();
    setState(() {
      _listGuru = data;
      _filteredListGuru = data;
      _isLoading = false;
    });
  }

  void _jalankanPencarian(String keyword) {
    setState(() {
      _filteredListGuru = keyword.isEmpty
          ? _listGuru
          : _listGuru.where((g) {
              return g.namaLengkap.toLowerCase().contains(
                    keyword.toLowerCase(),
                  ) ||
                  (g.nip?.toLowerCase().contains(keyword.toLowerCase()) ??
                      false) ||
                  g.email.toLowerCase().contains(keyword.toLowerCase());
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

  Future<bool> _konfirmasiHapusDialog(String nama) async {
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
              'Data guru "$nama" akan dihapus dan tidak dapat dikembalikan.',
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

  // Simpan data guru baru atau update data guru lama
  void _tampilkanForm({GuruModel? guru}) {
    final isEdit = guru != null;
    final nipCtrl = TextEditingController(text: guru?.nip ?? '');
    final namaCtrl = TextEditingController(text: guru?.namaLengkap ?? '');
    final emailCtrl = TextEditingController(text: guru?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(
          isEdit ? 'Edit Data Guru' : 'Tambah Data Guru',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              _inputField(
                nipCtrl,
                'NIP / NUPTK',
                'Contoh: 198501012010011001',
                Icons.badge_rounded,
              ),
              const SizedBox(height: 16),
              _inputField(
                namaCtrl,
                'Nama Lengkap',
                'Contoh: Budi Santoso, S.Pd',
                Icons.person_rounded,
              ),
              const SizedBox(height: 16),
              _inputField(
                emailCtrl,
                'Email',
                'Contoh: budi@sekolah.sch.id',
                Icons.email_rounded,
                type: TextInputType.emailAddress,
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
              if (namaCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                _showSnackbar('Nama dan Email wajib diisi!', isError: true);
                return;
              }
              if (!isEdit) {
                final duplikat = await _guruService.cekDataDuplikat(
                  nipCtrl.text,
                  namaCtrl.text,
                  emailCtrl.text,
                );
                if (duplikat != null) {
                  if (mounted)
                    _showSnackbar('$duplikat sudah terdaftar!', isError: true);
                  return;
                }
                Navigator.pop(ctx);
                final sukses = await _guruService.tambahGuru(
                  GuruModel(
                    nip: nipCtrl.text,
                    namaLengkap: namaCtrl.text,
                    email: emailCtrl.text,
                  ),
                );
                if (mounted) {
                  _ambilDataGuru();
                  _showSnackbar(
                    sukses
                        ? 'Guru berhasil ditambahkan.'
                        : 'Gagal menyimpan data.',
                    isError: !sukses,
                  );
                }
              }
              // TODO: tambahkan logika edit jika GuruService sudah punya updateGuru()
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(isEdit ? 'Simpan Perubahan' : 'Simpan Data'),
          ),
        ],
      ),
    );
  }

  Widget _inputField(
    TextEditingController ctrl,
    String label,
    String hint,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
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
          'Data Guru',
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
          'Tambah Guru',
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
          hintText: 'Cari nama, NIP, atau email...',
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
    if (_filteredListGuru.isEmpty) {
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
              'Data guru tidak ditemukan.',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      itemCount: _filteredListGuru.length,
      itemBuilder: (ctx, i) => _buildGuruCard(_filteredListGuru[i]),
    );
  }

  Widget _buildGuruCard(GuruModel guru) {
    // Inisial nama untuk avatar
    final inisial = guru.namaLengkap.isNotEmpty
        ? guru.namaLengkap.trim().split(' ').map((e) => e[0]).take(2).join()
        : '?';

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
          backgroundColor: const Color(0xFFFFEEEE),
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
          guru.namaLengkap,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 14,
            color: Color(0xFF1A1F36),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (guru.nip != null && guru.nip!.isNotEmpty)
                Text(
                  'NIP: ${guru.nip}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              Text(
                guru.email,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
        isThreeLine: true,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _actionBtn(
              Icons.edit_rounded,
              const Color(0xFF4E73DF),
              const Color(0xFFEEF2FF),
              () => _tampilkanForm(guru: guru),
            ),
            const SizedBox(width: 6),
            _actionBtn(
              Icons.delete_rounded,
              Colors.redAccent,
              const Color(0xFFFFEEEE),
              () async {
                final yakin = await _konfirmasiHapusDialog(guru.namaLengkap);
                if (yakin && mounted) {
                  final sukses = await _guruService.hapusGuru(guru.idGuru!);
                  if (mounted) {
                    _ambilDataGuru();
                    _showSnackbar(
                      sukses
                          ? 'Data berhasil dihapus.'
                          : 'Gagal menghapus data.',
                      isError: !sukses,
                    );
                  }
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
