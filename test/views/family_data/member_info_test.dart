import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:family_tree_app/views/family_data/member_info.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  testWidgets(
    'detail menampilkan gender, parent relation, role oriented, dan head spouse',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MemberInfoPage(memberId: 1, repository: _DetailRepository()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jenis Kelamin'), findsOneWidget);
      expect(find.text('Perempuan'), findsOneWidget);
      expect(find.text('Status Relasi'), findsOneWidget);
      expect(find.text('Anak Kandung'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Pasangan (1)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Istri'), findsOneWidget);
      expect(find.text('Suami'), findsOneWidget);
      expect(find.text('Kepala Keluarga'), findsOneWidget);
      expect(find.text('Jenis kelamin pasangan: Laki-laki'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('TestAdopsi1'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('TestAdopsi1'), findsOneWidget);
      expect(find.text('testadopsi2'), findsOneWidget);
      expect(find.text('Anak dan Cucu (2 anak)'), findsOneWidget);
      expect(find.text('Anak Adopsi'), findsNWidgets(2));
      expect(find.text('Belum ada data anak.'), findsNothing);
    },
  );

  testWidgets(
    'tree gagal ditampilkan sebagai data belum lengkap bukan nol anak',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MemberInfoPage(
            memberId: 1,
            repository: _UnavailableTreeRepository(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Anak dan Cucu (data belum lengkap)'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Anak dan Cucu (data belum lengkap)'), findsOneWidget);
      expect(
        find.textContaining(
          'Data anak adopsi tanpa pernikahan belum dapat dimuat.',
        ),
        findsOneWidget,
      );
      expect(find.text('Anak dan Cucu (0 anak)'), findsNothing);
      expect(find.text('Belum ada data anak.'), findsNothing);
      expect(find.text('Coba Lagi'), findsOneWidget);
    },
  );

  testWidgets('anggota dengan hanya anak adopsi tidak dapat dihapus', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemberInfoPage(
          memberId: 1,
          repository: _AdoptedOnlyDetailRepository(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Hapus Anggota'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    final deleteButton = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Hapus Anggota'),
    );
    expect(deleteButton.onPressed, isNull);
    expect(
      find.text(
        'Hapus pasangan dan keturunannya terlebih dahulu sebelum menghapus anggota ini.',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'konflik peran menonaktifkan tambah anak dan pasangan dengan petunjuk perbaikan',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MemberInfoPage(
            memberId: 1,
            repository: _RolePolicyDetailRepository(const [
              FamilyTreeMarriage(
                marriageId: 20,
                marriageOrder: 1,
                memberRole: MarriageRole.husband,
                spouseRole: MarriageRole.wife,
                isRoleClassified: true,
                spouse: FamilyTreeSpouse(
                  userId: 20,
                  familyTreeId: '1.0.1',
                  level: 1,
                  fullName: 'Pasangan Pertama',
                ),
                children: [],
              ),
              FamilyTreeMarriage(
                marriageId: 21,
                marriageOrder: 2,
                memberRole: MarriageRole.wife,
                spouseRole: MarriageRole.husband,
                isRoleClassified: true,
                spouse: FamilyTreeSpouse(
                  userId: 21,
                  familyTreeId: '1.0.2',
                  level: 1,
                  fullName: 'Pasangan Kedua',
                ),
                children: [],
              ),
            ]),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Tambah Pasangan'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final addChild = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tambah Anak'),
      );
      final addMarriage = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tambah Pasangan'),
      );
      expect(addChild.onPressed, isNull);
      expect(addMarriage.onPressed, isNull);
      expect(
        find.text('Rapikan data pernikahan terlebih dahulu'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          'hapus anak pada pernikahan yang salah terlebih dahulu, lalu hapus pasangan',
        ),
        findsOneWidget,
      );
      expect(find.text('Pasangan Pertama'), findsWidgets);
      expect(find.text('Pasangan Kedua'), findsWidgets);
    },
  );

  testWidgets('aksi tambah mengikuti policy peran anggota', (tester) async {
    final cases =
        <
          ({
            String name,
            List<FamilyTreeMarriage> marriages,
            bool canAddChild,
            bool canAddMarriage,
          })
        >[
          (
            name: 'unset',
            marriages: const [],
            canAddChild: true,
            canAddMarriage: true,
          ),
          (
            name: 'husband',
            marriages: [_classifiedMarriage(MarriageRole.husband)],
            canAddChild: true,
            canAddMarriage: true,
          ),
          (
            name: 'wife',
            marriages: [_classifiedMarriage(MarriageRole.wife)],
            canAddChild: true,
            canAddMarriage: false,
          ),
          (
            name: 'legacy',
            marriages: const [
              FamilyTreeMarriage(
                marriageId: 40,
                marriageOrder: 1,
                spouse: null,
                children: [],
              ),
            ],
            canAddChild: false,
            canAddMarriage: false,
          ),
        ];

    for (final testCase in cases) {
      await tester.pumpWidget(
        MaterialApp(
          home: MemberInfoPage(
            key: ValueKey(testCase.name),
            memberId: 1,
            repository: _RolePolicyDetailRepository(testCase.marriages),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Tambah Pasangan'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final addChild = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tambah Anak'),
      );
      final addMarriage = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Tambah Pasangan'),
      );
      expect(
        addChild.onPressed != null,
        testCase.canAddChild,
        reason: testCase.name,
      );
      expect(
        addMarriage.onPressed != null,
        testCase.canAddMarriage,
        reason: testCase.name,
      );
    }
  });
}

FamilyTreeMarriage _classifiedMarriage(MarriageRole memberRole) {
  final spouseRole = memberRole == MarriageRole.husband
      ? MarriageRole.wife
      : MarriageRole.husband;
  return FamilyTreeMarriage(
    marriageId: memberRole == MarriageRole.husband ? 30 : 31,
    marriageOrder: 1,
    memberRole: memberRole,
    spouseRole: spouseRole,
    isRoleClassified: true,
    spouse: const FamilyTreeSpouse(
      userId: 30,
      familyTreeId: '1.0.1',
      level: 1,
      fullName: 'Pasangan',
    ),
    children: const [],
  );
}

class _DetailRepository extends UserRepositoryImpl {
  @override
  Future<Either<Failure, UserData>> getById(String id) async {
    if (id == '3') {
      return const Right(
        UserData(userId: 3, nit: '1.1', fullName: 'TestAdopsi1'),
      );
    }
    if (id == '4') {
      return const Right(
        UserData(userId: 4, nit: '1.2', fullName: 'testadopsi2'),
      );
    }
    return const Right(
      UserData(
        userId: 1,
        nit: '1',
        fullName: 'Roisah',
        gender: PersonGender.female,
        parentRelation: ParentChildRelationData(
          relationId: 100,
          parentId: 9,
          childId: 1,
          relationshipType: ChildRelationshipType.biological,
        ),
      ),
    );
  }

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    if (memberId == '3' || memberId == '4') return const Right([]);
    return const Right([
      FamilyTreeMarriage(
        marriageId: 10,
        marriageOrder: 1,
        memberRole: MarriageRole.wife,
        spouseRole: MarriageRole.husband,
        isRoleClassified: true,
        familyHeadPosition: FamilyHeadPosition.spouse,
        familyHeadUserId: 2,
        spouse: FamilyTreeSpouse(
          userId: 2,
          familyTreeId: '1.0.1',
          level: 1,
          fullName: 'K. Iskandar',
          gender: PersonGender.male,
        ),
        children: [],
      ),
    ]);
  }

  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    return const Right(
      FamilyTreeResponse(
        root: FamilyTreeNode(
          userId: 1,
          nit: '1',
          familyTreeId: '1',
          level: 1,
          fullName: 'Roisah',
          adoptedChildren: [
            FamilyTreeNode(
              relationId: 30,
              parentId: 1,
              childId: 3,
              relationshipType: ChildRelationshipType.adopted,
              lineageOrder: 1,
              userId: 3,
              nit: '1.1',
              familyTreeId: '1.a.1',
              level: 2,
              fullName: 'TestAdopsi1',
            ),
            FamilyTreeNode(
              relationId: 31,
              parentId: 1,
              childId: 4,
              relationshipType: ChildRelationshipType.adopted,
              lineageOrder: 2,
              userId: 4,
              nit: '1.2',
              familyTreeId: '1.a.2',
              level: 2,
              fullName: 'testadopsi2',
            ),
          ],
        ),
        meta: FamilyTreeMeta(authenticatedMemberId: 1, subtreeRootId: 1),
      ),
    );
  }
}

class _UnavailableTreeRepository extends _DetailRepository {
  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    return Left(Failure('Bagan gagal dimuat.'));
  }
}

class _AdoptedOnlyDetailRepository extends _DetailRepository {
  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    return const Right([]);
  }
}

class _RolePolicyDetailRepository extends _DetailRepository {
  final List<FamilyTreeMarriage> memberMarriages;

  _RolePolicyDetailRepository(this.memberMarriages);

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    if (memberId != '1') return const Right([]);
    return Right(memberMarriages);
  }
}
