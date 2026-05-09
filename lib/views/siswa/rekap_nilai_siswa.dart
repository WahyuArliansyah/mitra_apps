import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:mitra_apps/widgets/siswa_app_bar.dart';

class RekapNilaiSiswa extends StatefulWidget {
  final String idSiswa;
  final String namaSiswa;
  final String idKelas;
  final String idMapel;
  final String semester;
  final String tahunAjaran;

  const RekapNilaiSiswa({
    super.key,
    required this.idSiswa,
    required this.namaSiswa,
    required this.idKelas,
    required this.idMapel,
    required this.semester,
    required this.tahunAjaran,
  });

  @override
  State<RekapNilaiSiswa> createState() => _RekapNilaiSiswaState();
}

class _RekapNilaiSiswaState extends State<RekapNilaiSiswa> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  List<Map<String, dynamic>> _historyNilai = [];

  // Variabel penampung hasil RPC sesuai routine_definition database
  double _rataMateri = 0.0;
  double _rataPraktikum = 0.0;
  double _nilaiTugasGabungan = 0.0; // Hasil 70:30
  double _kontribusiNilaiAkhir = 0.0; // Hasil * 0.40

  @override
  void initState() {
    super.initState();
    _loadDataRekap();
  }

  Future<void> _loadDataRekap() async {
    try {
      setState(() => _isLoading = true);

      // 1. Memanggil RPC dengan 5 parameter sesuai dokumentasi Data API kamu
      final responseRpc = await supabase.rpc(
        'hitung_nilai_akhir',
        params: {
          'p_id_siswa': widget.idSiswa,
          'p_id_kelas': widget.idKelas,
          'p_id_mapel': widget.idMapel,
          'p_semester': widget.semester,
          'p_tahun_ajaran': widget.tahunAjaran,
        },
      );

      // 2. Ambil data history untuk list di bawah
      final responseHistory = await supabase
          .from('nilai')
          .select('*, tugas!inner(*)') // Join ke tabel tugas untuk filter
          .eq('id_siswa', widget.idSiswa)
          .eq('tugas.id_kelas', widget.idKelas)
          .eq('tugas.id_mapel', widget.idMapel)
          .order('dinilai_at', ascending: true);

      setState(() {
        if (responseRpc != null &&
            responseRpc is List &&
            responseRpc.isNotEmpty) {
          final data = responseRpc[0];
          // Mapping sesuai urutan RETURN QUERY di RPC kamu
          _rataMateri =
              double.tryParse(data['v_rata_materi'].toString()) ?? 0.0;
          _rataPraktikum =
              double.tryParse(data['v_rata_praktikum'].toString()) ?? 0.0;
          _nilaiTugasGabungan =
              double.tryParse(data['v_nilai_tugas'].toString()) ?? 0.0;
          _kontribusiNilaiAkhir =
              double.tryParse(data['v_nilai_akhir'].toString()) ?? 0.0;
        }
        _historyNilai = List<Map<String, dynamic>>.from(responseHistory);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error Load Rekap: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: SiswaAppBar(namaSiswa: widget.namaSiswa),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDataRekap,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    _buildCardUtama(),
                    _buildSectionTitle("Detail Kategori"),
                    _buildKategoriRow(),
                    _buildSectionTitle("Riwayat Tugas"),
                    _buildListHistory(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCardUtama() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "Rata-Rata Tugas Gabungan",
            style: TextStyle(color: Colors.white70),
          ),
          Text(
            _nilaiTugasGabungan.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 52,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Divider(color: Colors.white24, height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.info_outline, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                "Kontribusi ke Nilai Rapor (40%): ${_kontribusiNilaiAkhir.toStringAsFixed(1)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildKategoriCard("Materi (30%)", _rataMateri, Colors.orange),
          const SizedBox(width: 12),
          _buildKategoriCard("Praktikum (70%)", _rataPraktikum, Colors.green),
        ],
      ),
    );
  }

  Widget _buildKategoriCard(String label, double nilai, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              nilai.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
      ),
    );
  }

  Widget _buildListHistory() {
    if (_historyNilai.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Text("Belum ada riwayat nilai."),
      );
    }
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _historyNilai.length,
      itemBuilder: (context, index) {
        final item = _historyNilai[index];
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ListTile(
            leading: Icon(
              item['tugas']['type_tugas'] == 'praktikum'
                  ? Icons.code
                  : Icons.menu_book,
              color: Colors.blue.shade300,
            ),
            title: Text(
              item['tugas']['judul_tugas'] ?? 'Tugas',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            trailing: Text(
              "${double.parse(item['nilai'].toString()).toStringAsFixed(0)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF0EA5E9),
                fontSize: 16,
              ),
            ),
          ),
        );
      },
    );
  }
}
