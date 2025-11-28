import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:fpdart/fpdart.dart';

abstract class UserRepository {
  Future<Either<Failure, List<UserData>>> getData({int page = 1});
  
  Future<Either<Failure, UserData>> createUser(UserData data);
}

class UserRepositoryImpl implements UserRepository {
  @override
  Future<Either<Failure, List<UserData>>> getData({int page = 1}) async {
    try {
      final api = await Config.dio.get(
        'https://api-alusrah.oproject.id/api/user',
        queryParameters: {'page': page}, 
      );

      if (api.statusCode == 200) {
        final List<dynamic> rawList = api.data is List ? api.data : api.data['data']; 
        
        final result = rawList.map((e) => UserData.fromJson(e)).toList();
        return Right(result);
      } else {
        return Left(Failure("Server Error: ${api.statusCode}"));
      }
    } on DioException catch (e) {
      return Left(Failure(e.message ?? "Koneksi Bermasalah"));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, UserData>> createUser(UserData data) async {
    try {
      final body = data.toJson();
      
      body.remove('user_id');
      body.remove('created_at');
      body.remove('updated_at');

      final response = await Config.dio.post(
        'https://api-alusrah.oproject.id/api/user',
        data: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return Right(UserData.fromJson(response.data));
      } else {
        return Left(Failure("Gagal simpan: ${response.statusCode}"));
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
         return Left(Failure("Validasi Gagal: ${e.response?.data}"));
      }
      return Left(Failure("Network Error: ${e.message}"));
    } catch (e) {
      return Left(Failure(e.toString()));
    }
  }
}