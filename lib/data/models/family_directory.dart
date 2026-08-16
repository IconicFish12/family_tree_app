import 'package:family_tree_app/data/models/family_contract.dart';

class FamilyDirectoryResponse {
  final List<FamilyDirectoryMember> members;
  final FamilyDirectoryMeta meta;

  const FamilyDirectoryResponse({required this.members, required this.meta});

  factory FamilyDirectoryResponse.fromJson(Map<String, dynamic> json) {
    final rawMembers = json['data'];
    final rawMeta = json['meta'];

    return FamilyDirectoryResponse(
      members: rawMembers is List
          ? rawMembers
                .whereType<Map>()
                .map(
                  (item) => FamilyDirectoryMember.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      meta: rawMeta is Map
          ? FamilyDirectoryMeta.fromJson(Map<String, dynamic>.from(rawMeta))
          : const FamilyDirectoryMeta(),
    );
  }
}

class FamilyDirectoryMeta {
  final int currentPage;
  final int perPage;
  final int lastPage;
  final int total;
  final int? authenticatedMemberId;
  final int? familyRootId;

  const FamilyDirectoryMeta({
    this.currentPage = 1,
    this.perPage = 25,
    this.lastPage = 1,
    this.total = 0,
    this.authenticatedMemberId,
    this.familyRootId,
  });

  factory FamilyDirectoryMeta.fromJson(Map<String, dynamic> json) {
    return FamilyDirectoryMeta(
      currentPage: _toInt(json['current_page']) ?? 1,
      perPage: _toInt(json['per_page']) ?? 25,
      lastPage: _toInt(json['last_page']) ?? 1,
      total: _toInt(json['total']) ?? 0,
      authenticatedMemberId: _toInt(json['authenticated_member_id']),
      familyRootId: _toInt(json['family_root_id']),
    );
  }
}

class FamilyDirectoryMember {
  final int? userId;
  final String familyTreeId;
  final String nit;
  final int level;
  final String fullName;
  final PersonGender? gender;
  final String? address;
  final String? birthYear;
  final String? avatar;
  final String? avatarUrl;
  final ParentChildRelationData? parentRelation;

  const FamilyDirectoryMember({
    this.userId,
    required this.familyTreeId,
    required this.nit,
    required this.level,
    required this.fullName,
    this.gender,
    this.address,
    this.birthYear,
    this.avatar,
    this.avatarUrl,
    this.parentRelation,
  });

  factory FamilyDirectoryMember.fromJson(Map<String, dynamic> json) {
    return FamilyDirectoryMember(
      userId: _toInt(json['user_id']),
      familyTreeId: (json['family_tree_id'] ?? '').toString(),
      nit: (json['nit'] ?? '').toString(),
      level: _toInt(json['level']) ?? 0,
      fullName: (json['full_name'] ?? 'Tanpa Nama').toString(),
      gender: personGenderFromJson(json['gender']),
      address: json['address']?.toString(),
      birthYear: json['birth_year']?.toString(),
      avatar: json['avatar']?.toString(),
      avatarUrl: json['avatar_url']?.toString(),
      parentRelation: parentChildRelationFromJson(json['parent_relation']),
    );
  }
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
