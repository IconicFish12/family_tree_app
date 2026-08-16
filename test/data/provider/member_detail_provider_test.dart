import 'dart:async';

import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/member_detail_provider.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  test(
    'error data cabang tidak diubah menjadi empty success dan dapat dicoba ulang',
    () async {
      final repository = _MemberDetailRepository();
      final provider = MemberDetailProvider(repository);

      await provider.load(1);

      expect(provider.state, MemberDetailState.success);
      expect(provider.directChildren.map((child) => child.userId), [2]);
      expect(provider.errorForChild(2), isNotNull);
      expect(provider.grandchildrenForChild(2), isEmpty);

      repository.failChildRequests = false;
      await provider.retryChildData(2);

      expect(provider.errorForChild(2), isNull);
      expect(provider.detailForChild(2)?.fullName, 'Anak');
      expect(provider.grandchildrenForChild(2).map((child) => child.userId), [
        3,
      ]);
    },
  );

  test(
    'anak adopsi personal dan cucunya berasal dari adopted_children tree',
    () async {
      final provider = MemberDetailProvider(_PersonalAdoptionRepository());

      await provider.load(53);

      expect(provider.state, MemberDetailState.success);
      expect(provider.descendantTreeError, isNull);
      expect(provider.directChildren.map((child) => child.userId), [424, 425]);
      expect(provider.directChildren.map((child) => child.fullName), [
        'TestAdopsi1',
        'testadopsi2',
      ]);
      expect(
        provider.directChildren.map((child) => child.relationshipType),
        everyElement(ChildRelationshipType.adopted),
      );
      expect(provider.grandchildrenForChild(424).map((child) => child.userId), [
        426,
      ]);
      expect(provider.hasCompleteTreeBranchFor(53), isTrue);
      expect(provider.hasCompleteTreeBranchFor(424), isTrue);
    },
  );

  test(
    'tree yang gagal tidak dianggap tanpa anak dan dapat dicoba ulang',
    () async {
      final repository = _PersonalAdoptionRepository()..failTree = true;
      final provider = MemberDetailProvider(repository);

      await provider.load(53);

      expect(provider.state, MemberDetailState.success);
      expect(provider.directChildren, isEmpty);
      expect(provider.descendantTreeError, 'Bagan gagal dimuat.');
      expect(provider.hasCompleteTreeBranchFor(53), isFalse);

      repository.failTree = false;
      await provider.retryDescendantTree();

      expect(provider.descendantTreeError, isNull);
      expect(provider.directChildren.map((child) => child.userId), [424, 425]);
    },
  );

  test('response load lama tidak menimpa detail load terbaru', () async {
    final repository = _DeferredMemberDetailRepository();
    final provider = MemberDetailProvider(repository);

    final oldLoad = provider.load(1);
    final freshLoad = provider.load(2);

    repository.completeMember(2, 'Data Baru');
    await freshLoad;
    expect(provider.member?.userId, 2);
    expect(provider.member?.fullName, 'Data Baru');

    repository.completeMember(1, 'Data Lama');
    await oldLoad;
    expect(provider.member?.userId, 2);
    expect(provider.member?.fullName, 'Data Baru');
  });

  test(
    'load yang selesai setelah provider dispose tidak menulis state',
    () async {
      final repository = _DeferredMemberDetailRepository();
      final provider = MemberDetailProvider(repository);

      final pendingLoad = provider.load(1);
      provider.dispose();
      repository.completeMember(1, 'Data Terlambat');

      await expectLater(pendingLoad, completes);
    },
  );
}

class _MemberDetailRepository extends UserRepositoryImpl {
  bool failChildRequests = true;

  static const child = FamilyTreeNode(
    userId: 2,
    familyTreeId: '1.1.1',
    level: 2,
    fullName: 'Anak',
  );
  static const grandchild = FamilyTreeNode(
    userId: 3,
    familyTreeId: '1.1.1.1.1',
    level: 3,
    fullName: 'Cucu',
  );
  static const rootMarriage = FamilyTreeMarriage(
    marriageId: 10,
    marriageOrder: 1,
    spouse: null,
    children: [child],
  );
  static const childMarriage = FamilyTreeMarriage(
    marriageId: 11,
    marriageOrder: 1,
    spouse: null,
    children: [grandchild],
  );
  static const tree = FamilyTreeNode(
    userId: 1,
    familyTreeId: '1',
    level: 1,
    fullName: 'Root',
    marriages: [rootMarriage],
  );

