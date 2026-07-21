class NitGenerationException implements Exception {
  final String message;

  const NitGenerationException(this.message);

  @override
  String toString() => message;
}

class NitGeneratorService {
  const NitGeneratorService();

  String generateNextNit({
    required String parentNit,
    required List<String> directChildNits,
  }) {
    final normalizedParent = parentNit.trim();
    final parentSegments = _parseSegments(
      normalizedParent,
      errorMessage: 'NIT orang tua tidak valid.',
    );
    final childPrefix = '$normalizedParent.';
    var largestChildOrder = 0;

    for (final rawNit in directChildNits) {
      final childNit = rawNit.trim();
      if (childNit.isEmpty) {
        throw const NitGenerationException(
          'NIT anak belum lengkap. Silakan muat ulang data dan coba kembali.',
        );
      }

      if (!childNit.startsWith(childPrefix)) {
        continue;
      }

      final childSegments = childNit.split('.');
      if (childSegments.length != parentSegments.length + 1) {
        continue;
      }

      final childOrder = int.tryParse(childSegments.last);
      if (childOrder == null || childOrder <= 0) {
        throw const NitGenerationException(
          'Urutan NIT anak tidak valid. Silakan muat ulang data dan coba kembali.',
        );
      }

      if (childOrder > largestChildOrder) {
        largestChildOrder = childOrder;
      }
    }

    return '$normalizedParent.${largestChildOrder + 1}';
  }

  List<int> _parseSegments(String nit, {required String errorMessage}) {
    if (nit.isEmpty) {
      throw NitGenerationException(errorMessage);
    }

    final segments = nit.split('.');
    final parsed = <int>[];
    for (final segment in segments) {
      final value = int.tryParse(segment);
      if (value == null || value <= 0) {
        throw NitGenerationException(errorMessage);
      }
      parsed.add(value);
    }
    return parsed;
  }
}
