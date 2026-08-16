bool canManageNit({required String? actorNit, required String? targetNit}) {
  final actorParts = _parts(actorNit);
  final targetParts = _parts(targetNit);
  if (actorParts == null || targetParts == null) return false;

  final isSelf = _sameParts(actorParts, targetParts);
  final isDirectChild =
      targetParts.length == actorParts.length + 1 &&
      _hasPrefix(targetParts, actorParts);
  return isSelf || isDirectChild;
}

bool canAddChildForNit({
  required String? actorNit,
  required String? parentNit,
}) {
  final actorParts = _parts(actorNit);
  final parentParts = _parts(parentNit);
  if (actorParts == null || parentParts == null) return false;

  final descendantDepth = parentParts.length - actorParts.length;
  return descendantDepth >= 0 &&
      descendantDepth <= 2 &&
      _hasPrefix(parentParts, actorParts);
}

List<String>? _parts(String? nit) {
  final value = nit?.trim() ?? '';
  if (value.isEmpty) return null;
  final parts = value.split('.');
  if (parts.any((part) => part.trim().isEmpty)) return null;
  return parts.map((part) => part.trim()).toList();
}

bool _sameParts(List<String> left, List<String> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

bool _hasPrefix(List<String> value, List<String> prefix) {
  for (var index = 0; index < prefix.length; index++) {
    if (value[index] != prefix[index]) return false;
  }
  return true;
}
