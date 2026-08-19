import 'dart:async';

import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/family_member_form_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  const actor = UserData(userId: 1, nit: '1', fullName: 'Anggota Utama');

  test(
    'toggle adopsi tetap membutuhkan pernikahan saat pemuatan gagal',
    () async {
      final repository = _FamilyFormRepository(
        marriagesResult: Left(Failure('Data pernikahan gagal dimuat.')),
      );
      final userProvider = UserProvider(repository);
      final formProvider = FamilyMemberFormProvider();
      addTearDown(formProvider.dispose);
      addTearDown(userProvider.dispose);

      await formProvider.initialize(userProvider: userProvider, actor: actor);

      expect(formProvider.marriageLoadState, MarriageLoadState.error);
      expect(formProvider.isBiological, isTrue);
      expect(formProvider.canSubmit, isFalse);

      formProvider.setIsAdopted(true);

      expect(formProvider.isAdopted, isTrue);
      expect(formProvider.isBiological, isFalse);
      expect(formProvider.selectedMarriageId, isNull);
      expect(formProvider.canSubmit, isFalse);
    },
  );

  test('toggle adopsi mempertahankan pernikahan yang dipilih', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: const Right([_FamilyFormRepository.marriage]),
    );
    final userProvider = UserProvider(repository);
    final formProvider = FamilyMemberFormProvider();
    addTearDown(formProvider.dispose);
    addTearDown(userProvider.dispose);

    await formProvider.initialize(userProvider: userProvider, actor: actor);

    expect(formProvider.selectedMarriageId, 10);
    expect(formProvider.canSubmit, isFalse);

    formProvider.selectGender(PersonGender.male);
    expect(formProvider.canSubmit, isTrue);

    formProvider.setIsAdopted(true);

    expect(formProvider.isAdopted, isTrue);
    expect(formProvider.isBiological, isFalse);
    expect(formProvider.selectedMarriageId, 10);
    expect(formProvider.canSubmit, isTrue);
  });

  test('dropdown orang tua hanya memuat diri, anak, dan cucu', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: const Right([_FamilyFormRepository.marriage]),
    );
    final userProvider = UserProvider(repository);
    final formProvider = FamilyMemberFormProvider();
    addTearDown(formProvider.dispose);
    addTearDown(userProvider.dispose);

    await formProvider.initialize(userProvider: userProvider, actor: actor);

    expect(
      formProvider.availableParents.map((member) => member.nit),
      orderedEquals(['1', '1.1', '1.1.1']),
    );
  });

  test(
    'UserProvider tetap mengirim adopsi personal saat pemeriksaan pernikahan gagal',
    () async {
      final repository = _FamilyFormRepository(
        marriagesResult: Left(Failure('Tidak seharusnya dipanggil.')),
      );
      final userProvider = UserProvider(repository);
      addTearDown(userProvider.dispose);

      final created = await userProvider.addChild(
        parentId: 1,
        isBiological: false,
        marriageId: null,
        childData: const UserData(
          fullName: 'Anak Adopsi',
          gender: PersonGender.female,
        ),
      );

      expect(repository.getMarriagesCalls, 1);
      expect(repository.createChildCalls, 1);
      expect(repository.receivedIsBiological, isFalse);
      expect(repository.receivedMarriageId, isNull);
      expect(repository.receivedChildData?.nit, isNull);
      expect(created?.nit, 'SERVER-NIT');
    },
  );

  test('UserProvider menolak anak kandung tanpa pernikahan', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: const Right([_FamilyFormRepository.marriage]),
    );
    final userProvider = UserProvider(repository);
    addTearDown(userProvider.dispose);

    final created = await userProvider.addChild(
      parentId: 1,
      isBiological: true,
      marriageId: null,
      childData: const UserData(fullName: 'Anak Kandung'),
    );

    expect(created, isNull);
    expect(repository.createChildCalls, 0);
    expect(userProvider.errorMessage, contains('wajib memilih pernikahan'));
  });

  test(
    'form anak memblokir conflict dan legacy walau status adopsi aktif',
    () async {
      final histories = <List<FamilyTreeMarriage>>[
        const [
          _FamilyFormRepository.marriage,
          _FamilyFormRepository.wifeMarriage,
        ],
        const [_FamilyFormRepository.legacyMarriage],
      ];

      for (final history in histories) {
        final repository = _FamilyFormRepository(
          marriagesResult: Right(history),
        );
        final userProvider = UserProvider(repository);
        final formProvider = FamilyMemberFormProvider();

        await formProvider.initialize(userProvider: userProvider, actor: actor);
        formProvider.setIsAdopted(true);

        expect(formProvider.childCreationBlockingMessage, isNotEmpty);
        expect(formProvider.childDataInputsEnabled, isFalse);
        expect(formProvider.canSubmit, isFalse);

        formProvider.dispose();
        userProvider.dispose();
      }
    },
  );

  test(
    'UserProvider memblokir anak pada history conflict dan legacy',
    () async {
      final histories = <List<FamilyTreeMarriage>>[
        const [
          _FamilyFormRepository.marriage,
          _FamilyFormRepository.wifeMarriage,
        ],
        const [_FamilyFormRepository.legacyMarriage],
      ];

      for (final history in histories) {
        final repository = _FamilyFormRepository(
          marriagesResult: Right(history),
        );
        final userProvider = UserProvider(repository);

        final created = await userProvider.addChild(
          parentId: 1,
          isBiological: false,
          marriageId: null,
          childData: const UserData(fullName: 'Anak'),
        );

        expect(created, isNull);
        expect(repository.createChildCalls, 0);
        expect(userProvider.errorMessage, contains('belum dapat ditambahkan'));
        expect(userProvider.isSubmitting, isFalse);

        userProvider.dispose();
      }
    },
  );

  test(
    'UserProvider mengizinkan role husband yang konsisten setelah refresh authoritative',
    () async {
      final repository = _FamilyFormRepository(
        marriagesResult: const Right([_FamilyFormRepository.marriage]),
      );
      final userProvider = UserProvider(repository);
      addTearDown(userProvider.dispose);

      final created = await userProvider.addSpouse(
        memberId: 1,
        memberRole: MarriageRole.husband,
        spouseData: const UserData(fullName: 'Pasangan'),
      );

      expect(created?.marriageId, 10);
      expect(repository.getMarriagesCalls, 1);
      expect(repository.createMarriageCalls, 1);
      expect(repository.receivedMemberRole, MarriageRole.husband);
      expect(userProvider.isSubmitting, isFalse);
    },
  );

  test('UserProvider memblokir role yang berbeda dari role terkunci', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: const Right([_FamilyFormRepository.marriage]),
    );
    final userProvider = UserProvider(repository);
    addTearDown(userProvider.dispose);

    final created = await userProvider.addSpouse(
      memberId: 1,
      memberRole: MarriageRole.wife,
      spouseData: const UserData(fullName: 'Pasangan'),
    );

    expect(created, isNull);
    expect(repository.createMarriageCalls, 0);
    expect(userProvider.errorMessage, contains('dikunci sebagai Suami'));
    expect(userProvider.isSubmitting, isFalse);
  });

  test('UserProvider memblokir create untuk riwayat wife', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: const Right([_FamilyFormRepository.wifeMarriage]),
    );
    final userProvider = UserProvider(repository);
    addTearDown(userProvider.dispose);

    final created = await userProvider.addSpouse(
      memberId: 1,
      memberRole: MarriageRole.wife,
      spouseData: const UserData(fullName: 'Pasangan'),
    );

    expect(created, isNull);
    expect(repository.createMarriageCalls, 0);
    expect(userProvider.errorMessage, isNotEmpty);
    expect(userProvider.isSubmitting, isFalse);
  });

  test('UserProvider memblokir create untuk role yang konflik', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: const Right([
        _FamilyFormRepository.marriage,
        _FamilyFormRepository.wifeMarriage,
      ]),
    );
    final userProvider = UserProvider(repository);
    addTearDown(userProvider.dispose);

    final created = await userProvider.addSpouse(
      memberId: 1,
      memberRole: MarriageRole.husband,
      spouseData: const UserData(fullName: 'Pasangan'),
    );

    expect(created, isNull);
    expect(repository.createMarriageCalls, 0);
    expect(userProvider.errorMessage, contains('konflik'));
    expect(userProvider.isSubmitting, isFalse);
  });

  test('UserProvider memblokir create untuk marriage legacy', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: const Right([_FamilyFormRepository.legacyMarriage]),
    );
    final userProvider = UserProvider(repository);
    addTearDown(userProvider.dispose);

    final created = await userProvider.addSpouse(
      memberId: 1,
      memberRole: MarriageRole.husband,
      spouseData: const UserData(fullName: 'Pasangan'),
    );

    expect(created, isNull);
    expect(repository.createMarriageCalls, 0);
    expect(
      userProvider.errorMessage,
      contains('Peran Suami/Istri pada pasangan lama belum lengkap'),
    );
    expect(userProvider.isSubmitting, isFalse);
  });

  test('UserProvider memblokir POST saat refresh marriage gagal', () async {
    final repository = _FamilyFormRepository(
      marriagesResult: Left(Failure('Riwayat gagal dimuat.')),
    );
    final userProvider = UserProvider(repository);
    addTearDown(userProvider.dispose);

    final created = await userProvider.addSpouse(
      memberId: 1,
      memberRole: MarriageRole.husband,
      spouseData: const UserData(fullName: 'Pasangan'),
    );

    expect(created, isNull);
    expect(repository.getMarriagesCalls, 1);
    expect(repository.createMarriageCalls, 0);
    expect(userProvider.errorMessage, 'Riwayat gagal dimuat.');
    expect(userProvider.isSubmitting, isFalse);
  });

  test(
    'UserProvider menolak submit pasangan paralel sebelum POST kedua',
    () async {
      final gate = Completer<Either<Failure, List<FamilyTreeMarriage>>>();
      final repository = _FamilyFormRepository(
        marriagesResult: const Right([]),
        marriagesGate: gate,
      );
      final userProvider = UserProvider(repository);
      addTearDown(userProvider.dispose);

      final firstRequest = userProvider.addSpouse(
        memberId: 1,
        memberRole: MarriageRole.husband,
        spouseData: const UserData(fullName: 'Pasangan Pertama'),
      );
      await Future<void>.delayed(Duration.zero);

      final secondResult = await userProvider.addSpouse(
        memberId: 1,
        memberRole: MarriageRole.wife,
        spouseData: const UserData(fullName: 'Pasangan Kedua'),
      );

      expect(secondResult, isNull);
      expect(repository.createMarriageCalls, 0);
      expect(userProvider.errorMessage, contains('masih diproses'));

      gate.complete(const Right([]));
      final firstResult = await firstRequest;

      expect(firstResult, isNotNull);
      expect(repository.createMarriageCalls, 1);
      expect(repository.receivedMemberRole, MarriageRole.husband);
      expect(userProvider.isSubmitting, isFalse);
    },
  );

  test(
    'force refresh menunggu request aktif lalu mengambil history baru',
    () async {
      final gate = Completer<Either<Failure, List<FamilyTreeMarriage>>>();
      final repository = _FamilyFormRepository(
        marriagesResult: const Right([]),
        marriagesGate: gate,
      );
      final userProvider = UserProvider(repository);
      addTearDown(userProvider.dispose);

      final initialRequest = userProvider.getMarriagesForMember(1);
      await Future<void>.delayed(Duration.zero);
      final forcedRequest = userProvider.getMarriagesForMember(
        1,
        forceRefresh: true,
      );

      gate.complete(const Right([_FamilyFormRepository.marriage]));
      await initialRequest;
      final forcedResult = await forcedRequest;

      expect(repository.getMarriagesCalls, 2);
      expect(forcedResult, const [_FamilyFormRepository.marriage]);
    },
  );
}

