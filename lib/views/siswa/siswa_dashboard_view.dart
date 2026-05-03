import 'package:flutter/material.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class SiswaDashboardView extends StatefulWidget {
  final String idSiswa; // Butuh ID Siswa untuk memfilter notifikasi

  const SiswaDashboardView({super.key, required this.idSiswa});

  @override
  State<SiswaDashboardView> createState() => _SiswaDashboardViewState();
}

class _SiswaDashboardViewState extends State<SiswaDashboardView> {
  final supabase = Supabase.instance.client;
  static const _primary = Color(0xFF0EA5E9);
  static const _bg = Color(0xFFF4F6FB);

  List<Map<String, dynamic>> _listNotifikasi = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _ambilNotifikasi();
  }

  Future<void> _ambilNotifikasi() async {
    if (widget.idSiswa.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Mengambil data dari tabel 'notifikasi' milik siswa ini
      final data = await supabase
          .from('notifikasi')
          .select()
          .eq('id_siswa', widget.idSiswa)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        _listNotifikasi = List<Map<String, dynamic>>.from(data);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error ambil notifikasi: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  // Fungsi untuk memformat tanggal (misal: 24 Des 2026, 14:30)
  String _formatTanggal(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final date = DateTime.parse(isoDate).toLocal();
      return DateFormat('dd MMM yyyy, HH:mm').format(date);
    } catch (e) {
      return isoDate;
    }
  }

  Future<void> _logout(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Logout'),
        content: const Text('Yakin ingin keluar dari akun ini?'),
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
            child: const Text('Logout', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Notifikasi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () => _logout(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.logout_rounded, color: Colors.white, size: 15),
                    SizedBox(width: 5),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _ambilNotifikasi,
        color: _primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : _listNotifikasi.isEmpty
            ? _buildKosong()
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: _listNotifikasi.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final notif = _listNotifikasi[index];
                  // Ngecek apakah notif belum dibaca (opsional, default true supaya putih)
                  final isRead = notif['is_read'] ?? true;

                  return _buildKartuNotifikasi(notif, isRead);
                },
              ),
      ),
    );
  }

  Widget _buildKartuNotifikasi(Map<String, dynamic> notif, bool isRead) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // Jika belum dibaca warnanya sedikit biru, jika sudah putih polos
        color: isRead ? Colors.white : const Color(0xFFE0F2FE).withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isRead ? Colors.grey.shade200 : _primary.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ikon Lonceng
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.notifications_active_rounded,
              color: _primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Isi Notifikasi
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  notif['judul'] ?? 'Informasi Baru',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1F36),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  notif['pesan'] ?? '',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTanggal(notif['created_at']),
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
              ],
            ),
          ),
          // Titik merah penanda belum dibaca
          if (!isRead)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: CircleAvatar(radius: 4, backgroundColor: Colors.redAccent),
            ),
        ],
      ),
    );
  }

  Widget _buildKosong() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_off_rounded,
                size: 80,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada notifikasi',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Notifikasi tugas atau materi baru\nakan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
