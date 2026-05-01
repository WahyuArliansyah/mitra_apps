import 'package:flutter/material.dart';
import 'package:mitra_apps/models/guru_model.dart';
import 'package:mitra_apps/services/guru_service.dart';
import 'package:uuid/uuid.dart';

class KelolaGuruView extends StatefulWidget {
  const KelolaGuruView({super.key});

  @override
  State<KelolaGuruView> createState() => _KelolaGuruViewState();
}

class _KelolaGuruViewState extends State<KelolaGuruView> {
  final GuruService _guruService = GuruService();
  final TextEditingController _searchController = TextEditingController();

  List<GuruModel> _listGuru = [];
  List<GuruModel> _filteredListGuru = [];
  bool _isLoading = true;

  static const _primary = Color(0xFFDC2626);
  static const _bgColor = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _ambilDataGuru();
  }

  // Mengammbil data guru
  Future<void> _ambilDataGuru() async {
    setState(() => _isLoading = true);
    final data = await _guruService.getSemuaGuru();
    if (!mounted) return;
    setState(() {
      _listGuru = data;
      _filteredListGuru = data;
      _isLoading = false;
    });
  }

  void _jalankanPencarian(String keyword) {
    setState(() {
      _filteredListGuru = _listGuru.where((g) {
        final nama = g.namaLengkap.toLowerCase();
        final nip = (g.nip ?? '').toLowerCase();
        final email = g.email.toLowerCase();
        final cari = keyword.toLowerCase();
        return nama.contains(cari) ||
            nip.contains(cari) ||
            email.contains(cari);
      }).toList();
    });
  }

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

  // tampilin form guru (buat tambah & edit)
  void _tampilkanForm({GuruModel? guru}) {
    final isEdit = guru != null;
    final nipCtrl = TextEditingController(text: guru?.nip ?? '');
    final namaCtrl = TextEditingController(text: guru?.namaLengkap ?? '');
    final emailCtrl = TextEditingController(text: guru?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        // Mengatur lebar pop-up agar lebih besar
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        title: Text(isEdit ? 'Edit Data Guru' : 'Tambah Guru Baru'),
        content: SizedBox(
          // Memaksa lebar maksimal agar pop-up terlihat luas
          width: MediaQuery.of(context).size.width * 0.9,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                _buildTextField(nipCtrl, 'NIP / NUPTK', Icons.badge_rounded),
                const SizedBox(height: 20),
                _buildTextField(namaCtrl, 'Nama Lengkap', Icons.person_rounded),
                const SizedBox(height: 20),
                _buildTextField(
                  emailCtrl,
                  'Email Aktif',
                  Icons.email_rounded,
                  type: TextInputType.emailAddress,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 8),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                if (namaCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                  _showSnackbar('Nama dan Email wajib diisi!', isError: true);
                  return;
                }

                // mengecek data duplikat sebelum simpan
                if (!isEdit) {
                  final duplikat = await _guruService.cekDataDuplikat(
                    nipCtrl.text,
                    namaCtrl.text,
                    emailCtrl.text,
                  );

                  if (duplikat != null) {
                    _showSnackbar('$duplikat sudah terdaftar!', isError: true);
                    return;
                  }
                }
                Navigator.pop(ctx);

                bool sukses;
                if (isEdit) {
                  sukses = await _guruService.updateGuru(guru.idGuru!, {
                    'nip': nipCtrl.text,
                    'nama_lengkap': namaCtrl.text,
                    'email': emailCtrl.text,
                  });
                } else {
                  final id = const Uuid().v4();
                  sukses = await _guruService.tambahGuru(
                    GuruModel(
                      idGuru: id,
                      userId: id, // user_id tetap sinkron[cite: 1, 3]
                      nip: nipCtrl.text,
                      namaLengkap: namaCtrl.text,
                      email: emailCtrl.text,
                    ),
                  );
                }
                _ambilDataGuru();
                _showSnackbar(
                  sukses ? 'Berhasil disimpan' : 'Gagal menyimpan',
                  isError: !sukses,
                );
              },
              child: const Text('Simpan Data'),
            ),
          ),
        ],
      ),
    );
  }

  // ── UTAMA (BUILD) ──
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Kelola Guru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: _primary,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: TextField(
              controller: _searchController,
              onChanged: _jalankanPencarian,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cari nama atau NIP...',
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          // List Data
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: _primary),
                  )
                : _filteredListGuru.isEmpty
                ? const Center(child: Text('Data tidak ditemukan'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredListGuru.length,
                    itemBuilder: (ctx, i) => _buildCard(_filteredListGuru[i]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _tampilkanForm(),
        backgroundColor: _primary,
        label: const Text(
          'Tambah Guru',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCard(GuruModel guru) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: _primary.withOpacity(0.1),
          child: Text(
            guru.namaLengkap.isNotEmpty
                ? guru.namaLengkap[0].toUpperCase()
                : '?',
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          guru.namaLengkap,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              guru.nip ?? 'NIP tidak tersedia',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            Text(
              guru.email,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
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
              onPressed: () => _tampilkanForm(guru: guru),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
              ),
              onPressed: () async {
                // ✅ Dialog konfirmasi sebelum hapus
                final konfirmasi = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Text('Hapus Guru'),
                    content: Text(
                      'Yakin ingin menghapus "${guru.namaLengkap}"?\nData akun pengguna juga akan ikut terhapus.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Batal'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Hapus',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );

                if (konfirmasi != true) return;

                final sukses = await _guruService.hapusGuru(guru.idGuru!);
                if (sukses) {
                  _ambilDataGuru();
                  _showSnackbar('${guru.namaLengkap} berhasil dihapus');
                } else {
                  _showSnackbar('Gagal menghapus guru', isError: true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 14),
        prefixIcon: Icon(icon, color: _primary),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }
}
