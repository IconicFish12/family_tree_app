import 'package:family_tree_app/core/nit_generator_service.dart';
import 'package:family_tree_app/data/models/export_file_data.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/material.dart';

enum ViewState { initial, loading, success, error }

class ChildCreationPreparation {
  final String generatedNit;
  final List<FamilyTreeMarriage> marriages;

  const ChildCreationPreparation({required this.generatedNit, required this.marriages});
}

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;
  final NitGeneratorService _nitGenerator;

  UserProvider(this._repository, {NitGeneratorService nitGenerator = const NitGeneratorService()})
    : _nitGenerator = nitGenerator;

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<FamilyDirectoryMember> _directoryMembers = [];
  List<FamilyDirectoryMember> get directoryMembers => _directoryMembers;

  List<UserData> _rawAllUsers = [];
  List<UserData> get allUsers => _rawAllUsers;

  List<FamilyUnit> _familyUnits = [];
  List<FamilyUnit> get familyUnits => _familyUnits;

  final Map<int, List<FamilyTreeMarriage>> _marriagesByMember = {};
  final Map<int, String> _marriageErrors = {};
  final Map<int, Future<List<FamilyTreeMarriage>?>> _marriageRequests = {};

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  bool _isExporting = false;
  bool get isExporting => _isExporting;

  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  String _keyword = '';
  String get keyword => _keyword;

  int _perPage = 25;
  int get perPage => _perPage;

  int _total = 0;
  int get total => _total;

  int? _authenticatedMemberId;
  int? get authenticatedMemberId => _authenticatedMemberId;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get canLoadMore => !_isLoadingMore && _directoryMembers.length >= _perPage && _directoryMembers.length < _total;

  Future<void> fetchData({bool isRefresh = false, String? keyword}) async {
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    if (isRefresh) {
      _perPage = 25;
      _directoryMembers = [];
      _rawAllUsers = [];
      _familyUnits = [];
      _clearMarriageCache();
    }

    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getFamilyMembers(keyword: _keyword, perPage: _perPage);

    result.fold(
      (failure) {
        _state = ViewState.error;
        _errorMessage = failure.message;
      },
      (response) {
        _applyDirectoryResponse(response);
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

    final result = await _repository.getFamilyMembers(keyword: _keyword, perPage: nextPerPage);

    result.fold((failure) => _errorMessage = failure.message, _applyDirectoryResponse);

    _isLoadingMore = false;
    notifyListeners();
  }

  Future<void> forceRefresh() async {
    await fetchData(isRefresh: true, keyword: _keyword);
  }

  Future<void> silentRefresh() async {
    if (_state == ViewState.loading) return;
    await fetchData(isRefresh: true, keyword: _keyword);
  }

  Future<UserData?> fetchMemberById(int memberId) async {
    final result = await _repository.getById(memberId.toString());
    return result.fold((failure) {
      _errorMessage = failure.message;
      notifyListeners();
      return null;
    }, (member) => member);
  }

  Future<UserData?> updateProfile({required UserData data}) async {
    _setSubmitting(true);
    final result = await _repository.updateProfile(data);
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setSubmitting(false);
        return null;
      },
      (updatedUser) async {
        await fetchData(isRefresh: true, keyword: _keyword);
        _setSubmitting(false);
        return updatedUser;
      },
    );
  }

  List<FamilyTreeMarriage>? marriagesForMember(int memberId) {
    return _marriagesByMember[memberId];
  }

  String? marriageErrorForMember(int memberId) {
    return _marriageErrors[memberId];
  }

  bool isLoadingMarriagesForMember(int memberId) {
    return _marriageRequests.containsKey(memberId);
  }

  Future<List<FamilyTreeMarriage>?> getMarriagesForMember(int memberId, {bool forceRefresh = false}) async {
    if (!forceRefresh && _marriagesByMember.containsKey(memberId)) {
      return _marriagesByMember[memberId];
    }

    final inFlight = _marriageRequests[memberId];
    if (inFlight != null) {
      return inFlight;
    }

    final request = _loadMarriages(memberId);
    _marriageRequests[memberId] = request;
    notifyListeners();
    try {
      return await request;
    } finally {
      _marriageRequests.remove(memberId);
      notifyListeners();
    }
  }

  Future<List<FamilyTreeMarriage>?> _loadMarriages(int memberId) async {
    final result = await _repository.getMarriages(memberId.toString());
    return result.fold(
      (failure) {
        _marriageErrors[memberId] = failure.message;
        _errorMessage = failure.message;
        return null;
      },
      (marriages) {
        _marriageErrors.remove(memberId);
        _marriagesByMember[memberId] = marriages;
        return marriages;
      },
    );
  }

  Future<ChildCreationPreparation?> prepareChildCreation({required int parentId, required String parentNit}) async {
    final marriages = await getMarriagesForMember(parentId, forceRefresh: true);
    if (marriages == null) {
      return null;
    }
    if (marriages.isEmpty) {
      _errorMessage = 'Tambahkan pasangan untuk anggota ini sebelum menambahkan anak.';
      notifyListeners();
      return null;
    }

    final childNits = <String>[];
    for (final marriage in marriages) {
      for (final child in marriage.children) {
        var childNit = child.nit?.trim() ?? '';
        if (childNit.isEmpty && child.userId != null) {
          for (final member in _directoryMembers) {
            if (member.userId == child.userId) {
              childNit = member.nit.trim();
              break;
            }
          }
        }
        if (childNit.isEmpty && child.userId != null) {
          final detail = await _repository.getById(child.userId.toString());
          childNit = detail.fold((_) => '', (member) => member.nit?.trim() ?? '');
        }
        if (childNit.isEmpty) {
          _errorMessage = 'NIT belum dapat dibuat. Silakan muat ulang data dan coba kembali.';
          notifyListeners();
          return null;
        }
        childNits.add(childNit);
      }
    }

    try {
      final generatedNit = _nitGenerator.generateNextNit(parentNit: parentNit, directChildNits: childNits);
      return ChildCreationPreparation(generatedNit: generatedNit, marriages: marriages);
    } on NitGenerationException catch (error) {
      _errorMessage = error.message;
      notifyListeners();
      return null;
    }
  }

  Future<bool> addSpouse({required UserData spouseData, required int memberId}) async {
    _setSubmitting(true);
    final result = await _repository.createMarriage(memberId: memberId.toString(), spouseData: spouseData);
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setSubmitting(false);
        return false;
      },
      (success) async {
        _marriagesByMember.remove(memberId);
        await fetchData(isRefresh: true, keyword: _keyword);
        _setSubmitting(false);
        return success;
      },
    );
  }

  Future<UserData?> addChild({
    required int parentId,
    required String parentNit,
    required int marriageId,
    required UserData childData,
  }) async {
    _setSubmitting(true);
    final preparation = await prepareChildCreation(parentId: parentId, parentNit: parentNit);
    if (preparation == null) {
      _setSubmitting(false);
      return null;
    }
    final validMarriage = preparation.marriages.any((marriage) => marriage.marriageId == marriageId);
    if (!validMarriage) {
      _errorMessage = 'Pasangan yang dipilih sudah berubah. Silakan pilih ulang.';
      _setSubmitting(false);
      return null;
    }

    final result = await _repository.createChild(
      memberId: parentId.toString(),
      marriageId: marriageId,
      nit: preparation.generatedNit,
      childData: childData,
    );
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setSubmitting(false);
        return null;
      },
      (createdChild) async {
        _marriagesByMember.remove(parentId);
        await fetchData(isRefresh: true, keyword: _keyword);
        _setSubmitting(false);
        return createdChild;
      },
    );
  }

  Future<bool> updateFamilyMember({required int memberId, required UserData memberData}) async {
    _setSubmitting(true);
    final result = await _repository.updateFamilyMember(memberId: memberId.toString(), memberData: memberData);
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setSubmitting(false);
        return false;
      },
      (_) async {
        await fetchData(isRefresh: true, keyword: _keyword);
        _setSubmitting(false);
        return true;
      },
    );
  }

  Future<bool> updateMarriage({required int marriageId, required int memberId, required UserData spouseData}) async {
    _setSubmitting(true);
    final result = await _repository.updateMarriage(marriageId: marriageId.toString(), spouseData: spouseData);
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setSubmitting(false);
        return false;
      },
      (success) {
        _marriagesByMember.remove(memberId);
        _setSubmitting(false);
        return success;
      },
    );
  }

  Future<bool> deleteFamilyMember(int memberId) async {
    _setSubmitting(true);
    final result = await _repository.deleteFamilyMember(memberId.toString());
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setSubmitting(false);
        return false;
      },
      (success) async {
        await fetchData(isRefresh: true, keyword: _keyword);
        _setSubmitting(false);
        return success;
      },
    );
  }

  Future<bool> deleteMarriage({required int marriageId, required int memberId}) async {
    _setSubmitting(true);
    final result = await _repository.deleteMarriage(marriageId.toString());
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _setSubmitting(false);
        return false;
      },
      (success) {
        _marriagesByMember.remove(memberId);
        _setSubmitting(false);
        return success;
      },
    );
  }

  Future<ExportFileData?> exportFamily() async {
    _isExporting = true;
    _errorMessage = null;
    notifyListeners();
    final result = await _repository.exportFamilyMembers();
    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isExporting = false;
        notifyListeners();
        return null;
      },
      (file) {
        _isExporting = false;
        notifyListeners();
        return file;
      },
    );
  }

  void clearFamilyState() {
    _directoryMembers = [];
    _rawAllUsers = [];
    _familyUnits = [];
    _authenticatedMemberId = null;
    _total = 0;
    _state = ViewState.initial;
    _clearMarriageCache();
    notifyListeners();
  }

  void _setSubmitting(bool value) {
    _isSubmitting = value;
    if (value) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void _clearMarriageCache() {
    _marriagesByMember.clear();
    _marriageErrors.clear();
  }

  void _applyDirectoryResponse(FamilyDirectoryResponse response) {
    _directoryMembers = response.members;
    _total = response.meta.total;
    _perPage = response.meta.perPage;
    _authenticatedMemberId = response.meta.authenticatedMemberId;
    _rawAllUsers = response.members
        .map(
          (member) => UserData(
            userId: member.userId,
            nit: member.nit,
            familyTreeId: member.familyTreeId,
            level: member.level,
            fullName: member.fullName,
            address: member.address,
            birthYear: member.birthYear,
            avatar: member.avatarUrl ?? member.avatar,
          ),
        )
        .toList();
    _familyUnits = _buildFamilyTree(_rawAllUsers);
  }

  List<FamilyUnit> _buildFamilyTree(List<UserData> allUsers) {
    final rootUsers = allUsers.where((u) => u.familyTreeId != null).toList()
      ..sort((a, b) => (a.familyTreeId ?? '').compareTo(b.familyTreeId ?? ''));

    final rootMembers = rootUsers.where((user) => !(user.familyTreeId ?? '').contains('.')).toList();

    return rootMembers.map((root) {
      final children = root.userId == null ? const <ChildMember>[] : _findChildren(root.userId!, allUsers);

      return FamilyUnit(
        headId: root.userId,
        nit: root.nit ?? '-',
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
    final directChildren =
        allUsers
            .where(
              (user) =>
                  user.familyTreeId != null &&
                  user.familyTreeId!.startsWith(parentPrefix) &&
                  !_hasIntermediateLevel(parentFamilyTreeId, user.familyTreeId!),
            )
            .toList()
          ..sort((a, b) => (a.familyTreeId ?? '').compareTo(b.familyTreeId ?? ''));

    return directChildren.map((child) {
      final nestedChildren = child.userId == null ? const <ChildMember>[] : _findChildren(child.userId!, allUsers);

      return ChildMember(
        id: child.userId,
        nit: child.nit ?? '-',
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
}
