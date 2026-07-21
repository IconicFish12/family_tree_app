import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late HttpClientAdapter originalAdapter;
  late _RecordingAdapter adapter;

  setUp(() {
    originalAdapter = Config.dio.httpClientAdapter;
    adapter = _RecordingAdapter();
    Config.dio.httpClientAdapter = adapter;
  });

  tearDown(() {
    Config.dio.httpClientAdapter = originalAdapter;
  });

  test(
    'create child mengirim kontrak minimum dan memakai response final',
    () async {
      adapter.responseJson = {
        'data': {
          'user_id': 99,
          'nit': '1.4',
          'family_tree_id': '1.0.2.1',
          'level': 2,
          'full_name': 'Anak Baru',
        },
      };
      adapter.statusCode = 201;

      final result = await UserRepositoryImpl().createChild(
        memberId: '7',
        marriageId: 12,
        nit: '1.3',
        childData: const UserData(fullName: 'Anak Baru'),
      );

      expect(adapter.request?.method, 'POST');
      expect(adapter.request?.path, '/family-members/7/children');
      expect(adapter.request?.data, {
        'marriage_id': 12,
        'nit': '1.3',
        'full_name': 'Anak Baru',
      });
      final payloadKeys = (adapter.request?.data as Map).keys;
      for (final forbiddenKey in const [
        'family_tree_id',
        'level',
        'child_order',
        'parent_id',
        'marriage_order',
      ]) {
        expect(payloadKeys, isNot(contains(forbiddenKey)));
      }

      final created = result.fold((failure) => null, (member) => member);
      expect(created?.nit, '1.4');
      expect(created?.familyTreeId, '1.0.2.1');
    },
  );

  test('create marriage tidak mengirim NIT atau identifier struktur', () async {
    adapter.responseJson = {'data': <String, dynamic>{}};
    adapter.statusCode = 201;

    final result = await UserRepositoryImpl().createMarriage(
      memberId: '7',
      spouseData: const UserData(
        fullName: 'Pasangan Baru',
        nit: 'tidak-boleh-dikirim',
        familyTreeId: 'tidak-boleh-dikirim',
        level: 99,
      ),
    );

    expect(result.fold((failure) => false, (success) => success), isTrue);
    expect(adapter.request?.path, '/family-members/7/marriages');
    expect(adapter.request?.data, {
      'spouse': {'full_name': 'Pasangan Baru'},
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  Map<String, dynamic> responseJson = const {};
  int statusCode = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(responseJson),
      statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
