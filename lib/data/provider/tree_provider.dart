import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/foundation.dart';

enum TreeViewState { initial, loading, success, error }

class TreeProvider extends ChangeNotifier {
  static const int visibleLevels = 3;

  final UserRepositoryImpl _repository;

  TreeProvider(this._repository);

  TreeViewState _state = TreeViewState.initial;
  TreeViewState get state => _state;

  FamilyTreeNode? _fullTree;
  FamilyTreeNode? get fullTree => _fullTree;

  FamilyTreeNode? _currentRoot;
  FamilyTreeNode? get currentRoot => _currentRoot;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  final List<FamilyTreeNode> _history = [];
  bool get canGoBack => _history.isNotEmpty;

  Future<void> initialize() async {
    _state = TreeViewState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getTree();
    result.fold(
      (failure) {
        _state = TreeViewState.error;
        _errorMessage = failure.message;
      },
      (tree) {
        _fullTree = tree;
        _currentRoot = tree;
        _history.clear();
        _state = TreeViewState.success;
      },
    );
    notifyListeners();
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
    final matchedNode = _findNodeByUserId(_fullTree, node.userId);
    if (matchedNode == null || !matchedNode.hasDescendants) {
      return;
    }

    if (_currentRoot != null) {
      _history.add(_currentRoot!);
    }

    _currentRoot = matchedNode;
    _state = TreeViewState.success;
    notifyListeners();
  }

  bool restorePreviousTree() {
    if (_history.isEmpty) return false;
    _currentRoot = _history.removeLast();
    _state = TreeViewState.success;
    notifyListeners();
    return true;
  }

  Future<void> refreshCurrentTree() async {
    await initialize();
  }

  void reset({bool shouldNotify = true}) {
    _state = TreeViewState.initial;
    _fullTree = null;
    _currentRoot = null;
    _errorMessage = null;
    _history.clear();
    if (shouldNotify) {
      notifyListeners();
    }
  }

  FamilyTreeNode? _findNodeByUserId(FamilyTreeNode? node, int? userId) {
    if (node == null || userId == null) return null;
    if (node.userId == userId) {
      return node;
    }

    for (final marriage in node.marriages) {
      for (final child in marriage.children) {
        final result = _findNodeByUserId(child, userId);
        if (result != null) {
          return result;
        }
      }
    }

    return null;
  }
}
