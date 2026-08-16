import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/marriage_role_policy.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/foundation.dart';

enum MemberDetailState { initial, loading, success, error }

class MemberDetailProvider extends ChangeNotifier {
  final UserRepository _repository;

  MemberDetailProvider(this._repository);

  MemberDetailState _state = MemberDetailState.initial;
  UserData? _member;
  List<FamilyTreeMarriage> _marriages = const [];
  List<FamilyTreeNode> _personalAdoptedChildren = const [];
  final Map<int, FamilyTreeNode> _treeNodesByUserId = {};
  final Map<int, List<FamilyTreeMarriage>> _childMarriages = {};
  final Map<int, UserData> _childDetails = {};
  final Map<int, String> _childErrors = {};
  final Set<int> _loadingChildIds = {};
  int? _memberId;
  bool _isLoadingDescendantTree = false;
  String? _descendantTreeError;
  String? _errorMessage;
  int _dataEpoch = 0;
  bool _isDisposed = false;

  MemberDetailState get state => _state;
  UserData? get member => _member;
  List<FamilyTreeMarriage> get marriages => _marriages;
  MarriageRolePolicy get marriageRolePolicy =>
      MarriageRolePolicy.fromMarriages(_marriages);
  bool get isLoadingDescendantTree => _isLoadingDescendantTree;
  String? get descendantTreeError => _descendantTreeError;
  String? get errorMessage => _errorMessage;

  List<FamilyTreeNode> get directChildren => _mergeAndOrderChildren([
    ..._marriages.expand((marriage) => marriage.children),
    ..._personalAdoptedChildren,
  ]);

  List<FamilyTreeMarriage> marriagesForChild(int childId) {
    return _childMarriages[childId] ?? const [];
  }

  UserData? detailForChild(int childId) => _childDetails[childId];

  String? errorForChild(int childId) => _childErrors[childId];

  bool isLoadingChild(int childId) => _loadingChildIds.contains(childId);

  List<FamilyTreeNode> grandchildrenForChild(int childId) {
    return _mergeAndOrderChildren([
      ...marriagesForChild(childId).expand((marriage) => marriage.children),
      ...?_treeNodesByUserId[childId]?.adoptedChildren,
    ]);
  }

  bool hasCompleteTreeBranchFor(int memberId) {
    return _treeNodesByUserId.containsKey(memberId);
  }

  Future<void> load(int memberId) async {
    if (_isDisposed) return;
    final epoch = ++_dataEpoch;
    _memberId = memberId;
    _state = MemberDetailState.loading;
    _errorMessage = null;
    _descendantTreeError = null;
    _isLoadingDescendantTree = false;
    _member = null;
    _marriages = const [];
    _personalAdoptedChildren = const [];
    _treeNodesByUserId.clear();
    _childMarriages.clear();
    _childDetails.clear();
    _childErrors.clear();
    _loadingChildIds.clear();
    _notifyListeners();

    final memberResult = await _repository.getById(memberId.toString());
    if (!_isCurrent(epoch)) return;
    final loadedMember = memberResult.fold<UserData?>((failure) {
      _errorMessage = failure.message;
      return null;
    }, (member) => member);
    if (loadedMember == null) {
      _state = MemberDetailState.error;
      _notifyListeners();
      return;
    }

    final marriageResult = await _repository.getMarriages(memberId.toString());
    if (!_isCurrent(epoch)) return;
    final loadedMarriages = marriageResult.fold<List<FamilyTreeMarriage>?>((
      failure,
    ) {
      _errorMessage = failure.message;
      return null;
    }, (marriages) => marriages);
    if (loadedMarriages == null) {
      _state = MemberDetailState.error;
      _notifyListeners();
      return;
    }

    _member = loadedMember;
    _marriages = loadedMarriages;

    await _loadDescendantTree(memberId, epoch);
    if (!_isCurrent(epoch)) return;

    await _loadMissingDirectChildData(epoch);
    if (!_isCurrent(epoch)) return;

    _state = MemberDetailState.success;
    _notifyListeners();
  }

