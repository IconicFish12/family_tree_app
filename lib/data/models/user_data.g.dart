// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserDataImpl _$$UserDataImplFromJson(Map<String, dynamic> json) =>
    _$UserDataImpl(
      userId: (json['user_id'] as num?)?.toInt(),
      nit: json['nit'] as String?,
      familyTreeId: json['family_tree_id'] as String?,
      level: (json['level'] as num?)?.toInt(),
      parentId: (json['parent_id'] as num?)?.toInt(),
      parentRelation: parentChildRelationFromJson(json['parent_relation']),
      fullName: json['full_name'] as String?,
      gender: personGenderFromJson(json['gender']),
      address: json['address'] as String?,
      birthYear: familyStringFromJson(json['birth_year']),
      avatar: json['avatar'],
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.parse(json['updated_at'] as String),
    );

Map<String, dynamic> _$$UserDataImplToJson(_$UserDataImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'nit': instance.nit,
      'family_tree_id': instance.familyTreeId,
      'level': instance.level,
      'parent_id': instance.parentId,
      'parent_relation': parentChildRelationToJson(instance.parentRelation),
      'full_name': instance.fullName,
      'gender': personGenderToJson(instance.gender),
      'address': instance.address,
      'birth_year': familyStringToJson(instance.birthYear),
      'avatar': instance.avatar,
      'avatar_url': instance.avatarUrl,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
