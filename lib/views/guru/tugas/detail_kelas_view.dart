import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DetailKelasView extends StatefulWidget {
  final String idGuru;
  final String idKelas;
  final String idMapel;
  final String namaKelas;
  final String namaMapel;

  const DetailKelasView({
    super.key,
    required this.idGuru,
    required this.idKelas,
    required this.idMapel,
    required this.namaKelas,
    required this.namaMapel,
  });

  @override
  State<DetailKelasView> createState() => _DetailKelasViewState();
}

class _DetailKelasViewState extends State<DetailKelasView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  List<Map<String, dynamic>> _listSiswa = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ambilSiswa();
  }

  Future<void> _ambilSiswa() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('siswa')
          .select('id_siswa, nama_siswa, nis')
          .eq('id_kelas', widget.idKelas)
          .order('nama_siswa', ascending: true);

      if (!mounted) return;
      setState(() {
        _listSiswa = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.namaKelas,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              widget.namaMapel,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _ambilSiswa,
        color: _primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _listSiswa.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 60,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada siswa di kelas ini',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _listSiswa.length,
                itemBuilder: (ctx, i) {
                  final siswa = _listSiswa[i];
                  final inisial = siswa['nama_siswa'].toString().isNotEmpty
                      ? siswa['nama_siswa']
                            .toString()
                            .trim()
                            .split(' ')
                            .map((e) => e[0])
                            .take(2)
                            .join()
                      : '?';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: const Color(0xFFE0F2FE),
                          child: Text(
                            inisial.toUpperCase(),
                            style: const TextStyle(
                              color: _primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                siswa['nama_siswa'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                siswa['nis'] ?? '-',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Badge nomor urut
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
