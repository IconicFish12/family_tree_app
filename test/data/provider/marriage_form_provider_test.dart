import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/marriage_form_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  const actor = UserData(userId: 1, nit: '1', fullName: 'Anggota Utama');

  test(
    'riwayat kosong meminta peran eksplisit dan tidak menebak dari gender',
    () async {
      final repository = _MarriageFormRepository(
        detailResult: const Right(
          UserData(
            userId: 1,
            fullName: 'Anggota Utama',
            gender: PersonGender.male,
          ),
        ),
        marriagesResult: const Right([]),
      );
      final userProvider = UserProvider(repository);
      final formProvider = MarriageFormProvider();
      addTearDown(formProvider.dispose);
      addTearDown(userProvider.dispose);

      await formProvider.initialize(userProvider: userProvider, actor: actor);

      expect(formProvider.rolePolicy, isNotNull);
      expect(formProvider.policyGuidanceMessage, isNotEmpty);
      expect(formProvider.canChooseRole, isTrue);
      expect(formProvider.spouseInputsEnabled, isTrue);
      expect(formProvider.memberRole, isNull);
      expect(formProvider.canSubmit, isFalse);

      formProvider.selectMemberRole(MarriageRole.wife);
      expect(formProvider.memberRole, MarriageRole.wife);
      expect(formProvider.spouseGender, PersonGender.male);
      expect(formProvider.roleCompatibilityError, isNotNull);
      expect(formProvider.canSubmit, isFalse);

      formProvider.selectMemberRole(MarriageRole.husband);
      expect(formProvider.spouseGender, PersonGender.female);
      expect(formProvider.roleCompatibilityError, isNull);
      expect(formProvider.canSubmit, isTrue);
    },
  );

  test(
    'riwayat Suami yang konsisten mengunci peran dan masih boleh menambah Istri',
    () async {
      final repository = _MarriageFormRepository(
        marriagesResult: Right([
          _classifiedMarriage(10, MarriageRole.husband),
          _classifiedMarriage(11, MarriageRole.husband),
        ]),
      );
      final userProvider = UserProvider(repository);
      final formProvider = MarriageFormProvider();
      addTearDown(formProvider.dispose);
      addTearDown(userProvider.dispose);

      await formProvider.initialize(userProvider: userProvider, actor: actor);

      expect(formProvider.memberRole, MarriageRole.husband);
      expect(formProvider.spouseGender, PersonGender.female);
      expect(formProvider.isRoleLocked, isTrue);
      expect(formProvider.canChooseRole, isFalse);
      expect(formProvider.hasBlockingIssue, isFalse);
      expect(formProvider.spouseInputsEnabled, isTrue);
      expect(formProvider.canSubmit, isTrue);

      formProvider.selectMemberRole(MarriageRole.wife);
      expect(formProvider.memberRole, MarriageRole.husband);
      expect(formProvider.canSubmit, isTrue);
    },
  );

  test(
    'riwayat Istri yang konsisten terkunci dan memblokir pasangan baru',
    () async {
      final repository = _MarriageFormRepository(
        marriagesResult: Right([_classifiedMarriage(20, MarriageRole.wife)]),
      );
      final userProvider = UserProvider(repository);
      final formProvider = MarriageFormProvider();
      addTearDown(formProvider.dispose);
      addTearDown(userProvider.dispose);

      await formProvider.initialize(userProvider: userProvider, actor: actor);

      expect(formProvider.memberRole, MarriageRole.wife);
      expect(formProvider.isRoleLocked, isTrue);
      expect(formProvider.hasBlockingIssue, isTrue);
      expect(formProvider.blockingMessage, isNotEmpty);
      expect(formProvider.spouseInputsEnabled, isFalse);
      expect(formProvider.canSubmit, isFalse);
    },
  );

  test('campuran peran Suami dan Istri memblokir formulir', () async {
    final repository = _MarriageFormRepository(
      marriagesResult: Right([
        _classifiedMarriage(30, MarriageRole.husband),
        _classifiedMarriage(31, MarriageRole.wife),
      ]),
    );
    final userProvider = UserProvider(repository);
    final formProvider = MarriageFormProvider();
    addTearDown(formProvider.dispose);
    addTearDown(userProvider.dispose);

    await formProvider.initialize(userProvider: userProvider, actor: actor);

    expect(formProvider.hasBlockingIssue, isTrue);
    expect(formProvider.blockingMessage, isNotEmpty);
    expect(formProvider.spouseInputsEnabled, isFalse);
    expect(formProvider.canSubmit, isFalse);
  });

  test('riwayat lama tanpa klasifikasi peran memblokir formulir', () async {
    final repository = _MarriageFormRepository(
      marriagesResult: const Right([
        FamilyTreeMarriage(
          marriageId: 40,
          marriageOrder: 1,
          isRoleClassified: false,
          spouse: null,
          children: [],
        ),
      ]),
    );
    final userProvider = UserProvider(repository);
    final formProvider = MarriageFormProvider();
    addTearDown(formProvider.dispose);
    addTearDown(userProvider.dispose);

    await formProvider.initialize(userProvider: userProvider, actor: actor);

    expect(formProvider.hasBlockingIssue, isTrue);
    expect(formProvider.blockingMessage, isNotEmpty);
    expect(formProvider.spouseInputsEnabled, isFalse);
    expect(formProvider.canSubmit, isFalse);
  });

  test(
    'gagal memuat pernikahan memblokir sampai muat ulang berhasil',
    () async {
      final repository = _MarriageFormRepository(
        marriagesResult: Left(Failure('Riwayat tidak dapat dimuat.')),
      );
      final userProvider = UserProvider(repository);
      final formProvider = MarriageFormProvider();
      addTearDown(formProvider.dispose);
      addTearDown(userProvider.dispose);

      await formProvider.initialize(userProvider: userProvider, actor: actor);

      expect(repository.getMarriagesCalls, 1);
      expect(formProvider.marriageError, 'Riwayat tidak dapat dimuat.');
      expect(formProvider.rolePolicy, isNull);
      expect(formProvider.hasBlockingIssue, isTrue);
      expect(formProvider.spouseInputsEnabled, isFalse);
      expect(formProvider.canSubmit, isFalse);

      repository.marriagesResult = const Right([]);
      await formProvider.retrySelectedMemberContext(userProvider: userProvider);

      expect(repository.getMarriagesCalls, 2);
      expect(formProvider.marriageError, isNull);
      expect(formProvider.rolePolicy, isNotNull);
      expect(formProvider.canChooseRole, isTrue);
      expect(formProvider.spouseInputsEnabled, isTrue);
    },
  );

  test(
    'selalu memuat ulang riwayat otoritatif walau cache sudah ada',
    () async {
      final repository = _MarriageFormRepository(
        marriagesResult: Right([_classifiedMarriage(50, MarriageRole.husband)]),
      );
      final userProvider = UserProvider(repository);
      final formProvider = MarriageFormProvider();
      addTearDown(formProvider.dispose);
      addTearDown(userProvider.dispose);

      await userProvider.getMarriagesForMember(1);
      repository.marriagesResult = const Right([]);

      await formProvider.initialize(userProvider: userProvider, actor: actor);

      expect(repository.getMarriagesCalls, 2);
      expect(formProvider.memberRole, isNull);
      expect(formProvider.canChooseRole, isTrue);
    },
  );

  test(
    'kegagalan detail gender tidak menebak peran atau memblokir riwayat valid',
    () async {
      final repository = _MarriageFormRepository(
        detailResult: Left(Failure('Detail anggota gagal dimuat.')),
        marriagesResult: const Right([]),
      );
      final userProvider = UserProvider(repository);
      final formProvider = MarriageFormProvider();
      addTearDown(formProvider.dispose);
      addTearDown(userProvider.dispose);

      await formProvider.initialize(userProvider: userProvider, actor: actor);

      expect(formProvider.selectedMemberDetail, isNull);
      expect(formProvider.memberDetailError, isNotNull);
      expect(formProvider.memberRole, isNull);

      formProvider.selectMemberRole(MarriageRole.wife);

      expect(formProvider.spouseGender, PersonGender.male);
      expect(formProvider.roleCompatibilityError, isNull);
      expect(formProvider.canSubmit, isTrue);
    },
  );
}

FamilyTreeMarriage _classifiedMarriage(int id, MarriageRole memberRole) {
  return FamilyTreeMarriage(
    marriageId: id,
    marriageOrder: id,
    memberRole: memberRole,
    spouseRole: memberRole == MarriageRole.husband
        ? MarriageRole.wife
        : MarriageRole.husband,
    isRoleClassified: true,
    spouse: null,
    children: const [],
  );
}

class _MarriageFormRepository extends UserRepositoryImpl {
  _MarriageFormRepository({
    this.detailResult = const Right(
      UserData(userId: 1, fullName: 'Anggota Utama'),
    ),
    required this.marriagesResult,
  });

  Either<Failure, UserData> detailResult;
  Either<Failure, List<FamilyTreeMarriage>> marriagesResult;
  int getMarriagesCalls = 0;

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
        ],
        meta: FamilyDirectoryMeta(
          perPage: 25,
          total: 2,
          authenticatedMemberId: 1,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, UserData>> getById(String id) async => detailResult;

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    getMarriagesCalls++;
    return marriagesResult;
  }
}
