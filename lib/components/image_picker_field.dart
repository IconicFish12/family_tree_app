import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:family_tree_app/config/config.dart';

class ImagePickerField extends StatefulWidget {
  final String label;
  final String? initialImagePath;
  final Function(XFile?) onImageSelected; 
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
  // Ganti File? menjadi XFile?
  XFile? _pickedFile; 
  String? _networkImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.initialImagePath != null) {
      if (widget.isNetworkImage) {
        _networkImageUrl = widget.initialImagePath;
      } else {
        // Untuk initial local image, kita biarkan null dulu atau handle logic khusus
        // Biasanya initial image itu dari Network (Edit Profile)
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        // Tips: Kompres gambar agar upload lebih cepat & hemat kuota
        imageQuality: 50,
        maxWidth: 800,
      );

      if (image != null) {
        setState(() {
          _pickedFile = image;
          _networkImageUrl = null;
        });
        // Kirim XFile ke parent
        widget.onImageSelected(_pickedFile);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 150,
          height: 150,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Config.background,
            border: Border.all(color: Config.accent.withOpacity(0.3), width: 2),
          ),
          child: ClipOval(child: _buildImageContent()),
        ),
        const SizedBox(height: 20),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildButton(Icons.photo_library, 'Galeri', ImageSource.gallery),
              const SizedBox(width: 12),
              _buildButton(Icons.camera_alt, 'Kamera', ImageSource.camera),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    // 1. Jika ada gambar baru yang dipilih user
    if (_pickedFile != null) {
      if (kIsWeb) {
        // WEB: Gunakan Image.network karena XFile.path di web adalah Blob URL
        return Image.network(
          _pickedFile!.path,
          fit: BoxFit.cover,
          errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
        );
      } else {
        return Image.file(File(_pickedFile!.path), fit: BoxFit.cover);
      }
    }

    if (_networkImageUrl != null) {
      return Image.network(
        _networkImageUrl!,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (ctx, err, stack) => Center(
          child: Icon(
            Icons.person,
            size: 80,
            color: Config.accent.withOpacity(0.3),
          ),
        ),
      );
    }

    // 3. Default Placeholder
    return Center(
      child: Icon(
        Icons.person,
        size: 80,
        color: Config.accent.withOpacity(0.3),
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
