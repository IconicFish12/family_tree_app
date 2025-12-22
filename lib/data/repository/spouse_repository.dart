import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';

class SpouseRepository {
  Future<Either<Failure, bool>> addSpouse({
    required int primaryUserId,
    required int spouseUserId,
  }) async {
    try {
      final response = await Config.dio.post(
        '${Config.baseUrl}/spouse',
        data: {
          'primary_child_id': primaryUserId,
          'related_user_id': spouseUserId,
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return const Right(true);
      } else {
        return Left(
          Failure("Gagal menghubungkan pasangan: ${response.statusCode}"),
        );
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        return Left(Failure("Pasangan sudah terdaftar sebelumnya!"));
      }
      return Left(Failure(e.response?.data['message'] ?? e.message));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}
