import 'package:flutter/material.dart';
import 'package:mitra_apps/models/guru_model.dart';

class GuruFormDialog extends StatefulWidget {
  final GuruModel? guru;
  final Function(String nip, String nama, String email) onSave;

  const GuruFormDialog({super.key, this.guru, required this.onSave});

  @override
  State<GuruFormDialog> createState() => _GuruFormDialogState();
}

class _GuruFormDialogState extends State<GuruFormDialog> {
  late TextEditingController nipCtrl, namaCtrl, emailCtrl;

  @override
  void initState() {
    super.initState();
    nipCtrl = TextEditingController(text: widget.guru?.nip ?? '');
    namaCtrl = TextEditingController(text: widget.guru?.namaLengkap ?? '');
    emailCtrl = TextEditingController(text: widget.guru?.email ?? '');
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.guru != null ? 'Edit Guru' : 'Tambah Guru'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInput(nipCtrl, 'NIP', Icons.badge),
          const SizedBox(height: 12),
          _buildInput(namaCtrl, 'Nama Lengkap', Icons.person),
          const SizedBox(height: 12),
          _buildInput(
            emailCtrl,
            'Email',
            Icons.email,
            type: TextInputType.emailAddress,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () =>
              widget.onSave(nipCtrl.text, namaCtrl.text, emailCtrl.text),
          child: const Text('Simpan'),
        ),
      ],
    );
  }

  Widget _buildInput(
    TextEditingController c,
    String l,
    IconData i, {
    TextInputType type = TextInputType.text,
  }) {
    return TextField(
      controller: c,
      keyboardType: type,
      decoration: InputDecoration(
        labelText: l,
        prefixIcon: Icon(i),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
