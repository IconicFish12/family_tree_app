import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';

class AuthRepository {
  Future<Either<Failure, String>> login({
    required String nit,
    required String password,
    required String deviceName,
  }) async {
    try {
      final response = await Config.dio.post(
        '/users/login',
        options: Options(extra: const {'skipUnauthorizedHandler': true}),
        data: {'nit': nit, 'password': password, 'device_name': deviceName},
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final accessToken = data['access_token']?.toString();
        if (accessToken == null || accessToken.isEmpty) {
          return Left(Failure('Token login tidak ditemukan.'));
        }
        return Right(accessToken);
      }

      return Left(Failure('Login gagal. Silakan periksa NIT dan password.'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(Failure('NIT atau password salah.'));
      }
      if (e.response?.statusCode == 422) {
        return Left(Failure('Data login belum lengkap atau tidak valid.'));
      }
      if (e.response?.statusCode == 429) {
        return Left(
          Failure('Terlalu banyak percobaan login. Coba lagi nanti.'),
        );
      }
      if (e.response?.statusCode == 503) {
        return Left(
          Failure('Layanan login sedang belum siap. Coba lagi nanti.'),
        );
      }
      return Left(Failure(_extractMessage(e) ?? 'Gagal terhubung ke server.'));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat memproses login.'));
    }
  }

  Future<Either<Failure, UserData>> getProfile() async {
    try {
      final response = await Config.dio.get('/profile');

      if (response.statusCode == 200 && response.data is Map) {
        final body = Map<String, dynamic>.from(response.data as Map);
        final rawData = body['data'] is Map
            ? Map<String, dynamic>.from(body['data'] as Map)
            : body;
        return Right(UserData.fromJson(rawData));
      }

      return Left(Failure('Profil tidak dapat dimuat.'));
    } on DioException catch (e) {
      return Left(Failure(_extractMessage(e) ?? 'Profil tidak dapat dimuat.'));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat membaca profil.'));
    }
  }

  Future<Either<Failure, bool>> logout() async {
    try {
      final response = await Config.dio.post(
        '/users/logout',
        options: Options(extra: const {'skipUnauthorizedHandler': true}),
      );

      if (response.statusCode == 200) {
        return const Right(true);
      }

      return Left(Failure('Logout gagal.'));
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return const Right(true);
      }
      return Left(Failure(_extractMessage(e) ?? 'Logout gagal.'));
    } catch (_) {
      return Left(Failure('Terjadi kesalahan saat logout.'));
    }
  }

  String? _extractMessage(DioException error) {
    final responseData = error.response?.data;
    if (responseData is Map && responseData['message'] != null) {
      return responseData['message'].toString();
    }
    return error.message;
  }
}
