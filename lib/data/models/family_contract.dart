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
}

enum ChildRelationshipType { biological, adopted }

extension ChildRelationshipTypeContract on ChildRelationshipType {
  String get apiValue => switch (this) {
    ChildRelationshipType.biological => 'biological',
    ChildRelationshipType.adopted => 'adopted',
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

ChildRelationshipType? childRelationshipTypeFromJson(Object? value) =>
    switch (value) {
      'biological' => ChildRelationshipType.biological,
      'adopted' => ChildRelationshipType.adopted,
      _ => null,
    };

String? childRelationshipTypeToJson(ChildRelationshipType? value) =>
    value?.apiValue;

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
      relationshipType: childRelationshipTypeFromJson(
        json['relationship_type'],
      ),
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
      'relationship_type': relationshipType?.apiValue,
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
