import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:family_tree_app/config/config.dart';

class ImagePickerField extends StatefulWidget {
  final String label;
  final String? initialImagePath;
  final Function(File?) onImageSelected;
  final bool isNetworkImage;

  const ImagePickerField({
    Key? key,
    required this.label,
    this.initialImagePath,
    required this.onImageSelected,
    this.isNetworkImage = false,
  }) : super(key: key);

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  File? _selectedImage;
  String? _networkImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      if (widget.isNetworkImage) {
        _networkImageUrl = widget.initialImagePath;
      } else {
        _selectedImage = File(widget.initialImagePath!);
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _networkImageUrl = null;
        });
        widget.onImageSelected(_selectedImage);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Large Profile Avatar (centered)
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Config.background,
            border: Border.all(
              color: Config.accent.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: _selectedImage != null
              ? ClipOval(child: Image.file(_selectedImage!, fit: BoxFit.cover))
              : _networkImageUrl != null
              ? ClipOval(
                  child: Image.network(
                    _networkImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Icon(
                          Icons.person,
                          size: 80,
                          color: Config.accent.withValues(alpha: 0.3),
                        ),
                      );
                    },
                  ),
                )
              : Center(
                  child: Icon(
                    Icons.person,
                    size: 80,
                    color: Config.accent.withValues(alpha: 0.3),
                  ),
                ),
        ),
        const SizedBox(height: 20),
        // Buttons Row - Now properly spaced
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Galeri'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Config.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Kamera'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Config.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
