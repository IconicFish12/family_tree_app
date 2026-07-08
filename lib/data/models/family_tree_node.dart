class FamilyTreeSpouse {
  final int? userId;
  final String fullName;
  final String? address;
  final String? birthYear;

  const FamilyTreeSpouse({
    this.userId,
    required this.fullName,
    this.address,
    this.birthYear,
  });

  factory FamilyTreeSpouse.fromJson(Map<String, dynamic> json) {
    return FamilyTreeSpouse(
      userId: _toInt(json['user_id']),
      fullName: (json['full_name'] ?? 'Tanpa Nama').toString(),
      address: json['address']?.toString(),
      birthYear: json['birth_year']?.toString(),
    );
  }
}

class FamilyTreeNode {
  final int? userId;
  final String familyTreeId;
  final String fullName;
  final String? address;
  final String? birthYear;
  final List<FamilyTreeSpouse> spouse;
  final List<FamilyTreeNode> children;

  const FamilyTreeNode({
    this.userId,
    required this.familyTreeId,
    required this.fullName,
    this.address,
    this.birthYear,
    required this.spouse,
    required this.children,
  });

  bool get hasChildren => children.isNotEmpty;
  bool get canOpenSubtree => familyTreeId.isNotEmpty && hasChildren;

  String get spouseNames {
    return spouse
        .map((item) => item.fullName.trim())
        .where((name) => name.isNotEmpty)
        .join(', ');
  }

  factory FamilyTreeNode.fromJson(Map<String, dynamic> json) {
    final spouseRaw = json['spouse'];
    final childrenRaw = json['children'];

    return FamilyTreeNode(
      userId: _toInt(json['user_id']),
      familyTreeId: (json['family_tree_id'] ?? '').toString(),
      fullName: (json['full_name'] ?? 'Tanpa Nama').toString(),
      address: json['address']?.toString(),
      birthYear: json['birth_year']?.toString(),
      spouse: spouseRaw is List
          ? spouseRaw
                .whereType<Map>()
                .map(
                  (item) => FamilyTreeSpouse.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      children: childrenRaw is List
          ? childrenRaw
                .whereType<Map>()
                .map(
                  (item) =>
                      FamilyTreeNode.fromJson(Map<String, dynamic>.from(item)),
                )
                .toList()
          : const [],
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is String) return int.tryParse(value);
  return null;
}
