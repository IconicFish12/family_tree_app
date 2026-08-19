import 'package:family_tree_app/data/models/family_contract.dart';

class FamilyTreeResponse {
  final FamilyTreeNode root;
  final FamilyTreeMeta meta;

  const FamilyTreeResponse({required this.root, required this.meta});

  factory FamilyTreeResponse.fromJson(Map<String, dynamic> json) {
    final rawRoot = json['data'];
    if (rawRoot is! Map) {
      throw const FormatException('Data root silsilah tidak ditemukan.');
    }

    final rawMeta = json['meta'];
    return FamilyTreeResponse(
      root: FamilyTreeNode.fromJson(Map<String, dynamic>.from(rawRoot)),
      meta: rawMeta is Map
          ? FamilyTreeMeta.fromJson(Map<String, dynamic>.from(rawMeta))
          : const FamilyTreeMeta(),
    );
  }
}

class FamilyTreeMeta {
  final int? authenticatedMemberId;
  final int? subtreeRootId;

  const FamilyTreeMeta({this.authenticatedMemberId, this.subtreeRootId});

  factory FamilyTreeMeta.fromJson(Map<String, dynamic> json) {
    return FamilyTreeMeta(
      authenticatedMemberId: _toInt(json['authenticated_member_id']),
      subtreeRootId: _toInt(json['subtree_root_id']),
    );
  }
}

class FamilyTreeSpouse {
  final int? userId;
  final String? nit;
  final String familyTreeId;
  final int level;
  final String fullName;
  final PersonGender? gender;
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
    this.gender,
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
      gender: personGenderFromJson(json['gender']),
      address: json['address']?.toString(),
      birthYear: json['birth_year']?.toString(),
      avatar: json['avatar']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
    );
  }
}

class FamilyTreeMarriage {
  final int marriageId;
  final int? memberId;
  final int marriageOrder;
  final String? status;
  final MarriageRole? memberRole;
  final MarriageRole? spouseRole;
  final bool isRoleClassified;
  final FamilyHeadPosition? familyHeadPosition;
  final int? familyHeadUserId;
  final FamilyTreeSpouse? spouse;
  final List<FamilyTreeNode> children;

  const FamilyTreeMarriage({
    required this.marriageId,
    this.memberId,
    required this.marriageOrder,
    this.status,
    this.memberRole,
    this.spouseRole,
    this.isRoleClassified = false,
    this.familyHeadPosition,
    this.familyHeadUserId,
    required this.spouse,
    required this.children,
  });

  bool get hasChildren => children.isNotEmpty;

  factory FamilyTreeMarriage.fromJson(Map<String, dynamic> json) {
    final rawChildren = json['children'];
    final rawSpouse = json['spouse'];

    return FamilyTreeMarriage(
      marriageId: _toInt(json['marriage_id']) ?? 0,
      memberId: _toInt(json['member_id']),
      marriageOrder: _toInt(json['marriage_order']) ?? 0,
      status: json['status']?.toString(),
      memberRole: marriageRoleFromJson(json['member_role']),
      spouseRole: marriageRoleFromJson(json['spouse_role']),
      isRoleClassified: _toBool(json['is_role_classified']),
      familyHeadPosition: familyHeadPositionFromJson(
        json['family_head_position'],
      ),
      familyHeadUserId: _toInt(json['family_head_user_id']),
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
  final int? parentId;
  final int? childId;
  final int? marriageId;
  final int? childOrder;
  final int? relationId;
  final ChildRelationshipType? relationshipType;
  final int? lineageOrder;
  final String fullName;
  final PersonGender? gender;
  final String? address;
  final String? birthYear;
  final String? avatar;
  final String? avatarUrl;
  final List<FamilyTreeMarriage> marriages;
  final List<FamilyTreeNode> adoptedChildren;

  const FamilyTreeNode({
    this.userId,
    this.nit,
    required this.familyTreeId,
    required this.level,
    this.parentId,
    this.childId,
    this.marriageId,
    this.childOrder,
    this.relationId,
    this.relationshipType,
    this.lineageOrder,
    required this.fullName,
    this.gender,
    this.address,
    this.birthYear,
    this.avatar,
    this.avatarUrl,
    this.marriages = const [],
    this.adoptedChildren = const [],
  });

  bool get hasDescendants =>
      adoptedChildren.isNotEmpty ||
      marriages.any((marriage) => marriage.children.isNotEmpty);

  int get spouseCount =>
      marriages.where((marriage) => marriage.spouse != null).length;

  Iterable<FamilyTreeNode> depthFirst() sync* {
    yield this;

    for (final marriage in marriages) {
      for (final child in marriage.children) {
        yield* child.depthFirst();
      }
    }

    for (final child in adoptedChildren) {
      yield* child.depthFirst();
    }
  }

  FamilyTreeNode? findByUserId(int? targetUserId) {
    if (targetUserId == null) return null;

    for (final node in depthFirst()) {
      if (node.userId == targetUserId) return node;
    }
    return null;
  }

  factory FamilyTreeNode.fromJson(Map<String, dynamic> json) {
    final rawMarriages = json['marriages'];
    final rawAdoptedChildren = json['adopted_children'];

    return FamilyTreeNode(
      userId: _toInt(json['user_id']),
      nit: json['nit']?.toString(),
      familyTreeId: (json['family_tree_id'] ?? '').toString(),
      level: _toInt(json['level']) ?? 0,
      parentId: _toInt(json['parent_id']),
      childId: _toInt(json['child_id']),
      marriageId: _toInt(json['marriage_id']),
      childOrder: _toInt(json['child_order']),
      relationId: _toInt(json['relation_id']),
      relationshipType: childRelationshipTypeFromRelationJson(json),
      lineageOrder: _toInt(json['lineage_order']),
      fullName: (json['full_name'] ?? 'Tanpa Nama').toString(),
      gender: personGenderFromJson(json['gender']),
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
      adoptedChildren: rawAdoptedChildren is List
          ? rawAdoptedChildren
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

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true' || value == '1';
  return false;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
