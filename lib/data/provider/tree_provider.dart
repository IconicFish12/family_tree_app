import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/foundation.dart';

enum TreeViewState { initial, loading, success, error }

class TreeProvider extends ChangeNotifier {
  static const int visibleLevels = 3;

  final UserRepository _repository;

  TreeProvider(this._repository);

  TreeViewState _state = TreeViewState.initial;
  TreeViewState get state => _state;

  FamilyTreeNode? _fullTree;
  FamilyTreeNode? get fullTree => _fullTree;

  FamilyTreeMeta? _meta;
  FamilyTreeMeta? get meta => _meta;

  FamilyTreeNode? _currentRoot;
  FamilyTreeNode? get currentRoot => _currentRoot;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final List<FamilyTreeNode> _history = [];
  bool get canGoBack => _history.isNotEmpty;
  int _requestEpoch = 0;
  bool _isDisposed = false;

  Future<void> initialize({bool preserveNavigation = false}) async {
    if (_isDisposed) return;
    final epoch = ++_requestEpoch;
    final previousRootId = preserveNavigation ? _currentRoot?.userId : null;
    final previousHistoryIds = preserveNavigation
        ? _history.map((node) => node.userId).whereType<int>().toList()
        : const <int>[];

    _state = TreeViewState.loading;
    _errorMessage = null;
    _notifyListeners();

    final result = await _repository.getTree();
    if (!_isCurrent(epoch)) return;
    result.fold(
      (failure) {
        _state = TreeViewState.error;
        _errorMessage = failure.message;
      },
      (response) {
        _fullTree = response.root;
        _meta = response.meta;
        _restoreNavigation(
          response.root,
          previousRootId: previousRootId,
          previousHistoryIds: previousHistoryIds,
        );
        _state = TreeViewState.success;
      },
    );
    _notifyListeners();
  }

  int relativeLevel(FamilyTreeNode node) {
    final root = _currentRoot;
    if (root == null) return 1;
    return (node.level - root.level) + 1;
  }

  bool isVisibleAtCurrentDepth(FamilyTreeNode node) {
    final level = relativeLevel(node);
    return level >= 1 && level <= visibleLevels;
  }

  bool canOpenSubtree(FamilyTreeNode node) {
    if (!node.hasDescendants) return false;
    return relativeLevel(node) >= visibleLevels;
  }

  Future<void> openSubtree(FamilyTreeNode node) async {
    if (_isDisposed) return;
    final matchedNode = _fullTree?.findByUserId(node.userId);
    if (matchedNode == null || !matchedNode.hasDescendants) {
      return;
    }

    if (_currentRoot != null) {
      _history.add(_currentRoot!);
    }

    _currentRoot = matchedNode;
    _state = TreeViewState.success;
    _notifyListeners();
  }

  bool restorePreviousTree() {
    if (_isDisposed || _history.isEmpty) return false;
    _currentRoot = _history.removeLast();
    _state = TreeViewState.success;
    _notifyListeners();
    return true;
  }

  Future<void> refreshCurrentTree() async {
    await initialize(preserveNavigation: true);
  }

  void reset({bool shouldNotify = true}) {
    if (_isDisposed) return;
    _requestEpoch++;
    _state = TreeViewState.initial;
    _fullTree = null;
    _meta = null;
    _currentRoot = null;
    _errorMessage = null;
    _history.clear();
    if (shouldNotify) {
      _notifyListeners();
    }
  }

  void _restoreNavigation(
    FamilyTreeNode freshRoot, {
    required int? previousRootId,
    required List<int> previousHistoryIds,
  }) {
    if (previousRootId == null) {
      _currentRoot = freshRoot;
      _history.clear();
      return;
    }

    final restoredRoot = freshRoot.findByUserId(previousRootId);
    if (restoredRoot == null) {
      _currentRoot = freshRoot;
      _history.clear();
      return;
    }

    _currentRoot = restoredRoot;
    _history
      ..clear()
      ..addAll(
        previousHistoryIds
            .map(freshRoot.findByUserId)
            .whereType<FamilyTreeNode>()
            .where((node) => node.userId != restoredRoot.userId),
      );
  }

  bool _isCurrent(int epoch) => !_isDisposed && epoch == _requestEpoch;

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _requestEpoch++;
    super.dispose();
  }
}
