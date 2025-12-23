import 'dart:io';

import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

abstract class UserRepository {
  // GET routes
  Future<Either<Failure, List<UserData>>> getData({int page = 1});
  Future<Either<Failure, UserData>> getById(String id);
  Future<Either<Failure, List<UserData>>> getByTree(String familyTreeId);
  Future<Either<Failure, UserData>> getSingleBySearch({
    String? name,
    String? familyTreeId,
  });
  Future<Either<Failure, Map<String, dynamic>>> countFamilyMembers(
    String familyTreeId,
  );

  // POST routes
  Future<Either<Failure, UserData>> createUser(UserData data);
  Future<Either<Failure, UserData>> createUserWithoutTree(UserData data);
  Future<Either<Failure, UserData>> addChild(Map<String, dynamic> childData);
  Future<Either<Failure, dynamic>> createSpouse(
    Map<String, dynamic> spouseData,
  );
  Future<Either<Failure, UserData>> login(String email, String password);

  // PUT routes
  Future<Either<Failure, UserData>> updateProfile(String id, UserData data);
  Future<Either<Failure, dynamic>> updateChildrenByFamilyTree(
    Map<String, dynamic> updateData,
  );
}

class UserRepositoryImpl implements UserRepository {
  final String baseUrl = Config.baseUrl;

  bool _isValidId(String id) {
    return RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(id);
  }

