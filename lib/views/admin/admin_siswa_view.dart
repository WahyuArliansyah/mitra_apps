import 'package:flutter/material.dart';
import 'package:mitra_apps/models/siswa_model.dart';
import 'package:mitra_apps/services/siswa_service.dart';
import 'package:mitra_apps/widgets/bulk_action_dialog.dart';
import 'package:mitra_apps/widgets/siswa_card.dart';
import 'package:mitra_apps/widgets/siswa_search_filter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminSiswaView extends StatefulWidget {
  const AdminSiswaView({super.key});

  @override
  State<AdminSiswaView> createState() => _AdminSiswaViewState();
}

class _AdminSiswaViewState extends State<AdminSiswaView> {
  final supabase = Supabase.instance.client;
  final _siswaService = SiswaService();

  List<Map<String, dynamic>> _listSiswa = [];
  List<Map<String, dynamic>> _filteredListSiswa = [];
  List<Map<String, dynamic>> _listKelas = [];
  final _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isSelecting = false;
  final Set<String> _selectedIds = {};
  String? _filterKelasId;

  static const _primary = Color(0xFF4338CA);
  static const _bgColor = Color(0xFFF4F6FB);

  @override
  void initState() {
    super.initState();
    _ambilDataSiswa();
    _ambilDataKelas();
  }