  Future<void> _loadDescendantTree(int memberId, int epoch) async {
    _personalAdoptedChildren = const [];
    _treeNodesByUserId.clear();

    final treeResult = await _repository.getTree();
    if (!_isCurrent(epoch)) return;
    treeResult.fold((failure) => _descendantTreeError = failure.message, (
      response,
    ) {
      final branch = response.root.findByUserId(memberId);
      if (branch == null) {
        _descendantTreeError =
            'Cabang anggota ini tidak tersedia pada pohon akun yang sedang login.';
        return;
      }

      for (final node in branch.depthFirst()) {
        final userId = node.userId;
        if (userId != null) {
          _treeNodesByUserId.putIfAbsent(userId, () => node);
        }
      }
      _personalAdoptedChildren = List.unmodifiable(branch.adoptedChildren);
      _descendantTreeError = null;
    });
  }

  Future<void> _loadMissingDirectChildData(int epoch) async {
    if (!_isCurrent(epoch)) return;
    final childIds = directChildren
        .map((child) => child.userId)
        .whereType<int>()
        .toSet();
    await Future.wait(
      childIds
          .where(
            (childId) =>
                !_childDetails.containsKey(childId) ||
                !_childMarriages.containsKey(childId),
          )
          .map((childId) => _loadChildData(childId, epoch)),
    );
  }

  Future<void> _loadChildData(int childId, int epoch) async {
    final errors = <String>[];
    final detailResult = await _repository.getById(childId.toString());
    if (!_isCurrent(epoch)) return;
    detailResult.fold(
      (failure) => errors.add(failure.message),
      (detail) => _childDetails[childId] = detail,
    );

    final marriageResult = await _repository.getMarriages(childId.toString());
    if (!_isCurrent(epoch)) return;
    marriageResult.fold(
      (failure) => errors.add(failure.message),
      (marriages) => _childMarriages[childId] = marriages,
    );

    if (errors.isEmpty) {
      _childErrors.remove(childId);
    } else {
      _childErrors[childId] = errors.toSet().join(' ');
    }
  }

  Future<void> retryChildData(int childId) async {
    if (_isDisposed || _loadingChildIds.contains(childId)) return;
    final epoch = _dataEpoch;

    _loadingChildIds.add(childId);
    _childErrors.remove(childId);
    _notifyListeners();

    try {
      await _loadChildData(childId, epoch);
    } finally {
      if (_isCurrent(epoch)) {
        _loadingChildIds.remove(childId);
        _notifyListeners();
      }
    }
  }

  Future<void> retryDescendantTree() async {
    final memberId = _memberId;
    if (_isDisposed || memberId == null || _isLoadingDescendantTree) return;
    final epoch = _dataEpoch;

    _isLoadingDescendantTree = true;
    _descendantTreeError = null;
    _notifyListeners();

    try {
      await _loadDescendantTree(memberId, epoch);
      if (_isCurrent(epoch) && _descendantTreeError == null) {
        await _loadMissingDirectChildData(epoch);
      }
    } finally {
      if (_isCurrent(epoch)) {
        _isLoadingDescendantTree = false;
        _notifyListeners();
      }
    }
  }

  bool _isCurrent(int epoch) => !_isDisposed && epoch == _dataEpoch;

  void _notifyListeners() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _dataEpoch++;
    super.dispose();
  }

  List<FamilyTreeNode> _mergeAndOrderChildren(
    Iterable<FamilyTreeNode> children,
  ) {
    final result = <FamilyTreeNode>[];
    final seenRelationIds = <int>{};
    final seenUserIds = <int>{};

    for (final child in children) {
      final relationId = child.relationId;
      final userId = child.userId;
      final hasSeenRelation =
          relationId != null && seenRelationIds.contains(relationId);
      final hasSeenUser = userId != null && seenUserIds.contains(userId);
      if (hasSeenRelation || hasSeenUser) continue;

      if (relationId != null) seenRelationIds.add(relationId);
      if (userId != null) seenUserIds.add(userId);
      result.add(child);
    }

    final originalOrder = <FamilyTreeNode, int>{
      for (var index = 0; index < result.length; index++) result[index]: index,
    };
    result.sort((left, right) {
      final leftOrder = left.lineageOrder;
      final rightOrder = right.lineageOrder;
      if (leftOrder != null && rightOrder != null && leftOrder != rightOrder) {
        return leftOrder.compareTo(rightOrder);
      }
      if (leftOrder != null && rightOrder == null) return -1;
      if (leftOrder == null && rightOrder != null) return 1;
      return originalOrder[left]!.compareTo(originalOrder[right]!);
    });
    return List.unmodifiable(result);
  }
}
