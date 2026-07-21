import 'package:family_tree_app/data/models/family_tree_node.dart';
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
  final Map<int, List<FamilyTreeMarriage>> _childMarriages = {};
  final Map<int, UserData> _childDetails = {};
  String? _errorMessage;

  MemberDetailState get state => _state;
  UserData? get member => _member;
  List<FamilyTreeMarriage> get marriages => _marriages;
  String? get errorMessage => _errorMessage;

  List<FamilyTreeNode> get directChildren => _marriages
      .expand((marriage) => marriage.children)
      .toList(growable: false);

  List<FamilyTreeMarriage> marriagesForChild(int childId) {
    return _childMarriages[childId] ?? const [];
  }

  UserData? detailForChild(int childId) => _childDetails[childId];

  List<FamilyTreeNode> grandchildrenForChild(int childId) {
    return marriagesForChild(
      childId,
    ).expand((marriage) => marriage.children).toList(growable: false);
  }

  Future<void> load(int memberId) async {
    _state = MemberDetailState.loading;
    _errorMessage = null;
    notifyListeners();

    final memberResult = await _repository.getById(memberId.toString());
    final loadedMember = memberResult.fold<UserData?>((failure) {
      _errorMessage = failure.message;
      return null;
    }, (member) => member);
    if (loadedMember == null) {
      _state = MemberDetailState.error;
      notifyListeners();
      return;
    }

    final marriageResult = await _repository.getMarriages(memberId.toString());
    final loadedMarriages = marriageResult.fold<List<FamilyTreeMarriage>?>((
      failure,
    ) {
      _errorMessage = failure.message;
      return null;
    }, (marriages) => marriages);
    if (loadedMarriages == null) {
      _state = MemberDetailState.error;
      notifyListeners();
      return;
    }

    _member = loadedMember;
    _marriages = loadedMarriages;
    _childMarriages.clear();
    _childDetails.clear();

    await Future.wait(
      directChildren
          .where((child) => child.userId != null)
          .map((child) => _loadChildData(child.userId!)),
    );

    _state = MemberDetailState.success;
    notifyListeners();
  }

  Future<void> _loadChildData(int childId) async {
    final detailResult = await _repository.getById(childId.toString());
    detailResult.fold((_) {}, (detail) => _childDetails[childId] = detail);

    final marriageResult = await _repository.getMarriages(childId.toString());
    marriageResult.fold(
      (_) => _childMarriages[childId] = const [],
      (marriages) => _childMarriages[childId] = marriages,
    );
  }
}
