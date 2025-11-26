import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';

abstract class UserRepository {
  Future<Either<Failure, List<UserData>>> getData();
}

class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<Failure, List<UserData>>> getData() async {
    try {
      final api = await Config.dio.get('https://api-alusrah.oproject.id/api/user');

      if (api.statusCode == 200) {
        final List<dynamic> rawList = api.data;
        final result = rawList.map((e) => UserData.fromJson(e)).toList();

        return Right(result);
      } else {
        return Left(Failure("Server Error: ${api.statusCode}"));
      }
    } on DioException catch (e) {
      return Left(Failure(e.message ?? "Terjadi kesalahan koneksi"));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
  
}