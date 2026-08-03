import 'dart:async';

import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

void main() {
  test(
    'subtree adopted recursive mengikuti batas tiga level dan history',
    () async {
      const greatGrandchild = FamilyTreeNode(
        userId: 4,
        familyTreeId: '1.a.1.a.1.a.1',
        level: 4,
        fullName: 'Cicit Adopsi',
      );
      const grandchild = FamilyTreeNode(
        userId: 3,
        familyTreeId: '1.a.1.a.1',
        level: 3,
        fullName: 'Cucu Adopsi',
        adoptedChildren: [greatGrandchild],
      );
      const child = FamilyTreeNode(
        userId: 2,
        familyTreeId: '1.a.1',
        level: 2,
        fullName: 'Anak Adopsi',
        adoptedChildren: [grandchild],
      );
      const root = FamilyTreeNode(
        userId: 1,
        familyTreeId: '1',
        level: 1,
        fullName: 'Root',
        adoptedChildren: [child],
      );
      final repository = _TreeRepository(
        const Right(
          FamilyTreeResponse(
            root: root,
            meta: FamilyTreeMeta(authenticatedMemberId: 1, subtreeRootId: 1),
          ),
        ),
      );
      final provider = TreeProvider(repository);

      await provider.initialize();

      expect(provider.state, TreeViewState.success);
      expect(provider.currentRoot, same(root));
      expect(provider.meta?.authenticatedMemberId, 1);
      expect(provider.meta?.subtreeRootId, 1);
      expect(provider.isVisibleAtCurrentDepth(grandchild), isTrue);
      expect(provider.isVisibleAtCurrentDepth(greatGrandchild), isFalse);
      expect(provider.canOpenSubtree(child), isFalse);
      expect(provider.canOpenSubtree(grandchild), isTrue);

      await provider.openSubtree(grandchild);

      expect(provider.currentRoot, same(grandchild));
      expect(provider.canGoBack, isTrue);
      expect(provider.isVisibleAtCurrentDepth(greatGrandchild), isTrue);

      expect(provider.restorePreviousTree(), isTrue);
      expect(provider.currentRoot, same(root));
      expect(provider.canGoBack, isFalse);
    },
  );

  test('reset membatalkan response initialize yang masih berjalan', () async {
    const staleRoot = FamilyTreeNode(
      userId: 1,
      familyTreeId: '1',
      level: 1,
      fullName: 'Data Lama',
    );
    final repository = _DeferredTreeRepository();
    final provider = TreeProvider(repository);

    final pendingInitialize = provider.initialize();
    expect(provider.state, TreeViewState.loading);

    provider.reset();
    repository.request.complete(
      const Right(FamilyTreeResponse(root: staleRoot, meta: FamilyTreeMeta())),
    );
    await pendingInitialize;

    expect(provider.state, TreeViewState.initial);
    expect(provider.fullTree, isNull);
    expect(provider.currentRoot, isNull);
    expect(provider.meta, isNull);
  });

  test(
    'refresh mempertahankan current subtree dan history dengan data baru',
    () async {
      const oldGreatGrandchild = FamilyTreeNode(
        userId: 4,
        familyTreeId: '1.a.1.a.1.a.1',
        level: 4,
        fullName: 'Cicit Lama',
      );
      const oldGrandchild = FamilyTreeNode(
        userId: 3,
        familyTreeId: '1.a.1.a.1',
        level: 3,
        fullName: 'Cucu Lama',
        adoptedChildren: [oldGreatGrandchild],
      );
      const oldRoot = FamilyTreeNode(
        userId: 1,
        familyTreeId: '1',
        level: 1,
        fullName: 'Root Lama',
        adoptedChildren: [oldGrandchild],
      );
      const freshGreatGrandchild = FamilyTreeNode(
        userId: 4,
        familyTreeId: '1.a.1.a.1.a.1',
        level: 4,
        fullName: 'Cicit Baru',
      );
      const freshGrandchild = FamilyTreeNode(
        userId: 3,
        familyTreeId: '1.a.1.a.1',
        level: 3,
        fullName: 'Cucu Baru',
        adoptedChildren: [freshGreatGrandchild],
      );
      const freshRoot = FamilyTreeNode(
        userId: 1,
        familyTreeId: '1',
        level: 1,
        fullName: 'Root Baru',
        adoptedChildren: [freshGrandchild],
      );
      final repository = _SequenceTreeRepository([
        const Right(FamilyTreeResponse(root: oldRoot, meta: FamilyTreeMeta())),
        const Right(
          FamilyTreeResponse(root: freshRoot, meta: FamilyTreeMeta()),
        ),
      ]);
      final provider = TreeProvider(repository);

      await provider.initialize();
      await provider.openSubtree(oldGrandchild);
      await provider.refreshCurrentTree();

      expect(provider.currentRoot, same(freshGrandchild));
      expect(provider.currentRoot?.fullName, 'Cucu Baru');
      expect(provider.canGoBack, isTrue);
      expect(provider.restorePreviousTree(), isTrue);
      expect(provider.currentRoot, same(freshRoot));
      expect(provider.currentRoot?.fullName, 'Root Baru');
    },
  );
}

class _TreeRepository extends UserRepositoryImpl {
  final Either<Failure, FamilyTreeResponse> result;

  _TreeRepository(this.result);

  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async => result;
}

class _DeferredTreeRepository extends UserRepositoryImpl {
  final request = Completer<Either<Failure, FamilyTreeResponse>>();

  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() => request.future;
}

class _SequenceTreeRepository extends UserRepositoryImpl {
  final List<Either<Failure, FamilyTreeResponse>> results;
  int _index = 0;

  _SequenceTreeRepository(this.results);

  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    return results[_index++];
  }
}
