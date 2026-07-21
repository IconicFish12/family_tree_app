class FamilyTreeSpouse {
  final int? userId;
  final String? nit;
  final String familyTreeId;
  final int level;
  final String fullName;
  final String? address;
  final String? birthYear;
  final String? avatar;
  final String? avatarUrl;

  const FamilyTreeSpouse({
    this.userId,
    this.nit,
    required this.familyTreeId,
    required this.level,
    required this.fullName,
    this.address,
    this.birthYear,
    this.avatar,
    this.avatarUrl,
  });

  factory FamilyTreeSpouse.fromJson(Map<String, dynamic> json) {
    return FamilyTreeSpouse(
      userId: _toInt(json['user_id']),
      nit: json['nit']?.toString(),
      familyTreeId: (json['family_tree_id'] ?? '').toString(),
      level: _toInt(json['level']) ?? 0,
      fullName: (json['full_name'] ?? 'Pasangan').toString(),
      address: json['address']?.toString(),
      birthYear: json['birth_year']?.toString(),
      avatar: json['avatar']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

class FamilyTreeMarriage {
  final int marriageId;
  final int marriageOrder;
  final FamilyTreeSpouse? spouse;
  final List<FamilyTreeNode> children;

  const FamilyTreeMarriage({
    required this.marriageId,
    required this.marriageOrder,
    required this.spouse,
    required this.children,
  });

  bool get hasChildren => children.isNotEmpty;

  factory FamilyTreeMarriage.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final rawSpouse = json['spouse'];

    return FamilyTreeMarriage(
      marriageId: _toInt(json['marriage_id']) ?? 0,
      marriageOrder: _toInt(json['marriage_order']) ?? 0,
      spouse: rawSpouse is Map
          ? FamilyTreeSpouse.fromJson(Map<String, dynamic>.from(rawSpouse))
          : null,
      children: rawChildren is List
          ? rawChildren
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

class FamilyTreeNode {
  final int? userId;
  final String? nit;
  final String familyTreeId;
  final int level;
  final int? childOrder;
  final int? relationId;
  final String fullName;
  final String? address;
  final String? birthYear;
  final String? avatar;
  final String? avatarUrl;
  final List<FamilyTreeMarriage> marriages;

  const FamilyTreeNode({
    this.userId,
    this.nit,
    required this.familyTreeId,
    required this.level,
    this.childOrder,
    this.relationId,
    required this.fullName,
    this.address,
    this.birthYear,
    this.avatar,
    this.avatarUrl,
    required this.marriages,
  });

  bool get hasDescendants =>
      marriages.any((marriage) => marriage.children.isNotEmpty);

  int get spouseCount =>
      marriages.where((marriage) => marriage.spouse != null).length;

  factory FamilyTreeNode.fromJson(Map<String, dynamic> json) {
    final rawMarriages = json['marriages'];

    return FamilyTreeNode(
      userId: _toInt(json['user_id']),
      nit: json['nit']?.toString(),
      familyTreeId: (json['family_tree_id'] ?? '').toString(),
      level: _toInt(json['level']) ?? 0,
      childOrder: _toInt(json['child_order']),
      relationId: _toInt(json['relation_id']),
      fullName: (json['full_name'] ?? 'Tanpa Nama').toString(),
      address: json['address']?.toString(),
      birthYear: json['birth_year']?.toString(),
      avatar: json['avatar']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      marriages: rawMarriages is List
          ? rawMarriages
                .whereType<Map>()
                .map(
                  (item) => FamilyTreeMarriage.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
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
