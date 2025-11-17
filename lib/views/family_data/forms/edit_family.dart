import 'dart:io';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/dummy_data.dart';
import 'package:family_tree_app/components/image_picker_field.dart';
import 'package:family_tree_app/components/child_selection_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class EditFamilyPage extends StatefulWidget {
  final Map<String, dynamic> familyData;
  final String familyId;

  const EditFamilyPage({
    super.key,
    required this.familyData,
    required this.familyId,
  });

  @override
  State<EditFamilyPage> createState() => _EditFamilyPageState();
}

class _EditFamilyPageState extends State<EditFamilyPage> {
  late TextEditingController _headNameController;
  late TextEditingController _spouseNameController;
  late TextEditingController _locationController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late List<Map<String, TextEditingController>> _childrenControllers;

  File? familyPhoto;
  String? _familyPhotoUrl;
  List<Map<String, dynamic>> _selectedChildren = [];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Use dummy data if familyData is empty
    final data = widget.familyData.isEmpty
        ? DummyData.dummyFamilyData
        : widget.familyData;

    _headNameController = TextEditingController(text: data['headName'] ?? '');
    _spouseNameController = TextEditingController(
      text: data['spouseName'] ?? '',
    );
    _locationController = TextEditingController(text: data['location'] ?? '');
    _familyPhotoUrl = data['headPhoto'];

    _childrenControllers = [];
    if (data['children'] != null) {
      for (var child in data['children']) {
        _childrenControllers.add({
          'name': TextEditingController(text: child['name'] ?? ''),
          'spouse': TextEditingController(text: child['spouse'] ?? ''),
        });
      }
    }

    // Load selected children from data
    _selectedChildren =
        (data['children'] as List?)?.map((child) {
          return {
            'id': child['id'] ?? '',
            'name': child['name'] ?? '',
            'photo': child['photo'],
          };
        }).toList() ??
        [];
  }

  @override
  void dispose() {
    _headNameController.dispose();
    _spouseNameController.dispose();
    _locationController.dispose();
    for (var controllers in _childrenControllers) {
      controllers['name']?.dispose();
      controllers['spouse']?.dispose();
    }
    super.dispose();
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Config.textSecondary, fontSize: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Config.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        validator: validator,
      ),
    );
  }

  void _deleteFamily() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus Keluarga'),
          content: const Text(
            'Apakah Anda yakin ingin menghapus data keluarga ini? Tindakan ini tidak dapat dibatalkan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () {
                final nav = Navigator.of(context);
                final messenger = ScaffoldMessenger.of(context);
                final navigatorContext = context;
                nav.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Keluarga berhasil dihapus'),
                    backgroundColor: Colors.green,
                  ),
                );
                if (mounted) {
                  Future.delayed(const Duration(milliseconds: 500), () {
                    // ignore: use_build_context_synchronously
                    if (mounted) navigatorContext.pop();
                  });
                }
              },
              child: const Text('Hapus', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _updateFamily() {
    if (_formKey.currentState!.validate()) {
      final childrenData = <Map<String, String>>[];
      for (var controllers in _childrenControllers) {
        if (controllers['name']!.text.isNotEmpty) {
          childrenData.add({
            'name': controllers['name']!.text,
            'spouse': controllers['spouse']!.text,
          });
        }
      }

      final updatedFamily = {
        'id': widget.familyId,
        'headName': _headNameController.text,
        'spouseName': _spouseNameController.text,
        'location': _locationController.text,
        'children': childrenData,
      };

      debugPrint('Updated Family: $updatedFamily');

      final messenger = ScaffoldMessenger.of(context);
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Data keluarga berhasil diperbarui'),
          backgroundColor: Colors.green,
        ),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) context.pop();
      });
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
          'Edit Data Keluarga',
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
            onPressed: _deleteFamily,
            tooltip: 'Hapus Keluarga',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Section: Informasi Keluarga
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
              // Photo Picker untuk Foto Keluarga (centered)
              ImagePickerField(
                label: 'Foto Keluarga',
                initialImagePath: _familyPhotoUrl,
                isNetworkImage: true,
                onImageSelected: (file) {
                  setState(() {
                    familyPhoto = file;
                    if (file != null) {
                      _familyPhotoUrl = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 24),

              _buildTextField(
                _headNameController,
                'Nama Kepala Keluarga',
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Nama kepala keluarga harus diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _spouseNameController,
                'Nama Pasangan (Opsional)',
              ),
              const SizedBox(height: 16),

              _buildTextField(
                _locationController,
                'Lokasi Tempat Tinggal',
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lokasi harus diisi';
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

              // Tombol Aksi
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
}