  @override
  Future<Either<Failure, UserData>> getById(String id) async {
    if (id == '1') {
      return const Right(UserData(userId: 1, fullName: 'Root'));
    }
    if (failChildRequests) {
      return Left(Failure('Detail anak gagal dimuat.'));
    }
    return const Right(UserData(userId: 2, fullName: 'Anak'));
  }

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    if (memberId == '1') {
      return const Right([rootMarriage]);
    }
    if (failChildRequests) {
      return Left(Failure('Data pernikahan anak gagal dimuat.'));
    }
    return const Right([childMarriage]);
  }

  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    return const Right(FamilyTreeResponse(root: tree, meta: FamilyTreeMeta()));
  }
}

class _PersonalAdoptionRepository extends UserRepositoryImpl {
  bool failTree = false;

  static const adoptedGrandchild = FamilyTreeNode(
    relationId: 218,
    parentId: 424,
    childId: 426,
    relationshipType: ChildRelationshipType.adopted,
    lineageOrder: 1,
    userId: 426,
    familyTreeId: '1.1.4.1.1.a.1.a.1',
    level: 5,
    fullName: 'Cucu Adopsi',
  );
  static const firstAdoptedChild = FamilyTreeNode(
    relationId: 216,
    parentId: 53,
    childId: 424,
    relationshipType: ChildRelationshipType.adopted,
    lineageOrder: 1,
    userId: 424,
    nit: '1.4.1.1',
    familyTreeId: '1.1.4.1.1.a.1',
    level: 4,
    fullName: 'TestAdopsi1',
    adoptedChildren: [adoptedGrandchild],
  );
  static const secondAdoptedChild = FamilyTreeNode(
    relationId: 217,
    parentId: 53,
    childId: 425,
    relationshipType: ChildRelationshipType.adopted,
    lineageOrder: 2,
    userId: 425,
    nit: '1.4.1.2',
    familyTreeId: '1.1.4.1.1.a.2',
    level: 4,
    fullName: 'testadopsi2',
  );
  static const root = FamilyTreeNode(
    userId: 53,
    nit: '1.4.1',
    familyTreeId: '1.1.4.1.1',
    level: 3,
    fullName: 'Rohmat',
    adoptedChildren: [secondAdoptedChild, firstAdoptedChild],
  );
  static const parentMarriage = FamilyTreeMarriage(
    marriageId: 26,
    marriageOrder: 1,
    spouse: null,
    children: [root],
  );
  static const parent = FamilyTreeNode(
    userId: 51,
    familyTreeId: '1.1.4.1',
    level: 2,
    fullName: 'Parent Rohmat',
    marriages: [parentMarriage],
  );
  static const ancestorMarriage = FamilyTreeMarriage(
    marriageId: 1,
    marriageOrder: 1,
    spouse: null,
    children: [parent],
  );
  static const responseRoot = FamilyTreeNode(
    userId: 1,
    familyTreeId: '1',
    level: 1,
    fullName: 'Roisah',
    marriages: [ancestorMarriage],
  );

  @override
  Future<Either<Failure, UserData>> getById(String id) async {
    final userId = int.parse(id);
    final names = <int, String>{
      53: 'Rohmat',
      424: 'TestAdopsi1',
      425: 'testadopsi2',
      426: 'Cucu Adopsi',
    };
    return Right(UserData(userId: userId, fullName: names[userId]));
  }

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    if (failTree) return Left(Failure('Bagan gagal dimuat.'));
    return const Right(
      FamilyTreeResponse(root: responseRoot, meta: FamilyTreeMeta()),
    );
  }
}

class _DeferredMemberDetailRepository extends UserRepositoryImpl {
  final Map<String, Completer<Either<Failure, UserData>>> _memberRequests = {};

  void completeMember(int memberId, String name) {
    _memberRequests['$memberId']!.complete(
      Right(UserData(userId: memberId, fullName: name)),
    );
  }

  @override
  Future<Either<Failure, UserData>> getById(String id) {
    return _memberRequests
        .putIfAbsent(id, Completer<Either<Failure, UserData>>.new)
        .future;
  }

  @override
  Future<Either<Failure, List<FamilyTreeMarriage>>> getMarriages(
    String memberId,
  ) async {
    return const Right([]);
  }

  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    return const Right(
      FamilyTreeResponse(
        root: FamilyTreeNode(
          userId: 2,
          familyTreeId: '2',
          level: 1,
          fullName: 'Data Baru',
        ),
        meta: FamilyTreeMeta(),
      ),
    );
  }
}
