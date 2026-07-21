import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/provider/image_picker_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class ImagePickerField extends StatefulWidget {
  final String label;
  final String? initialImagePath;
  final ValueChanged<XFile?> onImageSelected;
  final bool isNetworkImage;

  const ImagePickerField({
    super.key,
    required this.label,
    this.initialImagePath,
    required this.onImageSelected,
    this.isNetworkImage = false,
  });

  @override
  State<ImagePickerField> createState() => _ImagePickerFieldState();
}

class _ImagePickerFieldState extends State<ImagePickerField> {
  late final ImagePickerProvider _imagePickerProvider;

  @override
  void initState() {
    super.initState();
    _imagePickerProvider = ImagePickerProvider(
      initialImagePath: widget.initialImagePath,
      isNetworkImage: widget.isNetworkImage,
    );
  }

  @override
  void dispose() {
    _imagePickerProvider.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _imagePickerProvider.pickImage(source);
      if (image != null) {
        widget.onImageSelected(image);
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ImagePickerProvider>.value(
      value: _imagePickerProvider,
      child: Consumer<ImagePickerProvider>(
        builder: (context, pickerProvider, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Config.textHead,
                ),
              ),
              const SizedBox(height: 12),
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
                child: ClipOval(child: _buildImageContent(pickerProvider)),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildButton(
                      Icons.photo_library,
                      'Galeri',
                      ImageSource.gallery,
                    ),
                    const SizedBox(width: 12),
                    _buildButton(
                      Icons.camera_alt,
                      'Kamera',
                      ImageSource.camera,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildImageContent(ImagePickerProvider pickerProvider) {
    if (pickerProvider.pickedBytes != null) {
      return Image.memory(
        pickerProvider.pickedBytes!,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image),
      );
    }

    if (pickerProvider.networkImageUrl != null) {
      return Image.network(
        pickerProvider.networkImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, _, _) => Center(
          child: Icon(
            Icons.person,
            size: 80,
            color: Config.accent.withValues(alpha: 0.3),
          ),
        ),
      );
    }

    return Center(
      child: Icon(
        Icons.person,
        size: 80,
        color: Config.accent.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildButton(IconData icon, String label, ImageSource source) {
    return ElevatedButton.icon(
      onPressed: () => _pickImage(source),
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Config.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
