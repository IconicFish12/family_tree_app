import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/material.dart';

enum ViewState { initial, loading, success, error }

class UserProvider extends ChangeNotifier {
  final UserRepositoryImpl _repositoryImpl;

  UserProvider(this._repositoryImpl);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<FamilyDirectoryMember> _directoryMembers = [];
  List<FamilyDirectoryMember> get directoryMembers => _directoryMembers;

  List<UserData> _rawAllUsers = [];
  List<UserData> get allUsers => _rawAllUsers;

  List<FamilyUnit> _familyUnits = [];
  List<FamilyUnit> get familyUnits => _familyUnits;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String _keyword = '';
  String get keyword => _keyword;

  int _perPage = 25;
  int get perPage => _perPage;

  int _total = 0;
  int get total => _total;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get canLoadMore =>
      !_isLoadingMore &&
      _directoryMembers.length >= _perPage &&
      _directoryMembers.length < _total;

  Future<void> fetchData({
    bool isRefresh = false,
    String? keyword,
  }) async {
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    if (isRefresh) {
      _perPage = 25;
      _directoryMembers = [];
      _rawAllUsers = [];
      _familyUnits = [];
    }

    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repositoryImpl.getFamilyMembers(
      keyword: _keyword,
      perPage: _perPage,
    );

    result.fold(
      (failure) {
        _state = ViewState.error;
        _errorMessage = failure.message;
      },
      (response) {
        _directoryMembers = response.members;
        _total = response.meta.total;
        _perPage = response.meta.perPage;
        _rawAllUsers = response.members
            .map(
              (member) => UserData(
                userId: member.userId,
                familyTreeId: member.familyTreeId,
                fullName: member.fullName,
                address: member.address,
                birthYear: member.birthYear,
                avatar: member.avatarUrl ?? member.avatar,
              ),
            )
            .toList();
        _familyUnits = _buildFamilyTree(_rawAllUsers);
        _state = ViewState.success;
      },
    );

    notifyListeners();
  }

