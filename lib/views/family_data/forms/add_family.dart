import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/dummy_data.dart';
import 'package:family_tree_app/components/image_picker_field.dart';
import 'package:family_tree_app/components/child_selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddFamilyPage extends StatefulWidget {
  const AddFamilyPage({super.key});

  @override
  State<AddFamilyPage> createState() => _AddFamilyPageState();
}

class _AddFamilyPageState extends State<AddFamilyPage> {
  final _formKey = GlobalKey<FormState>();
  final _headNameController = TextEditingController();
  final _spouseNameController = TextEditingController();
  final _locationController = TextEditingController();

  File? _familyPhoto;
  String? _familyPhotoUrl;
  List<Map<String, dynamic>> _selectedChildren = [];

  final List<Map<String, TextEditingController>> _children = [];

  @override
  void dispose() {
    _headNameController.dispose();
    _spouseNameController.dispose();
    _locationController.dispose();
    for (var child in _children) {
      child['name']?.dispose();
      child['spouse']?.dispose();
    }
    super.dispose();
  }

  void _saveFamily() {
    if (_formKey.currentState!.validate()) {
      // Prepare family data
      final childrenData = <Map<String, String?>>[
        for (var child in _children)
          {
            'name': child['name']?.text ?? '',
            'spouse': child['spouse']?.text.isEmpty ?? true
                ? null
                : child['spouse']?.text,
          },
      ];

      final familyData = {
        'headName': _headNameController.text,
        'spouseName': _spouseNameController.text.isEmpty
            ? null
            : _spouseNameController.text,
        'location': _locationController.text,
        'children': childrenData,
      };

      debugPrint('Saving family: $familyData');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Keluarga ${_headNameController.text} berhasil ditambahkan',
          ),
          backgroundColor: Config.primary,
        ),
      );

      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 0,
        leading: CustomBackButton(
          color: Config.textHead,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/family-list');
            }
          },
        ),
        title: Text(
          'Tambah Data Keluarga',
          style: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section: Kepala Keluarga
              Text(
                'Informasi Keluarga',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Config.textHead,
                  fontWeight: Config.semiBold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              // Photo Picker untuk Foto Keluarga
              ImagePickerField(
                label: 'Foto Keluarga',
                initialImagePath: _familyPhotoUrl,
                isNetworkImage: true,
                onImageSelected: (file) {
                  setState(() {
                    _familyPhoto = file;
                    if (file != null) {
                      _familyPhotoUrl = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              _buildTextField(
                label: 'Nama Kepala Keluarga',
                controller: _headNameController,
                hint: 'Masukkan nama kepala keluarga',
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Nama kepala keluarga tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                label: 'Nama Pasangan (Opsional)',
                controller: _spouseNameController,
                hint: 'Masukkan nama pasangan',
                isRequired: false,
              ),
              const SizedBox(height: 16),

              // Section: Lokasi
              _buildTextField(
                label: 'Lokasi Tempat Tinggal',
                controller: _locationController,
                hint: 'Masukkan lokasi tempat tinggal',
                maxLines: 2,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Lokasi tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section: Pilih Anak dari List
              ChildSelectionWidget(
                availableChildren: DummyData.dummyAvailableChildren,
                selectedChildren: _selectedChildren,
                onChildrenSelected: (children) {
                  setState(() {
                    _selectedChildren = children;
                  });
                },
              ),
              const SizedBox(height: 24),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go('/family-list'),
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
                        onPressed: _saveFamily,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primary,
                          foregroundColor: Config.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Simpan Data Keluarga',
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

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
}
