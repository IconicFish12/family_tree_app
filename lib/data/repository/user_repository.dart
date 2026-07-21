import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/export_file_data.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

abstract class UserRepository {
  Future<Either<Failure, FamilyDirectoryResponse>> getFamilyMembers({String keyword = '', int perPage = 25});

  Future<Either<Failure, UserData>> getById(String id);
  Future<Either<Failure, FamilyTreeNode>> getTree();
  Future<Either<Failure, Map<String, dynamic>>> countFamilyMembers();
  Future<Either<Failure, UserData>> updateProfile(UserData data);
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(String memberId);
  Future<Either<Failure, FamilyTreeMarriage>> getMarriage(String marriageId);
  Future<Either<Failure, bool>> createMarriage({required String memberId, required UserData spouseData});
  Future<Either<Failure, bool>> updateMarriage({required String marriageId, required UserData spouseData});
  Future<Either<Failure, bool>> deleteMarriage(String marriageId);
  Future<Either<Failure, UserData>> createChild({
    required String memberId,
    required int marriageId,
    required String nit,
    required UserData childData,
  });
  Future<Either<Failure, UserData>> updateFamilyMember({required String memberId, required UserData memberData});
  Future<Either<Failure, bool>> deleteFamilyMember(String memberId);
  Future<Either<Failure, ExportFileData>> exportFamilyMembers();
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
    if (error.response?.statusCode == 403) {
      return 'Anda tidak memiliki izin untuk mengubah data ini.';
    }
    if (error.response?.statusCode == 409) {
      return 'Data belum dapat dihapus karena masih dipakai dalam silsilah.';
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
    if (sanitized['level'] is String) {
      sanitized['level'] = int.tryParse(sanitized['level']);
    }
    if (sanitized['nit'] != null && sanitized['nit'] is! String) {
      sanitized['nit'] = sanitized['nit'].toString();
    }
    if (sanitized['family_tree_id'] != null && sanitized['family_tree_id'] is! String) {
      sanitized['family_tree_id'] = sanitized['family_tree_id'].toString();
    }
    if (sanitized['birth_year'] != null && sanitized['birth_year'] is! String) {
      sanitized['birth_year'] = sanitized['birth_year'].toString();
    }
    return sanitized;
  }

