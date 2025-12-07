import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';

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

  // Helper: Validate ID format (UUID or numeric)
  bool _isValidId(String id) {
    return RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(id);
  }

  // Helper: Safe JSON parsing for list responses
  List<dynamic> _safeParseList(dynamic data) {
    if (data is List) return data;
    if (data is Map && data.containsKey('data') && data['data'] is List) {
      return data['data'] as List<dynamic>;
    }
    return [];
  }

  // Helper: Safe JSON parsing for map responses
  Map<String, dynamic>? _safeParseMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    return null;
  }

  // Helper: Extract user-friendly error message
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
        '$baseUrl/user',
        queryParameters: {'page': page},
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
        return Left(Failure("Gagal memuat data pengguna"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memproses data"));
    }
  }

  // GET USER BY ID - HALAMAN 5, HALAMAN 6
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

  // GET USERS BY FAMILY TREE ID - HALAMAN 4, HALAMAN 5, HALAMAN 12
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

  // GET SINGLE USER BY SEARCH - HALAMAN 7, HALAMAN 8
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

  // COUNT FAMILY MEMBERS - HALAMAN 2, HALAMAN 3
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
      final body = data.toJson();

      body.remove('user_id');
      body.remove('created_at');
      body.remove('updated_at');

      if (body.isEmpty) {
        return Left(Failure("Data tidak boleh kosong"));
      }

      final response = await Config.dio.post('$baseUrl/users', data: body);

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

      final body = data.toJson();

      body.remove('user_id');
      body.remove('created_at');
      body.remove('updated_at');

      if (body.isEmpty) {
        return Left(Failure("Data tidak boleh kosong"));
      }

      final response = await Config.dio.put(
        '$baseUrl/user/update/$id',
        data: body,
      );

      if (response.statusCode == 200 && response.data != null) {
        try {
          return Right(UserData.fromJson(response.data));
        } catch (e) {
          return Left(Failure("Format data respons tidak sesuai"));
        }
      } else {
        return Left(Failure("Gagal memperbarui profil"));
      }
    } on DioException catch (e) {
      return Left(Failure(_getErrorMessage(e)));
    } catch (e) {
      return Left(Failure("Terjadi kesalahan: Gagal memperbarui profil"));
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
