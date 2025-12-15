import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/login_model.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';

enum ViewState { initial, loading, success, error }

class AuthRepository {
  final String baseUrl = Config.baseUrl;

  Future<Either<Failure, LoginModel>> login(String familyTreeId, String password) async {
    try {
      final response = await Config.dio.post(
        "$baseUrl/users/login", // Base URL sudah ada di Config.dio
        data: {
          'family_tree_id': familyTreeId,
          'password': password,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Mapping JSON ke Model
        try {
          final loginData = LoginModel.fromJson(response.data);
          return Right(loginData);
        } catch (e) {
          return Left(Failure("Gagal memproses data login: $e"));
        }
      } else {
        return Left(Failure("Login gagal. Kode: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return Left(Failure("ID atau Password salah"));
      }
      if (e.response?.statusCode == 404) {
        return Left(Failure("Akun tidak ditemukan"));
      }
      return Left(Failure(e.response?.data['message'] ?? e.message ?? "Terjadi kesalahan koneksi"));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}