  @override
  Future<Either<Failure, FamilyDirectoryResponse>> getFamilyMembers({String keyword = '', int perPage = 25}) async {
    try {
      final response = await Config.dio.get(
        '/family-members',
        queryParameters: {'keyword': keyword.trim(), 'per_page': perPage},
      );

      if (response.statusCode == 200 && response.data is Map) {
        return Right(FamilyDirectoryResponse.fromJson(Map<String, dynamic>.from(response.data as Map)));
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
        final rawData = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
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
        final fileName = image.name;
        final mimeType = fileName.toLowerCase().endsWith('png')
            ? 'image/png'
            : fileName.toLowerCase().endsWith('webp')
            ? 'image/webp'
            : 'image/jpeg';

        formData.files.add(
          MapEntry(
            'avatar',
            MultipartFile.fromBytes(await image.readAsBytes(), filename: fileName, contentType: MediaType.parse(mimeType)),
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
      final rawData = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
      return Right(UserData.fromJson(_sanitizeUserData(rawData)));
    }

    return Left(Failure('Profil tidak dapat diperbarui.'));
  }

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(String memberId) async {
    try {
      final response = await Config.dio.get('/family-members/$memberId/marriages');

      if (response.statusCode == 200 && response.data is Map) {
        final body = Map<String, dynamic>.from(response.data as Map);
        final rawData = body['data'];
        if (rawData is List) {
          final marriages = rawData
              .whereType<Map>()
              .map((item) => FamilyTreeMarriage.fromJson(Map<String, dynamic>.from(item)))
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
  Future<Either<Failure, FamilyTreeMarriage>> getMarriage(String marriageId) async {
    try {
      final response = await Config.dio.get('/marriages/$marriageId');
      if (response.statusCode == 200 && response.data is Map) {
        final body = Map<String, dynamic>.from(response.data as Map);
        final rawData = body['data'];
        if (rawData is Map) {
          return Right(FamilyTreeMarriage.fromJson(Map<String, dynamic>.from(rawData)));
        }
      }
      return Left(Failure('Detail pernikahan tidak dapat dimuat.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat membaca pernikahan.'));
    }
  }

  @override
  Future<Either<Failure, bool>> createMarriage({required String memberId, required UserData spouseData}) async {
    try {
      final response = await Config.dio.post(
        '/family-members/$memberId/marriages',
        data: {
          'spouse': {
            'full_name': spouseData.fullName,
            if (spouseData.address?.trim().isNotEmpty == true) 'address': spouseData.address!.trim(),
            if (spouseData.birthYear?.trim().isNotEmpty == true) 'birth_year': spouseData.birthYear!.trim(),
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
  Future<Either<Failure, bool>> updateMarriage({required String marriageId, required UserData spouseData}) async {
    try {
      final response = await Config.dio.patch(
        '/marriages/$marriageId',
        data: {
          'spouse': {
            if (spouseData.fullName?.trim().isNotEmpty == true) 'full_name': spouseData.fullName!.trim(),
            if (spouseData.address != null) 'address': spouseData.address!.trim(),
            if (spouseData.birthYear != null) 'birth_year': spouseData.birthYear!.trim(),
          },
        },
      );
      if (response.statusCode == 200) {
        return const Right(true);
      }
      return Left(Failure('Data pasangan tidak dapat diperbarui.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memperbarui pasangan.'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteMarriage(String marriageId) async {
    try {
      final response = await Config.dio.delete('/marriages/$marriageId');
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      }
      return Left(Failure('Data pernikahan tidak dapat dihapus.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat menghapus pernikahan.'));
    }
  }

  @override
  Future<Either<Failure, UserData>> createChild({
    required String memberId,
    required int marriageId,
    required String nit,
    required UserData childData,
  }) async {
    try {
      final payload = <String, dynamic>{
        'marriage_id': marriageId,
        'nit': nit,
        'full_name': childData.fullName,
        if (childData.address?.trim().isNotEmpty == true) 'address': childData.address!.trim(),
        if (childData.birthYear?.trim().isNotEmpty == true) 'birth_year': childData.birthYear!.trim(),
      };

      final response = await Config.dio.post('/family-members/$memberId/children', data: payload);

      if ((response.statusCode == 201 || response.statusCode == 200) && response.data is Map) {
        return _parseUserResponse(
          response,
          failureMessage: 'Data anak dari server belum lengkap.',
          requireStructuralIdentity: true,
        );
      }

      return Left(Failure('Anak tidak dapat ditambahkan.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat menambah anak.'));
    }
  }

  @override
  Future<Either<Failure, UserData>> updateFamilyMember({required String memberId, required UserData memberData}) async {
    try {
      final response = await Config.dio.patch(
        '/family-members/$memberId',
        data: {
          if (memberData.fullName?.trim().isNotEmpty == true) 'full_name': memberData.fullName!.trim(),
          if (memberData.address != null) 'address': memberData.address!.trim(),
          if (memberData.birthYear != null) 'birth_year': memberData.birthYear!.trim(),
        },
      );
      if (response.statusCode == 200 && response.data is Map) {
        return _parseUserResponse(response, failureMessage: 'Data anggota dari server belum lengkap.');
      }
      return Left(Failure('Data anggota tidak dapat diperbarui.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memperbarui anggota.'));
    }
  }

  @override
  Future<Either<Failure, bool>> deleteFamilyMember(String memberId) async {
    try {
      final response = await Config.dio.delete('/family-members/$memberId', data: const {'confirm': true});
      if (response.statusCode == 200 || response.statusCode == 204) {
        return const Right(true);
      }
      return Left(Failure('Data anggota tidak dapat dihapus.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat menghapus anggota.'));
    }
  }

  @override
  Future<Either<Failure, ExportFileData>> exportFamilyMembers() async {
    try {
      final response = await Config.dio.get<List<int>>('/export-users', options: Options(responseType: ResponseType.bytes));
      final data = response.data;
      if (response.statusCode == 200 && data != null && data.isNotEmpty) {
        return Right(ExportFileData(fileName: _exportFileName(response.headers), bytes: Uint8List.fromList(data)));
      }
      return Left(Failure('File Excel tidak dapat diunduh.'));
    } on DioException catch (e) {
      return Left(Failure(_errorMessage(e)));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat menyiapkan file Excel.'));
    }
  }

  Either<Failure, UserData> _parseUserResponse(
    Response<dynamic> response, {
    required String failureMessage,
    bool requireStructuralIdentity = false,
  }) {
    if (response.data is! Map) {
      return Left(Failure(failureMessage));
    }
    final body = Map<String, dynamic>.from(response.data as Map);
    final rawData = body['data'] is Map ? Map<String, dynamic>.from(body['data'] as Map) : body;
    if (rawData['user_id'] == null ||
        (requireStructuralIdentity && (rawData['nit'] == null || rawData['family_tree_id'] == null))) {
      return Left(Failure(failureMessage));
    }
    return Right(UserData.fromJson(_sanitizeUserData(rawData)));
  }

  String _exportFileName(Headers headers) {
    final disposition = headers.value('content-disposition') ?? '';
    final encodedMatch = RegExp(r"filename\*=UTF-8''([^;]+)", caseSensitive: false).firstMatch(disposition);
    if (encodedMatch != null) {
      return Uri.decodeComponent(encodedMatch.group(1)!).replaceAll('"', '');
    }
    final plainMatch = RegExp(r'filename="?([^";]+)"?', caseSensitive: false).firstMatch(disposition);
    return plainMatch?.group(1) ?? 'silsilah-keluarga.xlsx';
  }
}
