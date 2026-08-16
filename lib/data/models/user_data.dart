import 'dart:convert';

import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_data.freezed.dart';
part 'user_data.g.dart';

List<UserData> userDataFromMap(String str) =>
    List<UserData>.from(json.decode(str).map((x) => UserData.fromJson(x)));

String userDataToMap(List<UserData> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

@freezed
class UserData with _$UserData {
  const factory UserData({
    @JsonKey(name: "user_id") int? userId,
    @JsonKey(name: "nit") String? nit,
    @JsonKey(name: "family_tree_id") String? familyTreeId,
    @JsonKey(name: "level") int? level,
    @JsonKey(name: "parent_id") int? parentId,
    @JsonKey(
      name: "parent_relation",
      fromJson: parentChildRelationFromJson,
      toJson: parentChildRelationToJson,
    )
    ParentChildRelationData? parentRelation,
    @JsonKey(name: "full_name") String? fullName,
    @JsonKey(
      name: "gender",
      fromJson: personGenderFromJson,
      toJson: personGenderToJson,
    )
    PersonGender? gender,
    @JsonKey(name: "address") String? address,
    @JsonKey(
      name: "birth_year",
      fromJson: familyStringFromJson,
      toJson: familyStringToJson,
    )
    String? birthYear,
    @JsonKey(name: "avatar") dynamic avatar,
    @JsonKey(name: "avatar_url") String? avatarUrl,
    @JsonKey(name: "created_at") DateTime? createdAt,
    @JsonKey(name: "updated_at") DateTime? updatedAt,
  }) = _UserData;

  factory UserData.fromJson(Map<String, dynamic> json) =>
      _$UserDataFromJson(json);
}
