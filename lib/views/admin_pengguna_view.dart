import 'package:flutter/material.dart';
import 'package:mitra_apps/views/login_view.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPenggunaView extends StatefulWidget {
  const AdminPenggunaView({super.key});

  @override
  State<AdminPenggunaView> createState() => _AdminPenggunaViewState();
}

class _AdminPenggunaViewState extends State<AdminPenggunaView> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _listPengguna = [];
  List<Map<String, dynamic>> _filteredPengguna = [];
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String _peranTerpilih = 'Semua';

  @override
  void initState() {
    super.initState();
    _ambilDataPengguna();
  }

  Future<void> _ambilDataPengguna() async {
    try {
      final data = await supabase
          .from('pengguna')
          .select('*, kelas(nama_kelas)')
          .order('nama_lengkap', ascending: true);

      if (mounted) {
        setState(() {
          _listPengguna = List<Map<String, dynamic>>.from(data);
          _filteredPengguna = _listPengguna;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _jalankanFilter(String keyword, String peran) {
    setState(() {
      _peranTerpilih = peran;
      _filteredPengguna = _listPengguna.where((u) {
        final namaMatch = u['nama_lengkap'].toString().toLowerCase().contains(
          keyword.toLowerCase(),
        );
        final nimMatch = u['nim_nuptk'].toString().toLowerCase().contains(
          keyword.toLowerCase(),
        );
        final peranMatch =
            peran == 'Semua' ||
            u['peran'].toString().toLowerCase() == peran.toLowerCase();
        return (namaMatch || nimMatch) && peranMatch;
      }).toList();
    });
  }

  Future<void> _logout() async {
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
    if (ok == true && mounted) {
      await supabase.auth.signOut();
      if (ok == true && mounted) {
        await supabase.auth.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB), // Warna background dashboard
      body: RefreshIndicator(
        onRefresh: () async {
          await _ambilDataPengguna();
        },
        color: const Color(0xFF4E73DF),
        child: CustomScrollView(
          slivers: [
            // SliverAppBar agar seragam dengan dashboard
            SliverAppBar(
              expandedHeight: 100,
              pinned: true,
              backgroundColor: const Color(0xFF4E73DF),
              automaticallyImplyLeading: false,
              // Kita hilangkan title standar agar tidak mengganggu posisi tengah flexibleSpace
              title: null,

              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF6C8EF5), Color(0xFF3A5BD9)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  // Gunakan Center dan Padding agar berada di tengah body biru
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment
                            .spaceBetween, // Memisahkan judul dan tombol
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // Menyejajarkan secara vertikal ke tengah
                        children: [
                          const Text(
                            'Kelola Pengguna',
                            style: TextStyle(
                              fontSize: 25, // Sedikit lebih besar agar tegas
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          // Bungkus IconButton agar sejajar sempurna
                          Container(
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
                                Icon(
                                  Icons.logout_rounded,
                                  color: Colors.white,
                                  size: 15,
                                ),
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
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Konten Filter dan Search
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search Field lebih clean
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (val) =>
                            _jalankanFilter(val, _peranTerpilih),
                        decoration: const InputDecoration(
                          hintText: 'Cari Nama atau NIM/NUPTK...',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Color(0xFF4E73DF),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 15),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Peran Filter Chip
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: ['Semua', 'Admin', 'Guru', 'Siswa'].map((p) {
                          final isSelected = _peranTerpilih == p;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(p),
                              selected: isSelected,
                              onSelected: (val) =>
                                  _jalankanFilter(_searchController.text, p),
                              selectedColor: const Color(0xFF4E73DF),
                              labelStyle: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // List Pengguna
            _isLoading
                ? const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final user = _filteredPengguna[index];
                        bool hasToken =
                            user['fcm_token'] != null &&
                            user['fcm_token'].toString().isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.all(12),
                            leading: CircleAvatar(
                              radius: 25,
                              backgroundImage: user['foto_profil'] != null
                                  ? NetworkImage(user['foto_profil'])
                                  : null,
                              child: user['foto_profil'] == null
                                  ? const Icon(Icons.person, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(
                              user['nama_lengkap'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${user['nim_nuptk']} • ${user['peran'].toString().toUpperCase()}",
                                ),
                                if (user['id_kelas'] != null)
                                  Text(
                                    "Kelas: ${user['kelas']?['nama_kelas'] ?? 'N/A'}",
                                  ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      hasToken
                                          ? Icons.notifications_active
                                          : Icons.notifications_off,
                                      size: 14,
                                      color: hasToken
                                          ? Colors.green
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasToken
                                          ? "Notifikasi Aktif"
                                          : "Notifikasi Mati",
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: hasToken
                                            ? Colors.green
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }, childCount: _filteredPengguna.length),
                    ),
                  ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ), // Spasi bawah agar tidak tertutup nav bar
          ],
        ),
      ),
    );
  }
}
