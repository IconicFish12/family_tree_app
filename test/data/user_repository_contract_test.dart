import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
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

  test('create biological child mengirim payload fakta minimum', () async {
    adapter.responseJson = {
      'data': {
        'relation_id': 20,
        'parent_id': 7,
        'child_id': 99,
        'marriage_id': 12,
        'relationship_type': 'biological',
        'lineage_order': 4,
        'child_order': 2,
        'user_id': 99,
        'nit': '1.4',
        'family_tree_id': '1.2.2',
        'level': 2,
        'full_name': 'Anak Baru',
        'gender': 'male',
      },
    };
    adapter.statusCode = 201;

    final result = await UserRepositoryImpl().createChild(
      memberId: '7',
      relationshipType: ChildRelationshipType.biological,
      marriageId: 12,
      childData: const UserData(
        fullName: 'Anak Baru',
        gender: PersonGender.male,
        nit: 'tidak-boleh-dikirim',
        familyTreeId: 'tidak-boleh-dikirim',
        level: 99,
      ),
    );

    expect(adapter.request?.method, 'POST');
    expect(adapter.request?.path, '/family-members/7/children');
    expect(adapter.request?.data, {
      'relationship_type': 'biological',
      'marriage_id': 12,
      'full_name': 'Anak Baru',
      'gender': 'male',
      'address': null,
      'birth_year': null,
    });
    final payloadKeys = (adapter.request?.data as Map).keys;
    for (final forbiddenKey in const [
      'nit',
      'family_tree_id',
      'level',
      'lineage_order',
      'child_order',
      'parent_id',
      'marriage_order',
    ]) {
      expect(payloadKeys, isNot(contains(forbiddenKey)));
    }

    final created = result.fold((failure) => null, (member) => member);
    expect(created?.nit, '1.4');
    expect(created?.familyTreeId, '1.2.2');
    expect(created?.relationshipType, ChildRelationshipType.biological);
    expect(created?.lineageOrder, 4);
  });

  test(
    'create adopted child tanpa marriage tidak mengirim marriage_id',
    () async {
      adapter.responseJson = {
        'data': {
          'relation_id': 21,
          'parent_id': 7,
          'child_id': 100,
          'marriage_id': null,
          'relationship_type': 'adopted',
          'lineage_order': 5,
          'child_order': null,
          'user_id': 100,
          'nit': '1.5',
          'family_tree_id': '1.a.5',
          'level': 2,
          'full_name': 'Anak Adopsi',
          'gender': 'female',
        },
      };
      adapter.statusCode = 201;

      await UserRepositoryImpl().createChild(
        memberId: '7',
        relationshipType: ChildRelationshipType.adopted,
        childData: const UserData(
          fullName: 'Anak Adopsi',
          gender: PersonGender.female,
        ),
      );

      expect(adapter.request?.data, {
        'relationship_type': 'adopted',
        'full_name': 'Anak Adopsi',
        'gender': 'female',
        'address': null,
        'birth_year': null,
      });
      expect(
        (adapter.request?.data as Map).keys,
        isNot(contains('marriage_id')),
      );
    },
  );

  test('create adopted child dapat ditautkan ke marriage', () async {
    adapter.responseJson = {
      'data': {
        'relation_id': 22,
        'parent_id': 7,
        'child_id': 101,
        'marriage_id': 12,
        'relationship_type': 'adopted',
        'lineage_order': 6,
        'child_order': 3,
        'user_id': 101,
        'nit': '1.6',
        'family_tree_id': '1.2.3',
        'level': 2,
        'full_name': 'Anak Adopsi Pasangan',
        'gender': 'male',
      },
    };
    adapter.statusCode = 201;

    await UserRepositoryImpl().createChild(
      memberId: '7',
      relationshipType: ChildRelationshipType.adopted,
      marriageId: 12,
      childData: const UserData(
        fullName: 'Anak Adopsi Pasangan',
        gender: PersonGender.male,
      ),
    );

    expect(adapter.request?.data, {
      'relationship_type': 'adopted',
      'marriage_id': 12,
      'full_name': 'Anak Adopsi Pasangan',
      'gender': 'male',
      'address': null,
      'birth_year': null,
    });
  });

  test('biological child tanpa marriage gagal sebelum request', () async {
    final result = await UserRepositoryImpl().createChild(
      memberId: '7',
      relationshipType: ChildRelationshipType.biological,
      childData: const UserData(fullName: 'Anak Baru'),
    );

    expect(adapter.request, isNull);
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'Anak kandung wajib memilih pernikahan.',
    );
  });

  test('create child tanpa gender gagal sebelum request', () async {
    final result = await UserRepositoryImpl().createChild(
      memberId: '7',
      relationshipType: ChildRelationshipType.adopted,
      childData: const UserData(fullName: 'Anak Baru'),
    );

    expect(adapter.request, isNull);
    expect(
      result.fold((failure) => failure.message, (_) => null),
      'Jenis kelamin anak wajib dipilih.',
    );
  });

  test(
    'create marriage otomatis mengirim gender spouse dari member_role',
    () async {
      adapter.responseJson = {
        'data': {
          'marriage_id': 30,
          'member_id': 7,
          'marriage_order': 2,
          'member_role': 'husband',
          'spouse_role': 'wife',
          'is_role_classified': true,
          'family_head_position': 'member',
          'family_head_user_id': 7,
          'spouse': {
            'user_id': 8,
            'nit': null,
            'family_tree_id': '1.0.2',
            'level': 1,
            'full_name': 'Pasangan Baru',
            'gender': 'female',
          },
          'children': <dynamic>[],
        },
      };
      adapter.statusCode = 201;

      final result = await UserRepositoryImpl().createMarriage(
        memberId: '7',
        memberRole: MarriageRole.husband,
        spouseData: const UserData(
          fullName: 'Pasangan Baru',
          nit: 'tidak-boleh-dikirim',
          familyTreeId: 'tidak-boleh-dikirim',
          level: 99,
        ),
      );

      expect(adapter.request?.path, '/family-members/7/marriages');
      expect(adapter.request?.data, {
        'member_role': 'husband',
        'spouse': {
          'full_name': 'Pasangan Baru',
          'gender': 'female',
          'address': null,
          'birth_year': null,
        },
      });
      final request = adapter.request?.data as Map;
      expect(request.keys, isNot(contains('spouse_role')));
      expect(request.keys, isNot(contains('spouse_id')));

      final marriage = result.fold((failure) => null, (value) => value);
      expect(marriage?.memberRole, MarriageRole.husband);
      expect(marriage?.spouseRole, MarriageRole.wife);
      expect(marriage?.familyHeadPosition, FamilyHeadPosition.member);
    },
  );

  test('create marriage sebagai wife otomatis mengirim gender male', () async {
    adapter.responseJson = {
      'data': {
        'marriage_id': 31,
        'member_id': 7,
        'marriage_order': 1,
        'member_role': 'wife',
        'spouse_role': 'husband',
        'is_role_classified': true,
        'spouse': {
          'user_id': 9,
          'family_tree_id': '1.0.1',
          'level': 1,
          'full_name': 'Pasangan Baru',
          'gender': 'male',
        },
        'children': <dynamic>[],
      },
    };
    adapter.statusCode = 201;

    await UserRepositoryImpl().createMarriage(
      memberId: '7',
      memberRole: MarriageRole.wife,
      spouseData: const UserData(fullName: 'Pasangan Baru'),
    );

    expect(adapter.request?.data, {
      'member_role': 'wife',
      'spouse': {
        'full_name': 'Pasangan Baru',
        'gender': 'male',
        'address': null,
        'birth_year': null,
      },
    });
  });

  test('update member hanya mengirim fakta person termasuk null', () async {
    adapter.responseJson = {
      'data': {'user_id': 7, 'full_name': 'Nama Baru'},
    };

    await UserRepositoryImpl().updateFamilyMember(
      memberId: '7',
      memberData: const UserData(fullName: 'Nama Baru'),
    );

    expect(adapter.request?.data, {
      'full_name': 'Nama Baru',
      'gender': null,
      'address': null,
      'birth_year': null,
    });
  });

  test(
    'update profile JSON mengirim gender nullable dan fakta person',
    () async {
      adapter.responseJson = {
        'data': {
          'user_id': 7,
          'full_name': 'Nama Profil',
          'gender': null,
          'address': null,
          'birth_year': null,
        },
      };

      final result = await UserRepositoryImpl().updateProfile(
        const UserData(fullName: 'Nama Profil'),
      );

      expect(result.isRight(), isTrue);
      expect(adapter.request?.path, '/profile');
      expect(adapter.request?.data, {
        'full_name': 'Nama Profil',
        'gender': null,
        'address': null,
        'birth_year': null,
      });
    },
  );

  test('update marriage hanya mengirim fakta spouse termasuk gender', () async {
    adapter.responseJson = {'data': <String, dynamic>{}};

    final result = await UserRepositoryImpl().updateMarriage(
      marriageId: '30',
      spouseData: const UserData(
        fullName: 'Pasangan Diperbarui',
        gender: PersonGender.female,
        nit: 'tidak-boleh-dikirim',
      ),
    );

    expect(result.isRight(), isTrue);
    expect(adapter.request?.path, '/marriages/30');
    expect(adapter.request?.data, {
      'spouse': {
        'full_name': 'Pasangan Diperbarui',
        'gender': 'female',
        'address': null,
        'birth_year': null,
      },
    });
  });

  test('validation 422 meneruskan pesan errors pertama', () async {
    adapter.statusCode = 422;
    adapter.responseJson = {
      'message': 'Data tidak valid.',
      'errors': {
        'member_role': ['Istri hanya dapat mempunyai satu suami.'],
      },
    };

    final result = await UserRepositoryImpl().createMarriage(
      memberId: '7',
      memberRole: MarriageRole.wife,
      spouseData: const UserData(fullName: 'Pasangan Baru'),
    );

    expect(
      result.fold((failure) => failure.message, (_) => null),
      'Istri hanya dapat mempunyai satu suami.',
    );
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
