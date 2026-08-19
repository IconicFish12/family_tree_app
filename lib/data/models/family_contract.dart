enum PersonGender { male, female }

extension PersonGenderContract on PersonGender {
  String get apiValue => switch (this) {
    PersonGender.male => 'male',
    PersonGender.female => 'female',
  };

  String get label => switch (this) {
    PersonGender.male => 'Laki-laki',
    PersonGender.female => 'Perempuan',
  };
}

enum MarriageRole { husband, wife }

extension MarriageRoleContract on MarriageRole {
  String get apiValue => switch (this) {
    MarriageRole.husband => 'husband',
    MarriageRole.wife => 'wife',
  };

  String get label => switch (this) {
    MarriageRole.husband => 'Suami',
    MarriageRole.wife => 'Istri',
  };

  PersonGender get requiredSpouseGender => switch (this) {
    MarriageRole.husband => PersonGender.female,
    MarriageRole.wife => PersonGender.male,
  };
}

enum ChildRelationshipType { biological, adopted }

extension ChildRelationshipTypeContract on ChildRelationshipType {
  bool get isBiological => switch (this) {
    ChildRelationshipType.biological => true,
    ChildRelationshipType.adopted => false,
  };

  String get label => switch (this) {
    ChildRelationshipType.biological => 'Anak Kandung',
    ChildRelationshipType.adopted => 'Anak Adopsi',
  };
}

enum FamilyHeadPosition { member, spouse }

extension FamilyHeadPositionContract on FamilyHeadPosition {
  String get apiValue => switch (this) {
    FamilyHeadPosition.member => 'member',
    FamilyHeadPosition.spouse => 'spouse',
  };

  String get label => switch (this) {
    FamilyHeadPosition.member => 'Anggota',
    FamilyHeadPosition.spouse => 'Pasangan',
  };
}

PersonGender? personGenderFromJson(Object? value) => switch (value) {
  'male' => PersonGender.male,
  'female' => PersonGender.female,
  _ => null,
};

String? personGenderToJson(PersonGender? value) => value?.apiValue;

MarriageRole? marriageRoleFromJson(Object? value) => switch (value) {
  'husband' => MarriageRole.husband,
  'wife' => MarriageRole.wife,
  _ => null,
};

String? marriageRoleToJson(MarriageRole? value) => value?.apiValue;

ChildRelationshipType? childRelationshipTypeFromJson(Object? value) {
  final isBiological = familyBoolFromJson(value);
  if (isBiological != null) {
    return isBiological
        ? ChildRelationshipType.biological
        : ChildRelationshipType.adopted;
  }

  // Fallback hanya untuk response lama yang masih memakai relationship_type.
  if (value is! String) return null;
  return switch (value.trim().toLowerCase()) {
    'biological' => ChildRelationshipType.biological,
    'adopted' => ChildRelationshipType.adopted,
    _ => null,
  };
}

ChildRelationshipType? childRelationshipTypeFromRelationJson(
  Map<String, dynamic> json,
) =>
    childRelationshipTypeFromJson(json['is_biological']) ??
    childRelationshipTypeFromJson(json['relationship_type']);

bool? childRelationshipTypeToJson(ChildRelationshipType? value) =>
    value?.isBiological;

FamilyHeadPosition? familyHeadPositionFromJson(Object? value) =>
    switch (value) {
      'member' => FamilyHeadPosition.member,
      'spouse' => FamilyHeadPosition.spouse,
      _ => null,
    };

String? familyHeadPositionToJson(FamilyHeadPosition? value) => value?.apiValue;

int? familyIntFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

bool? familyBoolFromJson(Object? value) {
  if (value is bool) return value;
  if (value is num) {
    if (value == 1) return true;
    if (value == 0) return false;
    return null;
  }
  if (value is String) {
    return switch (value.trim().toLowerCase()) {
      'true' || '1' => true,
      'false' || '0' => false,
      _ => null,
    };
  }
  return null;
}

String? familyStringFromJson(Object? value) {
  if (value is String) return value;
  if (value is num) return value.toString();
  return null;
}

String? familyStringToJson(String? value) => value;

class ParentChildRelationData {
  final int? relationId;
  final int? parentId;
  final int? childId;
  final int? marriageId;
  final ChildRelationshipType? relationshipType;
  final int? lineageOrder;
  final int? childOrder;

  const ParentChildRelationData({
    this.relationId,
    this.parentId,
    this.childId,
    this.marriageId,
    this.relationshipType,
    this.lineageOrder,
    this.childOrder,
  });

  factory ParentChildRelationData.fromJson(Map<String, dynamic> json) {
    final rawParent = json['parent'];
    final rawMarriage = json['marriage'];

    return ParentChildRelationData(
      relationId: familyIntFromJson(json['relation_id']),
      parentId:
          familyIntFromJson(json['parent_id']) ??
          _nestedInt(rawParent, 'user_id'),
      childId: familyIntFromJson(json['child_id']),
      marriageId:
          familyIntFromJson(json['marriage_id']) ??
          _nestedInt(rawMarriage, 'marriage_id'),
      relationshipType: childRelationshipTypeFromRelationJson(json),
      lineageOrder: familyIntFromJson(json['lineage_order']),
      childOrder: familyIntFromJson(json['child_order']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relation_id': relationId,
      'parent_id': parentId,
      'child_id': childId,
      'marriage_id': marriageId,
      'is_biological': childRelationshipTypeToJson(relationshipType),
      'lineage_order': lineageOrder,
      'child_order': childOrder,
    };
  }
}

int? _nestedInt(Object? value, String key) {
  if (value is! Map) return null;
  return familyIntFromJson(value[key]);
}

ParentChildRelationData? parentChildRelationFromJson(Object? value) {
  if (value is! Map) return null;
  return ParentChildRelationData.fromJson(Map<String, dynamic>.from(value));
}

Map<String, dynamic>? parentChildRelationToJson(
  ParentChildRelationData? value,
) => value?.toJson();
