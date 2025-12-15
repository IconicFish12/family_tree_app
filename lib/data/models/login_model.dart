import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';

part 'login_model.freezed.dart';
part 'login_model.g.dart';

LoginModel loginModelFromMap(String str) =>
    LoginModel.fromJson(json.decode(str));

String loginModelToMap(LoginModel data) => json.encode(data.toJson());

@freezed
class LoginModel with _$LoginModel {
  const factory LoginModel({
    @JsonKey(name: "message") required String message,
    @JsonKey(name: "data") required Data data,
  }) = _LoginModel;

  factory LoginModel.fromJson(Map<String, dynamic> json) =>
      _$LoginModelFromJson(json);
}

@freezed
class Data with _$Data {
  const factory Data({
    @JsonKey(name: "user_id") required int userId,
    @JsonKey(name: "family_tree_id") required String familyTreeId,
    @JsonKey(name: "parent_id") required dynamic parentId,
    @JsonKey(name: "full_name") required String fullName,
    @JsonKey(name: "address") required String address,
    @JsonKey(name: "birth_year") required dynamic birthYear,
    @JsonKey(name: "avatar") required dynamic avatar,
    @JsonKey(name: "created_at") required DateTime createdAt,
    @JsonKey(name: "updated_at") required DateTime updatedAt,
  }) = _Data;

  factory Data.fromJson(Map<String, dynamic> json) => _$DataFromJson(json);
}
