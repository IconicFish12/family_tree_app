import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/repository/auth_repository.dart';
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

  test('login tetap memakai NIT, password, dan device_name', () async {
    adapter.responseJson = {'access_token': 'token-test'};

    final result = await AuthRepository().login(
      nit: '1.2.3',
      password: 'password-test',
      deviceName: 'android',
    );

    expect(result.fold((failure) => null, (token) => token), 'token-test');
    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.path, '/users/login');
    expect(adapter.request?.data, {
      'nit': '1.2.3',
      'password': 'password-test',
      'device_name': 'android',
    });
  });
}

class _RecordingAdapter implements HttpClientAdapter {
  RequestOptions? request;
  Map<String, dynamic> responseJson = const {};

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    request = options;
    return ResponseBody.fromString(
      jsonEncode(responseJson),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
