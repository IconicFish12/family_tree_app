import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerProvider extends ChangeNotifier {
  ImagePickerProvider({
    required String? initialImagePath,
    required bool isNetworkImage,
  }) : _networkImageUrl = isNetworkImage ? initialImagePath : null;

  final ImagePicker _picker = ImagePicker();

  XFile? _pickedFile;
  String? _networkImageUrl;

  XFile? get pickedFile => _pickedFile;
  String? get networkImageUrl => _networkImageUrl;

  Future<XFile?> pickImage(ImageSource source) async {
    final image = await _picker.pickImage(
      source: source,
      imageQuality: 50,
      maxWidth: 800,
    );

    if (image == null) {
      return null;
    }

    _pickedFile = image;
    _networkImageUrl = null;
    notifyListeners();
    return image;
  }
}