class _FamilyFormRepository extends UserRepositoryImpl {
  _FamilyFormRepository({required this.marriagesResult, this.marriagesGate});

  static const marriage = FamilyTreeMarriage(
    marriageId: 10,
    marriageOrder: 1,
    memberRole: MarriageRole.husband,
    spouseRole: MarriageRole.wife,
    isRoleClassified: true,
    spouse: null,
    children: [],
  );

  static const wifeMarriage = FamilyTreeMarriage(
    marriageId: 11,
    marriageOrder: 2,
    status: 'divorced',
    memberRole: MarriageRole.wife,
    spouseRole: MarriageRole.husband,
    isRoleClassified: true,
    spouse: null,
    children: [],
  );

  static const legacyMarriage = FamilyTreeMarriage(
    marriageId: 12,
    marriageOrder: 3,
    spouse: null,
    children: [],
  );

  final Either<Failure, List<FamilyTreeMarriage>> marriagesResult;
  final Completer<Either<Failure, List<FamilyTreeMarriage>>>? marriagesGate;
  int getMarriagesCalls = 0;
  int createChildCalls = 0;
  int createMarriageCalls = 0;
  bool? receivedIsBiological;
  int? receivedMarriageId;
  UserData? receivedChildData;
  MarriageRole? receivedMemberRole;

