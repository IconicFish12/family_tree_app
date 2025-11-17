import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_member.dart';
import 'package:family_tree_app/data/dummy_data.dart';
import 'package:family_tree_app/components/image_picker_field.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class UpdateFamilyMemberPage extends StatefulWidget {
  const UpdateFamilyMemberPage({super.key});

  @override
  State<UpdateFamilyMemberPage> createState() => _UpdateFamilyMemberPageState();
}

class _UpdateFamilyMemberPageState extends State<UpdateFamilyMemberPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nikController = TextEditingController();
  final _dateRangeController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedGender = 'Laki-Laki';
  String _selectedMonth = 'Januari';
  int _selectedYear = DateTime.now().year;
  String? _selectedRelation;
  File? memberPhoto;
  String? _memberPhotoUrl;

  final List<String> _months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  final List<String> _relations = [
    'Kepala Keluarga',
    'Pasangan',
    'Anak',
    'Cucu',
    'Orangtua',
    'Kakak',
    'Adik',
    'Paman/Bibi',
    'Keponakan',
    'Sepupu',
  ];

  @override
  void initState() {
    super.initState();
    // TODO: Load member data from route parameters or state management
    _initializeMemberData();
  }

  void _initializeMemberData() {
    // Load dummy data untuk testing
    final dummy = DummyData.dummyMemberData;
    _nameController.text = dummy['name'] ?? '';
    _nikController.text = dummy['nik'] ?? '';
    _dateRangeController.text = dummy['dateRange'] ?? '';
    _notesController.text = dummy['notes'] ?? '';
    _memberPhotoUrl = dummy['photoUrl'];
    _selectedGender = dummy['gender'] ?? 'Laki-Laki';
    _selectedRelation = dummy['relation'];
    _selectedMonth = dummy['month'] ?? 'Januari';
    _selectedYear = dummy['year'] ?? DateTime.now().year;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nikController.dispose();
    _dateRangeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateFamily() {
    if (_formKey.currentState!.validate()) {
      // Create updated FamilyMember object
      final updatedMember = FamilyMember(
        id: 'member-id', // TODO: Get from existing member
        name: _nameController.text,
        nik: _nikController.text,
        dateRange: _dateRangeController.text,
        image: _selectedGender == 'Laki-Laki' ? '👨' : '👩',
        year: _selectedYear,
        month: _selectedMonth,
        relation: _selectedRelation,
        status: 'active',
      );

      debugPrint('Updating member: ${updatedMember.toJson()}');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_nameController.text} berhasil diperbarui'),
          backgroundColor: Config.primary,
        ),
      );

      // Navigate back
      context.pop();
    }
  }

  void _deleteMember() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Anggota'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus anggota keluarga ini?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                // TODO: Delete from database/API
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Anggota berhasil dihapus'),
                    backgroundColor: Colors.red,
                  ),
                );
                context.pop(); // Close dialog
                context.pop(); // Go back to previous page
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 1.0,
        leading: CustomBackButton(
          color: Config.textHead,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/family-info');
            }
          },
        ),
        title: Text(
          'Edit Anggota Keluarga',
          style: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteMember,
            tooltip: 'Hapus Anggota',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Foto Anggota Keluarga
              Center(
                child: ImagePickerField(
                  label: 'Foto Anggota Keluarga',
                  initialImagePath: _memberPhotoUrl,
                  isNetworkImage: true,
                  onImageSelected: (file) {
                    setState(() {
                      memberPhoto = file;
                      if (file != null) {
                        _memberPhotoUrl = null;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Nama Lengkap
              _buildTextField(
                label: 'Nama Lengkap',
                controller: _nameController,
                hint: 'Masukkan nama lengkap',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Nama tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // NIK
              _buildTextField(
                label: 'Nomor Induk Kependudukan (NIK)',
                controller: _nikController,
                hint: 'Masukkan NIK (16 digit)',
                keyboardType: TextInputType.number,
                maxLength: 16,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'NIK tidak boleh kosong';
                  }
                  if (value!.length != 16) {
                    return 'NIK harus 16 digit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Jenis Kelamin
              _buildDropdown(
                label: 'Jenis Kelamin',
                value: _selectedGender,
                items: ['Laki-Laki', 'Perempuan'],
                onChanged: (value) {
                  setState(() => _selectedGender = value!);
                },
              ),
              const SizedBox(height: 16),

              // Hubungan Keluarga
              _buildDropdown(
                label: 'Hubungan Keluarga',
                value: _selectedRelation,
                items: _relations,
                onChanged: (value) {
                  setState(() => _selectedRelation = value);
                },
                isRequired: false,
              ),
              const SizedBox(height: 16),

              // Tanggal Lahir
              Text(
                'Tanggal Lahir',
                style: TextStyle(
                  color: Config.textHead,
                  fontWeight: Config.semiBold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      controller: _dateRangeController,
                      decoration: InputDecoration(
                        hintText: 'Tanggal',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Tanggal diperlukan';
                        }
                        final day = int.tryParse(value!);
                        if (day == null || day < 1 || day > 31) {
                          return 'Tanggal tidak valid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedMonth,
                      items: _months
                          .map(
                            (month) => DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        setState(() => _selectedMonth = value!);
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Bulan diperlukan';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 1,
                    child: TextFormField(
                      initialValue: _selectedYear.toString(),
                      decoration: InputDecoration(
                        hintText: 'Tahun',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          setState(() => _selectedYear = int.parse(value));
                        }
                      },
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Tahun diperlukan';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Catatan
              _buildTextField(
                label: 'Catatan Singkat',
                controller: _notesController,
                hint: 'Tambahkan catatan...',
                maxLines: 3,
                isRequired: false,
              ),
              const SizedBox(height: 32),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/family-info'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE0E0E0),
                          foregroundColor: Config.textSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _updateFamily,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primary,
                          foregroundColor: Config.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Helper widget untuk text field
  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator:
              validator ??
              (value) {
                if (isRequired && (value?.isEmpty ?? true)) {
                  return '$label tidak boleh kosong';
                }
                return null;
              },
        ),
      ],
    );
  }

  // Helper widget untuk dropdown
  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required Function(String?) onChanged,
    bool isRequired = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: value,
          items: items
              .map((item) => DropdownMenuItem(value: item, child: Text(item)))
              .toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          validator: isRequired
              ? (value) {
                  if (value == null) {
                    return '$label harus dipilih';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }
}