  Future<void> loadMore() async {
    if (!canLoadMore) return;

    _isLoadingMore = true;
    _errorMessage = null;
    final nextPerPage = _perPage + 25;
    notifyListeners();

    final result = await _repositoryImpl.getFamilyMembers(
      keyword: _keyword,
      perPage: nextPerPage,
    );

    result.fold(
      (failure) {
        _errorMessage = failure.message;
      },
      (response) {
        _directoryMembers = response.members;
        _total = response.meta.total;
        _perPage = response.meta.perPage;
        _rawAllUsers = response.members
            .map(
              (member) => UserData(
                userId: member.userId,
                familyTreeId: member.familyTreeId,
                fullName: member.fullName,
                address: member.address,
                birthYear: member.birthYear,
                avatar: member.avatarUrl ?? member.avatar,
              ),
            )
            .toList();
        _familyUnits = _buildFamilyTree(_rawAllUsers);
      },
    );

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> forceRefresh() async {
    await fetchData(isRefresh: true);
  }

  Future<void> silentRefresh() async {
    if (_state == ViewState.loading) return;
    await fetchData(isRefresh: true, keyword: _keyword);
  }

  Future<UserData?> updateProfile({required UserData data}) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repositoryImpl.updateProfile(data);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return null;
      },
      (updatedUser) {
        _isSubmitting = false;
        notifyListeners();
        return updatedUser;
      },
    );
  }

  Future<List<FamilyTreeMarriage>> getMarriagesForMember(int memberId) async {
    final result = await _repositoryImpl.getMarriages(memberId.toString());
    return result.fold((_) => const [], (marriages) => marriages);
  }

  Future<bool> addSpouse({
    required UserData spouseData,
    required int currentUserId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repositoryImpl.createMarriage(
      memberId: currentUserId.toString(),
      spouseData: spouseData,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (success) async {
        await fetchData(isRefresh: true, keyword: _keyword);
        _isSubmitting = false;
        notifyListeners();
        return success;
      },
    );
  }

  Future<bool> addChild({
    required UserData childData,
    required String nit,
    String? marriageId,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final parentId = childData.parentId;
    if (parentId == null) {
      _errorMessage = 'Orang tua belum dipilih.';
      _isSubmitting = false;
      notifyListeners();
      return false;
    }

    final result = await _repositoryImpl.createChild(
      memberId: parentId.toString(),
      marriageId: marriageId,
      nit: nit,
      childData: childData,
    );

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (success) async {
        await fetchData(isRefresh: true, keyword: _keyword);
        _isSubmitting = false;
        notifyListeners();
        return success;
      },
    );
  }

  List<FamilyUnit> _buildFamilyTree(List<UserData> allUsers) {
    final rootUsers = allUsers.where((u) => u.familyTreeId != null).toList()
      ..sort((a, b) => (a.familyTreeId ?? '').compareTo(b.familyTreeId ?? ''));

    final rootMembers = rootUsers
        .where((user) => !(user.familyTreeId ?? '').contains('.'))
        .toList();

    return rootMembers.map((root) {
      final children = root.userId == null
          ? const <ChildMember>[]
          : _findChildren(root.userId!, allUsers);

      return FamilyUnit(
        headId: root.userId,
        nit: root.familyTreeId ?? '-',
        headName: root.fullName ?? 'Tanpa Nama',
        spouseName: null,
        location: root.address ?? '-',
        avatar: root.avatar is String ? root.avatar as String : null,
        birthYear: root.birthYear,
        children: children,
      );
    }).toList();
  }

  List<ChildMember> _findChildren(int parentId, List<UserData> allUsers) {
    UserData? parent;
    for (final user in allUsers) {
      if (user.userId == parentId) {
        parent = user;
        break;
      }
    }

    if (parent?.familyTreeId == null) {
      return const [];
    }

    final parentFamilyTreeId = parent!.familyTreeId!;
    final parentPrefix = '$parentFamilyTreeId.';
    final directChildren = allUsers
        .where(
          (user) =>
              user.familyTreeId != null &&
              user.familyTreeId!.startsWith(parentPrefix) &&
              !_hasIntermediateLevel(parentFamilyTreeId, user.familyTreeId!),
        )
        .toList()
      ..sort((a, b) => (a.familyTreeId ?? '').compareTo(b.familyTreeId ?? ''));

    return directChildren.map((child) {
      final nestedChildren = child.userId == null
          ? const <ChildMember>[]
          : _findChildren(child.userId!, allUsers);

      return ChildMember(
        id: child.userId,
        nit: child.familyTreeId ?? '-',
        name: child.fullName ?? 'Tanpa Nama',
        spouseName: null,
        location: child.address ?? '-',
        photoUrl: child.avatar is String ? child.avatar as String : null,
        birthYear: child.birthYear,
        children: nestedChildren,
      );
    }).toList();
  }

  bool _hasIntermediateLevel(String parentId, String childId) {
    final parentParts = parentId.split('.');
    final childParts = childId.split('.');
    return childParts.length != parentParts.length + 1;
  }

  Future<bool> updateFamilyMember({
    required int memberId,
    required String fullName,
    String? address,
    String? birthYear,
    String? gender,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repositoryImpl.updateFamilyMember(
      memberId: memberId,
      fullName: fullName,
      address: address,
      birthYear: birthYear,
      gender: gender,
    );

    _isSubmitting = false;
    notifyListeners();

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return false;
      },
      (success) {
        fetchData(isRefresh: true);
        return success;
      },
    );
  }

  Future<bool> deleteFamilyMember(int memberId) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await _repositoryImpl.deleteFamilyMember(memberId);

    _isSubmitting = false;
    notifyListeners();

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        return false;
      },
      (success) {
        fetchData(isRefresh: true);
        return success;
      },
    );
  }
}
