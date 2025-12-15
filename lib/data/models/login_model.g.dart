// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'login_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LoginModelImpl _$$LoginModelImplFromJson(Map<String, dynamic> json) =>
    _$LoginModelImpl(
      message: json['message'] as String,
      data: Data.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$LoginModelImplToJson(_$LoginModelImpl instance) =>
    <String, dynamic>{'message': instance.message, 'data': instance.data};

_$DataImpl _$$DataImplFromJson(Map<String, dynamic> json) => _$DataImpl(
  userId: (json['user_id'] as num).toInt(),
  familyTreeId: json['family_tree_id'] as String,
  parentId: json['parent_id'],
  fullName: json['full_name'] as String,
  address: json['address'] as String,
  birthYear: json['birth_year'],
  avatar: json['avatar'],
  createdAt: DateTime.parse(json['created_at'] as String),
  updatedAt: DateTime.parse(json['updated_at'] as String),
);

Map<String, dynamic> _$$DataImplToJson(_$DataImpl instance) =>
    <String, dynamic>{
      'user_id': instance.userId,
      'family_tree_id': instance.familyTreeId,
      'parent_id': instance.parentId,
      'full_name': instance.fullName,
      'address': instance.address,
      'birth_year': instance.birthYear,
      'avatar': instance.avatar,
      'created_at': instance.createdAt.toIso8601String(),
      'updated_at': instance.updatedAt.toIso8601String(),
    };
