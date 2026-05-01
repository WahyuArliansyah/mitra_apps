import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'detail_mapping_guru_view.dart';

class KelolaMapingGuruView extends StatefulWidget {
  const KelolaMapingGuruView({super.key});

  @override
  State<KelolaMapingGuruView> createState() => _KelolaMapingGuruViewState();
}

class _KelolaMapingGuruViewState extends State<KelolaMapingGuruView> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _listGuru = [];
  List<Map<String, dynamic>> _filtered = [];
  final _searchCtrl = TextEditingController();
  bool _isLoading = true;

  static const _primary = Color(0xFF7C3AED);
  static const _bg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();
    _ambilGuru();
  }

  Future<void> _ambilGuru() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('guru')
          .select('id_guru, nama_lengkap, nip, email')
          .order('nama_lengkap', ascending: true);
      setState(() {
        _listGuru = List<Map<String, dynamic>>.from(data);
        _filtered = _listGuru;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _cari(String keyword) {
    setState(() {
      _filtered = _listGuru.where((g) {
        final nama = g['nama_lengkap'].toString().toLowerCase();
        final nip = (g['nip'] ?? '').toString().toLowerCase();
        return nama.contains(keyword.toLowerCase()) ||
            nip.contains(keyword.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text(
          'Kelola Penugasan Guru',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _ambilGuru,
        color: _primary,
        child: Column(
          children: [
            // Search bar
            Container(
              color: _primary,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: TextField(
                controller: _searchCtrl,
                onChanged: _cari,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Cari nama atau NIP...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.15),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            // List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: _primary),
                    )
                  : _filtered.isEmpty
                  ? const Center(child: Text('Data guru tidak ditemukan'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filtered.length,
                      itemBuilder: (ctx, i) {
                        final guru = _filtered[i];
                        return _buildCard(guru);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> guru) {
    final nama = guru['nama_lengkap'] ?? '-';
    final nip = guru['nip'] ?? 'NIP tidak tersedia';
    final inisial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: _primary.withOpacity(0.1),
          child: Text(
            inisial,
            style: const TextStyle(
              color: _primary,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        title: Text(
          nama,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          nip,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Atur Tugas',
            style: TextStyle(
              color: _primary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DetailMappingGuruView(idGuru: guru['id_guru'], namaGuru: nama),
          ),
        ).then((_) => _ambilGuru()),
      ),
    );
  }
}
