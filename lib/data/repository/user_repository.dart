import 'dart:io';

import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

abstract class UserRepository {
  Future<Either<Failure, FamilyDirectoryResponse>> getFamilyMembers({
    String keyword = '',
    int perPage = 25,
  });

  Future<Either<Failure, UserData>> getById(String id);
  Future<Either<Failure, FamilyTreeNode>> getTree();
  Future<Either<Failure, Map<String, dynamic>>> countFamilyMembers();
  Future<Either<Failure, UserData>> updateProfile(UserData data);
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(String memberId);
  Future<Either<Failure, bool>> createMarriage({
    required String memberId,
    required UserData spouseData,
  });
  Future<Either<Failure, bool>> createChild({
    required String memberId,
    String? marriageId,
    required String nit,
    required UserData childData,
  });
  Future<Either<Failure, bool>> updateFamilyMember({
    required int memberId,
    required String fullName,
    String? address,
    String? birthYear,
    String? gender,
  });
  Future<Either<Failure, bool>> deleteFamilyMember(int memberId);
}

class UserRepositoryImpl implements UserRepository {
  String _errorMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Koneksi ke server terlalu lama. Silakan coba lagi.';
    }
    return error.message ?? 'Terjadi kesalahan saat terhubung ke server.';
  }

  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    if (sanitized['user_id'] is String) {
      sanitized['user_id'] = int.tryParse(sanitized['user_id']);
    }
    if (sanitized['parent_id'] is String) {
      sanitized['parent_id'] = int.tryParse(sanitized['parent_id']);
    }
    return sanitized;
  }

  @override
  Future<Either<Failure, FamilyDirectoryResponse>> getFamilyMembers({
    String keyword = '',
    int perPage = 25,
  }) async {
    try {
      final response = await Config.dio.get(
        '/family-members',
        queryParameters: {
          'keyword': keyword.trim(),
          'per_page': perPage,
        },
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Right(
          FamilyDirectoryResponse.fromJson(
            Map<String, dynamic>.from(response.data as Map),
          ),
        );
      }

      return Left(Failure('Daftar keluarga tidak dapat dimuat.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memproses daftar keluarga.'));
    }
  }

  @override
  Future<Either<Failure, UserData>> getById(String id) async {
    try {
      final response = await Config.dio.get('/family-members/$id');

      if (response.statusCode == 200 && response.data is Map) {
        final body = Map<String, dynamic>.from(response.data as Map);
        final rawData = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : body;
        return Right(UserData.fromJson(_sanitizeUserData(rawData)));
      }

      return Left(Failure('Detail anggota tidak ditemukan.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memuat detail anggota.'));
    }
  }

  @override
  Future<Either<Failure, FamilyTreeNode>> getTree() async {
    try {
      final response = await Config.dio.get('/family-tree');

      if (response.statusCode == 200 && response.data is Map) {
        final body = Map<String, dynamic>.from(response.data as Map);
        final rawData = body['data'];
        if (rawData is Map) {
          return Right(FamilyTreeNode.fromJson(Map<String, dynamic>.from(rawData)));
        }
      }

      return Left(Failure('Bagan keluarga tidak dapat dimuat.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memproses bagan keluarga.'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> countFamilyMembers() async {
    try {
      final response = await Config.dio.get('/family/count');

      if (response.statusCode == 200 && response.data is Map) {
        return Right(Map<String, dynamic>.from(response.data as Map));
      }

      return Left(Failure('Jumlah anggota keluarga tidak dapat dimuat.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat menghitung anggota keluarga.'));
    }
  }

  @override
  Future<Either<Failure, UserData>> updateProfile(UserData data) async {
    try {
      if (data.avatar is XFile) {
        final formData = FormData.fromMap({
          '_method': 'PATCH',
          if (data.fullName != null) 'full_name': data.fullName,
          if (data.address != null) 'address': data.address,
          if (data.birthYear != null) 'birth_year': data.birthYear,
        });

        final image = data.avatar as XFile;
        final fileName = image.path.split(Platform.pathSeparator).last;
        final mimeType = fileName.toLowerCase().endsWith('png')
            ? 'image/png'
            : 'image/jpeg';

        formData.files.add(
          MapEntry(
            'avatar',
            await MultipartFile.fromFile(
              image.path,
              filename: fileName,
              contentType: MediaType.parse(mimeType),
            ),
          ),
        );

        final response = await Config.dio.post('/profile', data: formData);
        return _parseProfileResponse(response);
      }

      final response = await Config.dio.patch(
        '/profile',
        data: {
          if (data.fullName != null) 'full_name': data.fullName,
          if (data.address != null) 'address': data.address,
          if (data.birthYear != null) 'birth_year': data.birthYear,
        },
      );
      return _parseProfileResponse(response);
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memperbarui profil.'));
    }
  }

  Either<Failure, UserData> _parseProfileResponse(Response<dynamic> response) {
    if (response.statusCode == 200 && response.data is Map) {
      final body = Map<String, dynamic>.from(response.data as Map);
      final rawData = body['data'] is Map
          ? Map<String, dynamic>.from(body['data'] as Map)
          : body;
      return Right(UserData.fromJson(_sanitizeUserData(rawData)));
    }

    return Left(Failure('Profil tidak dapat diperbarui.'));
  }

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    try {
      final response = await Config.dio.get('/family-members/$memberId/marriages');

      if (response.statusCode == 200 && response.data is Map) {
        final body = Map<String, dynamic>.from(response.data as Map);
        final rawData = body['data'];
        if (rawData is List) {
          final marriages = rawData
              .whereType<Map>()
              .map(
                (item) => FamilyTreeMarriage.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList();
          return Right(marriages);
        }
      }

      return Left(Failure('Data pasangan tidak dapat dimuat.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat membaca data pasangan.'));
    }
  }

  @override
  Future<Either<Failure, bool>> createMarriage({
    required String memberId,
    required UserData spouseData,
  }) async {
    try {
      final response = await Config.dio.post(
        '/family-members/$memberId/marriages',
        data: {
          'spouse': {
            'full_name': spouseData.fullName,
            'address': spouseData.address,
            'birth_year': spouseData.birthYear,
          },
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return const Right(true);
      }

      return Left(Failure('Pasangan tidak dapat ditambahkan.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat menambah pasangan.'));
    }
  }

  @override
  Future<Either<Failure, bool>> createChild({
    required String memberId,
    String? marriageId,
    required String nit,
    required UserData childData,
  }) async {
    try {
      final payload = <String, dynamic>{
        'nit': nit,
        'full_name': childData.fullName,
        'address': childData.address,
        'birth_year': childData.birthYear,
      };

      if (marriageId != null && marriageId.isNotEmpty) {
        payload['marriage_id'] = marriageId;
      }

      final response = await Config.dio.post(
        '/family-members/$memberId/children',
        data: payload,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return const Right(true);
      }

      return Left(Failure('Anak tidak dapat ditambahkan.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat menambah anak.'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateFamilyMember({
    required int memberId,
    required String fullName,
    String? address,
    String? birthYear,
    String? gender,
  }) async {
    try {
      final response = await Config.dio.patch(
        '/family-members/$memberId',
        data: {
          'full_name': fullName,
          if (address != null && address.isNotEmpty) 'address': address,
          if (birthYear != null && birthYear.isNotEmpty) 'birth_year': birthYear,
          if (gender != null && gender.isNotEmpty) 'gender': gender,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return const Right(true);
      }
      return Left(Failure('Gagal memperbarui data anggota keluarga.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memproses pembaruan anggota keluarga.'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteFamilyMember(int memberId) async {
    try {
      final response = await Config.dio.delete(
        '/family-members/$memberId',
        data: {'confirm': true},
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      }
      return Left(Failure('Gagal menghapus anggota keluarga.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memproses penghapusan anggota keluarga.'));
    }
  }
}