  @override
  Future<Either<Failure, FamilyDirectoryResponse>> getFamilyMembers({
    String keyword = '',
    int perPage = 25,
  }) async {
    return const Right(
      FamilyDirectoryResponse(
        members: [
          FamilyDirectoryMember(
            userId: 1,
            familyTreeId: '1',
            nit: '1',
            level: 1,
            fullName: 'Anggota Utama',
          ),
          FamilyDirectoryMember(
            userId: 2,
            familyTreeId: '1.1',
            nit: '1.1',
            level: 2,
            fullName: 'Anggota Terhubung',
          ),
          FamilyDirectoryMember(
            userId: 3,
            familyTreeId: '1.1.1',
            nit: '1.1.1',
            level: 3,
            fullName: 'Cucu',
          ),
          FamilyDirectoryMember(
            userId: 4,
            familyTreeId: '1.1.1.1',
            nit: '1.1.1.1',
            level: 4,
            fullName: 'Cicit',
          ),
          FamilyDirectoryMember(
            userId: 5,
            familyTreeId: '2',
            nit: '2',
            level: 1,
            fullName: 'Cabang Lain',
          ),
        ],
        meta: FamilyDirectoryMeta(
          perPage: 25,
          total: 5,
          authenticatedMemberId: 1,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, UserData>> getById(String id) async {
    return Right(UserData(userId: int.parse(id), fullName: 'Anggota $id'));
  }

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    getMarriagesCalls++;
    if (marriagesGate != null) return marriagesGate!.future;
    return marriagesResult;
  }

  @override
  Future<Either<Failure, FamilyTreeNode>> createChild({
    required String memberId,
    required bool isBiological,
    int? marriageId,
    required UserData childData,
  }) async {
    createChildCalls++;
    receivedIsBiological = isBiological;
    receivedMarriageId = marriageId;
    receivedChildData = childData;
    return const Right(
      FamilyTreeNode(
        userId: 3,
        nit: 'SERVER-NIT',
        familyTreeId: 'server-owned-id',
        level: 2,
        fullName: 'Anak Adopsi',
        relationshipType: ChildRelationshipType.adopted,
      ),
    );
  }

  @override
  Future<Either<Failure, FamilyTreeMarriage>> createMarriage({
    required String memberId,
    required MarriageRole memberRole,
    required UserData spouseData,
  }) async {
    createMarriageCalls++;
    receivedMemberRole = memberRole;
    return const Right(marriage);
  }
}
