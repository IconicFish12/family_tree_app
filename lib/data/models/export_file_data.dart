import 'dart:typed_data';

class ExportFileData {
  final String fileName;
  final Uint8List bytes;

  const ExportFileData({required this.fileName, required this.bytes});
}