  Future<void> _ambilDataSiswa() async {
    setState(() => _isLoading = true);
    try {
      final data = await supabase
          .from('siswa')
          .select('*, kelas(nama_kelas)')
          .order('nama_siswa', ascending: true);
      setState(() {
        _listSiswa = List<Map<String, dynamic>>.from(data);
        _terapkanFilter();
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

  void _terapkanFilter() {
    final keyword = _searchController.text.toLowerCase();
    setState(() {
      _filteredListSiswa = _listSiswa.where((s) {
        final namaMatch = s['nama_siswa'].toString().toLowerCase().contains(
          keyword,
        );
        final nisMatch = s['nis'].toString().toLowerCase().contains(keyword);
        final kelasMatch =
            _filterKelasId == null || s['id_kelas'] == _filterKelasId;
        return (namaMatch || nisMatch) && kelasMatch;
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

  Future<void> _bulkHapus() async {
    final ok = await BulkActionDialog.konfirmasiHapus(
      context,
      _selectedIds.length,
    );
    if (!ok) return;

    setState(() => _isLoading = true);
    int berhasil = 0;
    for (final id in _selectedIds) {
      if (await _siswaService.hapusSiswa(id)) berhasil++;
    }
    setState(() {
      _selectedIds.clear();
      _isSelecting = false;
    });
    await _ambilDataSiswa();
    _showSnackbar('$berhasil siswa berhasil dihapus.');
  }

  Future<void> _bulkPindahKelas() async {
    final idKelasBaru = await BulkActionDialog.pilihKelasTujuan(
      context,
      _selectedIds.length,
      _listKelas,
    );
    if (idKelasBaru == null) return;

    setState(() => _isLoading = true);
    await supabase
        .from('siswa')
        .update({'id_kelas': idKelasBaru})
        .inFilter('id_siswa', _selectedIds.toList());

    setState(() {
      _selectedIds.clear();
      _isSelecting = false;
    });
    await _ambilDataSiswa();
    _showSnackbar('Siswa berhasil dipindahkan ke kelas baru.');
  }

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
                if (isEdit) {
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  await _siswaService.updateSiswa(siswa['id_siswa'], {
                    'nis': nisCtrl.text.trim(),
                    'nama_siswa': namaCtrl.text.trim(),
                    'id_kelas': idKelasTerpilih,
                  });
                  if (mounted) {
                    await _ambilDataSiswa();
                    _showSnackbar('Data berhasil diperbarui.');
                  }
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
                  Navigator.pop(ctx);
                  setState(() => _isLoading = true);
                  final sukses = await _siswaService.tambahSiswa(
                    SiswaModel(
                      nis: nisCtrl.text.trim(),
                      namaSiswa: namaCtrl.text.trim(),
                      idKelas: idKelasTerpilih,
                    ),
                  );
                  if (mounted) {
                    await _ambilDataSiswa();
                    _showSnackbar(
                      sukses
                          ? 'Siswa berhasil ditambahkan.'
                          : 'Gagal menambahkan siswa.',
                      isError: !sukses,
                    );
                  }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: _isSelecting
            ? Text('${_selectedIds.length} dipilih')
            : const Text(
                'Data Siswa',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: _isSelecting
            ? [
                IconButton(
                  icon: Icon(
                    _selectedIds.length == _filteredListSiswa.length
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                  onPressed: () => setState(() {
                    if (_selectedIds.length == _filteredListSiswa.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(
                        _filteredListSiswa.map((s) => s['id_siswa'].toString()),
                      );
                    }
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.drive_file_move_rounded),
                  tooltip: 'Pindah Kelas',
                  onPressed: _selectedIds.isEmpty ? null : _bulkPindahKelas,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_sweep_rounded),
                  tooltip: 'Hapus Terpilih',
                  onPressed: _selectedIds.isEmpty ? null : _bulkHapus,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() {
                    _isSelecting = false;
                    _selectedIds.clear();
                  }),
                ),
              ]
            : [
                IconButton(
                  icon: const Icon(Icons.checklist_rounded),
                  tooltip: 'Pilih Siswa',
                  onPressed: () => setState(() => _isSelecting = true),
                ),
              ],
      ),
      body: Column(
        children: [
          SiswaSearchFilter(
            searchController: _searchController,
            listKelas: _listKelas,
            filterKelasId: _filterKelasId,
            jumlahDitemukan: _filteredListSiswa.length,
            onSearch: (_) => _terapkanFilter(),
            onFilterKelas: (v) {
              setState(() => _filterKelasId = v);
              _terapkanFilter();
            },
          ),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _isSelecting
          ? null
          : FloatingActionButton.extended(
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
    return RefreshIndicator(
      onRefresh: _ambilDataSiswa,
      color: _primary,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        itemCount: _filteredListSiswa.length,
        itemBuilder: (ctx, i) {
          final siswa = _filteredListSiswa[i];
          final idSiswa = siswa['id_siswa'].toString();
          return SiswaCard(
            siswa: siswa,
            isSelecting: _isSelecting,
            isSelected: _selectedIds.contains(idSiswa),
            onLongPress: () => setState(() {
              _isSelecting = true;
              _selectedIds.add(idSiswa);
            }),
            onTap: () => setState(() {
              if (_selectedIds.contains(idSiswa)) {
                _selectedIds.remove(idSiswa);
                if (_selectedIds.isEmpty) _isSelecting = false;
              } else {
                _selectedIds.add(idSiswa);
              }
            }),
            onEdit: () => _tampilkanDialogForm(siswa: siswa),
            onHapus: () async {
              final yakin =
                  await showDialog<bool>(
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
                        'Data siswa "${siswa['nama_siswa']}" akan dihapus.',
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

              if (yakin && mounted) {
                final sukses = await _siswaService.hapusSiswa(idSiswa);
                if (mounted) {
                  await _ambilDataSiswa();
                  _showSnackbar(
                    sukses ? 'Data berhasil dihapus.' : 'Gagal menghapus data.',
                    isError: !sukses,
                  );
                }
              }
            },
            onResetPassword: () async {
              final nis = siswa['nis']?.toString() ?? '';
              final konfirmasi = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  title: const Row(
                    children: [
                      Icon(Icons.lock_reset_rounded, color: Color(0xFFD97706)),
                      SizedBox(width: 8),
                      Text('Reset Password', style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  content: Text(
                    'Reset password "${siswa['nama_siswa']}" kembali ke NIS?\n\n'
                    'Password baru: $nis',
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
                        backgroundColor: const Color(0xFFD97706),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );

              if (konfirmasi != true || !mounted) return;

              setState(() => _isLoading = true);
              final sukses = await _siswaService.resetPasswordSiswa(
                idSiswa,
                nis,
              );
              if (mounted) {
                setState(() => _isLoading = false);
                _showSnackbar(
                  sukses
                      ? 'Password berhasil direset ke NIS'
                      : 'Gagal reset password',
                  isError: !sukses,
                );
              }
            },
          );
        },
      ),
    );
  }
}