  List<dynamic> _safeParseList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey('data') && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return [];
  }

  Map<String, dynamic>? _safeParseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  /// Sanitize numeric fields yang mungkin datang sebagai String dari API
  Map<String, dynamic> _sanitizeUserData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);

    // Convert user_id jika String
    if (sanitized['user_id'] is String) {
      sanitized['user_id'] = int.tryParse(sanitized['user_id']);
    }

    // Convert parent_id jika String
    if (sanitized['parent_id'] is String) {
      sanitized['parent_id'] = int.tryParse(sanitized['parent_id']);
    }

    return sanitized;
  }

  String _getErrorMessage(DioException e) {
    if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
      return "Akses ditolak. Silahkan login kembali.";
    }
    if (e.response?.statusCode == 404) {
      return "Data tidak ditemukan.";
    }
    if (e.response?.statusCode == 422) {
      return "Data yang dikirim tidak valid. Periksa kembali.";
    }
    if (e.response?.statusCode == 500) {
      return "Terjadi kesalahan server. Coba lagi nanti.";
    }
    if (e.type == DioExceptionType.connectionTimeout) {
      return "Koneksi timeout. Periksa internet Anda.";
    }
    if (e.type == DioExceptionType.receiveTimeout) {
      return "Server tidak merespon. Coba lagi nanti.";
    }
    return "Gagal terhubung ke server.";
  }

  // GET ALL USERS
  @override
  Future<Either<Failure, List<UserData>>> getData({int page = 1}) async {
    try {
      if (page < 1) return Left(Failure("Halaman harus minimal 1"));

      final response = await Config.dio.get(
        '$baseUrl/users',
        queryParameters: {'page': page},
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = _safeParseList(response.data);
        if (rawList.isEmpty) return Right([]);

        try {
          final result = rawList
              .map(
                (e) => UserData.fromJson(
                  _sanitizeUserData(Map<String, dynamic>.from(e)),
                ),
              )
              .toList();
          return Right(result);
        } catch (e) {
          return Left(Failure("Format data tidak sesuai"));
        }
      } else {
        return Left(Failure("Gagal memuat data pengguna"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memproses data"));
    }
  }

  // GET USER BY ID
  @override
  Future<Either<Failure, UserData>> getById(String id) async {
    try {
      if (id.isEmpty || !_isValidId(id)) {
        return Left(Failure("ID pengguna tidak valid"));
      }

      final response = await Config.dio.get('$baseUrl/user/$id');

      if (response.statusCode == 200 && response.data != null) {
        try {
          return Right(UserData.fromJson(response.data));
        } catch (e) {
          return Left(Failure("Format data tidak sesuai"));
        }
      } else {
        return Left(Failure("Pengguna tidak ditemukan"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memproses data"));
    }
  }

  // GET USERS BY FAMILY TREE ID
  @override
  Future<Either<Failure, List<UserData>>> getByTree(String familyTreeId) async {
    try {
      if (familyTreeId.isEmpty || !_isValidId(familyTreeId)) {
        return Left(Failure("ID pohon keluarga tidak valid"));
      }

      final response = await Config.dio.get(
        '$baseUrl/users/tree/$familyTreeId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> rawList = _safeParseList(response.data);
        if (rawList.isEmpty) return Right([]);

        try {
          final result = rawList.map((e) => UserData.fromJson(e)).toList();
          return Right(result);
        } catch (e) {
          return Left(Failure("Format data tidak sesuai"));
        }
      } else {
        return Left(Failure("Data pohon keluarga tidak ditemukan"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memproses data"));
    }
  }

  // GET SINGLE USER BY SEARCH
  @override
  Future<Either<Failure, UserData>> getSingleBySearch({
    String? name,
    String? familyTreeId,
  }) async {
    try {
      final queryParams = <String, dynamic>{};

      if (name != null && name.isNotEmpty) {
        if (name.length > 255) return Left(Failure("Nama terlalu panjang"));
        queryParams['name'] = name.trim();
      }

      if (familyTreeId != null && familyTreeId.isNotEmpty) {
        if (!_isValidId(familyTreeId)) {
          return Left(Failure("ID pohon keluarga tidak valid"));
        }
        queryParams['family_tree_id'] = familyTreeId;
      }

      if (queryParams.isEmpty) {
        return Left(
          Failure("Minimal satu parameter pencarian harus diberikan"),
        );
      }

      final response = await Config.dio.get(
        '$baseUrl/user/find',
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 && response.data != null) {
        try {
          return Right(UserData.fromJson(response.data));
        } catch (e) {
          return Left(Failure("Format data tidak sesuai"));
        }
      } else {
        return Left(Failure("Pengguna tidak ditemukan"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memproses data"));
    }
  }

  // COUNT FAMILY MEMBERS
  @override
  Future<Either<Failure, Map<String, dynamic>>> countFamilyMembers(
    String familyTreeId,
  ) async {
    try {
      if (familyTreeId.isEmpty || !_isValidId(familyTreeId)) {
        return Left(Failure("ID pohon keluarga tidak valid"));
      }

      final response = await Config.dio.get(
        '$baseUrl/family/count/$familyTreeId',
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic>? data = _safeParseMap(response.data);
        if (data == null) return Left(Failure("Format data tidak sesuai"));
        return Right(data);
      } else {
        return Left(Failure("Gagal mendapatkan jumlah anggota"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memproses data"));
    }
  }

  // CREATE USER WITH TREE
  @override
  Future<Either<Failure, UserData>> createUser(UserData data) async {
    try {
      final Map<String, dynamic> mapData = data.toJson();

      mapData.remove('user_id');
      mapData.remove('created_at');
      mapData.remove('updated_at');
      mapData.remove('avatar');

      final formData = FormData.fromMap(mapData);

      if (data.avatar != null) {
        String? filePath;

        if (data.avatar is XFile) {
          filePath = (data.avatar as XFile).path;
        }

        // Jika path ditemukan, proses upload
        if (filePath != null && filePath.isNotEmpty) {
          final String fileName = filePath.split('/').last;

          // Deteksi Mime Type sederhana
          final String mimeType = fileName.toLowerCase().endsWith('png')
              ? 'image/png'
              : 'image/jpeg';
          final MediaType mediaType = MediaType.parse(mimeType);

          formData.files.add(
            MapEntry(
              'avatar',
              await MultipartFile.fromFile(
                filePath,
                filename: fileName,
                contentType: mediaType,
              ),
            ),
          );
        }
      }
      ;

      final response = await Config.dio.post('$baseUrl/users', data: formData);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // API mungkin mengembalikan {message, data}, jadi handle kedua format
        final responseData = response.data;
        Map<String, dynamic>? userData;

        if (responseData is Map && responseData.containsKey('data')) {
          userData = responseData['data'];
        } else if (responseData is Map<String, dynamic>) {
          userData = responseData;
        }

        if (userData != null) {
          return Right(UserData.fromJson(_sanitizeUserData(userData)));
        } else {
          return Left(Failure("Format response tidak sesuai"));
        }
      } else {
        return Left(
          Failure("Gagal menyimpan data (Status: ${response.statusCode})"),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        print("Validation Error Detail: ${e.response?.data}");
      }
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: $e"));
    }
  }

  // CREATE USER WITHOUT TREE
  @override
  Future<Either<Failure, UserData>> createUserWithoutTree(UserData data) async {
    try {
      final body = data.toJson();

      body.remove('user_id');
      body.remove('created_at');
      body.remove('updated_at');

      if (body.isEmpty) {
        return Left(Failure("Data tidak boleh kosong"));
      }

      final response = await Config.dio.post(
        '$baseUrl/users/no-tree',
        data: body,
      );

      if (response.statusCode == 201 && response.data != null) {
        try {
          return Right(UserData.fromJson(response.data));
        } catch (e) {
          return Left(Failure("Format data respons tidak sesuai"));
        }
      } else {
        return Left(Failure("Gagal menyimpan data pengguna"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal menyimpan data"));
    }
  }

  // ADD CHILD - HALAMAN 9
  @override
  Future<Either<Failure, UserData>> addChild(
    Map<String, dynamic> childData,
  ) async {
    try {
      if (childData.isEmpty) {
        return Left(Failure("Data anak tidak boleh kosong"));
      }

      final response = await Config.dio.post(
        '$baseUrl/users/add-child',
        data: childData,
      );

      if (response.statusCode == 201 && response.data != null) {
        try {
          return Right(UserData.fromJson(response.data));
        } catch (e) {
          return Left(Failure("Format data respons tidak sesuai"));
        }
      } else {
        return Left(Failure("Gagal menambahkan anak"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal menambahkan anak"));
    }
  }

  // CREATE SPOUSE - HALAMAN 9
  @override
  Future<Either<Failure, dynamic>> createSpouse(
    Map<String, dynamic> spouseData,
  ) async {
    try {
      if (spouseData.isEmpty) {
        return Left(Failure("Data pasangan tidak boleh kosong"));
      }

      final response = await Config.dio.post(
        '$baseUrl/spouse',
        data: spouseData,
      );

      if (response.statusCode == 201 && response.data != null) {
        return Right(response.data);
      } else {
        return Left(Failure("Gagal menambahkan pasangan"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal menambahkan pasangan"));
    }
  }

  // LOGIN - HALAMAN 1
  @override
  Future<Either<Failure, UserData>> login(String email, String password) async {
    try {
      // Validate email format
      if (email.isEmpty || !email.contains('@')) {
        return Left(Failure("Email tidak valid"));
      }
      if (email.length > 255) {
        return Left(Failure("Email terlalu panjang"));
      }

      // Validate password
      if (password.isEmpty || password.length < 6) {
        return Left(Failure("Password minimal 6 karakter"));
      }
      if (password.length > 255) {
        return Left(Failure("Password terlalu panjang"));
      }

      final response = await Config.dio.post(
        '$baseUrl/users/login',
        data: {'email': email.trim(), 'password': password},
      );

      if (response.statusCode == 200 && response.data != null) {
        try {
          return Right(UserData.fromJson(response.data));
        } catch (e) {
          return Left(Failure("Format data respons tidak sesuai"));
        }
      } else {
        return Left(Failure("Email atau password salah"));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(Failure("Email atau password salah"));
      }
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal login"));
    }
  }

  // UPDATE PROFILE - HALAMAN 10
  @override
  Future<Either<Failure, UserData>> updateProfile(
    String id,
    UserData data,
  ) async {
    try {
      if (id.isEmpty || !_isValidId(id)) {
        return Left(Failure("ID pengguna tidak valid"));
      }

      print('[Repository] updateProfile called - id: $id');

      final Map<String, dynamic> mapData = data.toJson();
      mapData.remove('user_id');
      mapData.remove('created_at');
      mapData.remove('updated_at');
      mapData.remove('avatar');

      print('[Repository] Form data fields: $mapData');

      final formData = FormData.fromMap(mapData);

      if (data.avatar != null) {
        String? filePath;

        if (data.avatar is XFile) {
          filePath = (data.avatar as XFile).path;
        } else if (data.avatar is File) {
          filePath = (data.avatar as File).path;
        }

        print('[Repository] Avatar path: $filePath');

        if (filePath != null && filePath.isNotEmpty) {
          final String fileName = filePath.split('/').last;
          final String mimeType = fileName.toLowerCase().endsWith('png')
              ? 'image/png'
              : 'image/jpeg';
          final MediaType mediaType = MediaType.parse(mimeType);

          formData.files.add(
            MapEntry(
              'avatar',
              await MultipartFile.fromFile(
                filePath,
                filename: fileName,
                contentType: mediaType,
              ),
            ),
          );
          print('[Repository] Avatar file added to form');
        }
      }

      print('[Repository] Calling POST $baseUrl/user/update/$id');

      final response = await Config.dio.post(
        '$baseUrl/user/update/$id',
        data: formData,
      );

      print('[Repository] Response status: ${response.statusCode}');
      print('[Repository] Response data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        // API mengembalikan {message, data}, jadi ambil data['data']
        final responseData = response.data;
        Map<String, dynamic>? userData;

        if (responseData is Map && responseData.containsKey('data')) {
          userData = responseData['data'];
        } else if (responseData is Map<String, dynamic>) {
          userData = responseData;
        }

        if (userData != null) {
          final parsedUser = UserData.fromJson(_sanitizeUserData(userData));
          print('[Repository] Parsed UserData: ${parsedUser.toJson()}');
          return Right(parsedUser);
        } else {
          return Left(Failure("Format response tidak sesuai"));
        }
      } else {
        return Left(Failure("Gagal memperbarui profil"));
      }
    } on DioException catch (e) {
      print('[Repository] DioException: ${e.message}');
      print('[Repository] DioException response: ${e.response?.data}');
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      print('[Repository] Error: $e');
      return Left(Failure(e.toString()));
    }
  }

  // UPDATE CHILDREN BY FAMILY TREE - HALAMAN 11
  @override
  Future<Either<Failure, dynamic>> updateChildrenByFamilyTree(
    Map<String, dynamic> updateData,
  ) async {
    try {
      if (updateData.isEmpty) {
        return Left(Failure("Data update tidak boleh kosong"));
      }

      final response = await Config.dio.put(
        '$baseUrl/family/update-children',
        data: updateData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return Right(response.data);
      } else {
        return Left(Failure("Gagal memperbarui data anak"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memperbarui data"));
    }
  }
}
