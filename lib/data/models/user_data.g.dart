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
      fullName: json['full_name'] as String?,
      address: json['address'] as String?,
      birthYear: json['birth_year'] as String?,
      avatar: json['avatar'],
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
      'full_name': instance.fullName,
      'address': instance.address,
      'birth_year': instance.birthYear,
      'avatar': instance.avatar,
      'created_at': instance.createdAt?.toIso8601String(),
      'updated_at': instance.updatedAt?.toIso8601String(),
    };
