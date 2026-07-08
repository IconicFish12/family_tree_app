import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/foundation.dart';

enum TreeViewState { initial, loading, success, error }

class TreeProvider extends ChangeNotifier {
  final UserRepositoryImpl _repository;

  TreeProvider(this._repository);

  TreeViewState _state = TreeViewState.initial;
  TreeViewState get state => _state;

  FamilyTreeNode? _currentTree;
  FamilyTreeNode? get currentTree => _currentTree;

  String? _currentFamilyTreeId;
  String? get currentFamilyTreeId => _currentFamilyTreeId;

  String? _currentTitle;
  String? get currentTitle => _currentTitle;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final List<_TreeHistoryEntry> _history = [];
  bool get canGoBack => _history.isNotEmpty;

  Future<void> initialize({
    String? initialFamilyTreeId,
    String? initialTitle,
    String? fallbackRootFamilyTreeId,
  }) async {
    final resolvedId =
        _normalizeFamilyTreeId(initialFamilyTreeId) ??
        _resolveRootFamilyTreeId(fallbackRootFamilyTreeId);

    debugPrint(
      '[TreeProvider] initialize initialFamilyTreeId=$initialFamilyTreeId '
      'fallbackRootFamilyTreeId=$fallbackRootFamilyTreeId resolvedId=$resolvedId '
      'initialTitle=$initialTitle',
    );

    _history.clear();
    _currentFamilyTreeId = resolvedId;
    _currentTitle = initialTitle;

    if (resolvedId == null || resolvedId.isEmpty) {
      _state = TreeViewState.error;
      _errorMessage = 'ID pohon keluarga belum tersedia.';
      _currentTree = null;
      notifyListeners();
      return;
    }

    await loadCurrentTree();
  }

  Future<void> loadCurrentTree() async {
    final familyTreeId = _normalizeFamilyTreeId(_currentFamilyTreeId);

    debugPrint(
      '[TreeProvider] loadCurrentTree start familyTreeId=$familyTreeId '
      'historyDepth=${_history.length}',
    );

    if (familyTreeId == null || familyTreeId.isEmpty) {
      _state = TreeViewState.error;
      _errorMessage = 'ID pohon keluarga tidak valid';
      _currentTree = null;
      notifyListeners();
      return;
    }

    _state = TreeViewState.loading;
    _errorMessage = null;
    _currentTree = null;
    notifyListeners();

    final result = await _repository.getTree(familyTreeId);

    result.fold(
      (failure) {
        debugPrint(
          '[TreeProvider] loadCurrentTree failed familyTreeId=$familyTreeId '
          'message=${failure.message}',
        );
        _state = TreeViewState.error;
        _errorMessage = failure.message;
        notifyListeners();
      },
      (tree) {
        debugPrint(
          '[TreeProvider] loadCurrentTree success familyTreeId=$familyTreeId '
          'resolvedRoot=${tree.familyTreeId} childCount=${tree.children.length}',
        );
        _state = TreeViewState.success;
        _errorMessage = null;
        _currentTree = tree;
        _currentFamilyTreeId = tree.familyTreeId;
        _currentTitle = tree.fullName;
        notifyListeners();
      },
    );
  }

  Future<void> openSubtree(FamilyTreeNode node) async {
    if (!node.canOpenSubtree || _currentTree == null) {
      debugPrint(
        '[TreeProvider] openSubtree ignored familyTreeId=${node.familyTreeId} '
        'hasChildren=${node.hasChildren} currentTreeNull=${_currentTree == null}',
      );
      return;
    }

    if (_state == TreeViewState.loading) {
      debugPrint(
        '[TreeProvider] openSubtree ignored while loading '
        'target=${node.familyTreeId}',
      );
      return;
    }

    final nextFamilyTreeId = _normalizeFamilyTreeId(node.familyTreeId);
    debugPrint(
      '[TreeProvider] openSubtree current=$_currentFamilyTreeId '
      'target=$nextFamilyTreeId title=${node.fullName}',
    );

    if (nextFamilyTreeId == null || nextFamilyTreeId.isEmpty) {
      _state = TreeViewState.error;
      _errorMessage = 'ID pohon keluarga tidak valid';
      notifyListeners();
      return;
    }

    _history.add(
      _TreeHistoryEntry(
        familyTreeId: _currentFamilyTreeId!,
        title: _currentTitle,
        tree: _currentTree!,
      ),
    );

    _currentFamilyTreeId = nextFamilyTreeId;
    _currentTitle = node.fullName;

    await loadCurrentTree();
  }

  bool restorePreviousTree() {
    if (_history.isEmpty) {
      debugPrint('[TreeProvider] restorePreviousTree no history');
      return false;
    }

    final previous = _history.removeLast();
    debugPrint(
      '[TreeProvider] restorePreviousTree familyTreeId=${previous.familyTreeId} '
      'remainingHistory=${_history.length}',
    );

    _currentFamilyTreeId = previous.familyTreeId;
    _currentTitle = previous.title;
    _currentTree = previous.tree;
    _errorMessage = null;
    _state = TreeViewState.success;
    notifyListeners();
    return true;
  }

  Future<void> refreshCurrentTree() async {
    debugPrint(
      '[TreeProvider] refreshCurrentTree familyTreeId=$_currentFamilyTreeId',
    );
    await loadCurrentTree();
  }

  void reset() {
    debugPrint('[TreeProvider] reset');
    _state = TreeViewState.initial;
    _currentTree = null;
    _currentFamilyTreeId = null;
    _currentTitle = null;
    _errorMessage = null;
    _history.clear();
    notifyListeners();
  }

  String? _normalizeFamilyTreeId(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String? _resolveRootFamilyTreeId(String? value) {
    final normalized = _normalizeFamilyTreeId(value);
    if (normalized == null) {
      return null;
    }
    return normalized.split('.').first;
  }
}

class _TreeHistoryEntry {
  final String familyTreeId;
  final String? title;
  final FamilyTreeNode tree;

  const _TreeHistoryEntry({
    required this.familyTreeId,
    required this.title,
    required this.tree,
  });
}
