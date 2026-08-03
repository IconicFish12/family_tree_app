import 'package:family_tree_app/data/models/export_file_data.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/marriage_role_policy.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/material.dart';

enum ViewState { initial, loading, success, error }

class UserProvider extends ChangeNotifier {
  final UserRepository _repository;

  UserProvider(this._repository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<FamilyDirectoryMember> _directoryMembers = [];
  List<FamilyDirectoryMember> get directoryMembers => _directoryMembers;

  List<UserData> _rawAllUsers = [];
  List<UserData> get allUsers => _rawAllUsers;

  List<FamilyUnit> get familyUnits => const [];

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

  bool get canLoadMore =>
      !_isLoadingMore &&
      _directoryMembers.length >= _perPage &&
      _directoryMembers.length < _total;

  Future<void> fetchData({bool isRefresh = false, String? keyword}) async {
    if (keyword != null) {
      _keyword = keyword.trim();
    }

    if (isRefresh) {
      _perPage = 25;
      _directoryMembers = [];
      _rawAllUsers = [];
      _clearMarriageCache();
    }

    _state = ViewState.loading;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.getFamilyMembers(
      keyword: _keyword,
      perPage: _perPage,
    );

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

    final result = await _repository.getFamilyMembers(
      keyword: _keyword,
      perPage: nextPerPage,
    );

    result.fold(
      (failure) => _errorMessage = failure.message,
      _applyDirectoryResponse,
    );

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

  Future<List<FamilyTreeMarriage>?> getMarriagesForMember(
    int memberId, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _marriagesByMember.containsKey(memberId)) {
      return _marriagesByMember[memberId];
    }

    final inFlight = _marriageRequests[memberId];
    if (inFlight != null) {
      if (!forceRefresh) return inFlight;
      await inFlight;
      return getMarriagesForMember(memberId, forceRefresh: true);
    }

    _marriageErrors.remove(memberId);
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

  Future<FamilyTreeMarriage?> addSpouse({
    required UserData spouseData,
    required int memberId,
    required MarriageRole memberRole,
  }) async {
    if (!_tryStartSubmitting()) return null;
    try {
      List<FamilyTreeMarriage>? marriages;
      try {
        marriages = await getMarriagesForMember(memberId, forceRefresh: true);
      } catch (_) {
        _errorMessage =
            'Riwayat pernikahan gagal dimuat. Coba lagi sebelum menambah pasangan.';
        return null;
      }
      if (marriages == null) {
        _errorMessage =
            marriageErrorForMember(memberId) ??
            'Riwayat pernikahan gagal dimuat. Coba lagi sebelum menambah pasangan.';
        return null;
      }

      final policy = MarriageRolePolicy.fromMarriages(marriages);
      if (!policy.canCreateMarriage) {
        _errorMessage =
            policy.blockingMessage ??
            'Pernikahan baru tidak dapat ditambahkan untuk anggota ini.';
        return null;
      }
      if (!policy.allowsRole(memberRole)) {
        final lockedRole = policy.lockedRole;
        _errorMessage = lockedRole == null
            ? 'Peran yang dipilih tidak sesuai dengan riwayat pernikahan anggota.'
            : 'Peran anggota sudah dikunci sebagai ${lockedRole.label} berdasarkan riwayat pernikahan.';
        return null;
      }

      final result = await _repository.createMarriage(
        memberId: memberId.toString(),
        memberRole: memberRole,
        spouseData: spouseData,
      );
      return await result.fold(
        (failure) async {
          _errorMessage = failure.message;
          return null;
        },
        (createdMarriage) async {
          _marriagesByMember.remove(memberId);
          await fetchData(isRefresh: true, keyword: _keyword);
          return createdMarriage;
        },
      );
    } finally {
      _setSubmitting(false);
    }
  }

  Future<FamilyTreeNode?> addChild({
    required int parentId,
    required ChildRelationshipType relationshipType,
    required int? marriageId,
    required UserData childData,
  }) async {
    if (!_tryStartSubmitting()) return null;
    try {
      if (relationshipType == ChildRelationshipType.biological &&
          marriageId == null) {
        _errorMessage = 'Anak kandung wajib memilih pernikahan.';
        return null;
      }

      List<FamilyTreeMarriage>? marriages;
      try {
        marriages = await getMarriagesForMember(parentId, forceRefresh: true);
      } catch (_) {
        if (marriageId != null) {
          _errorMessage = 'Data pernikahan gagal dimuat. Silakan coba lagi.';
          return null;
        }
      }

      if (marriages == null && marriageId != null) {
        _errorMessage =
            marriageErrorForMember(parentId) ??
            'Data pernikahan gagal dimuat. Silakan coba lagi.';
        return null;
      }

      if (marriages != null) {
        final policy = MarriageRolePolicy.fromMarriages(marriages);
        if (!policy.canAddChild) {
          _errorMessage =
              policy.childCreationBlockingMessage ??
              'Data pernikahan perlu dirapikan sebelum menambah anak.';
          return null;
        }

        if (marriageId != null &&
            !marriages.any((marriage) => marriage.marriageId == marriageId)) {
          _errorMessage =
              'Pernikahan yang dipilih sudah berubah. Silakan pilih ulang.';
          return null;
        }
      }

      final result = await _repository.createChild(
        memberId: parentId.toString(),
        relationshipType: relationshipType,
        marriageId: marriageId,
        childData: childData,
      );
      return await result.fold(
        (failure) async {
          _errorMessage = failure.message;
          return null;
        },
        (createdChild) async {
          _marriagesByMember.remove(parentId);
          await fetchData(isRefresh: true, keyword: _keyword);
          return createdChild;
        },
      );
    } finally {
      _setSubmitting(false);
    }
  }

  Future<bool> updateFamilyMember({
    required int memberId,
    required UserData memberData,
  }) async {
    _setSubmitting(true);
    final result = await _repository.updateFamilyMember(
      memberId: memberId.toString(),
      memberData: memberData,
    );
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

  Future<bool> updateMarriage({
    required int marriageId,
    required int memberId,
    required UserData spouseData,
  }) async {
    _setSubmitting(true);
    final result = await _repository.updateMarriage(
      marriageId: marriageId.toString(),
      spouseData: spouseData,
    );
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

  Future<bool> deleteMarriage({
    required int marriageId,
    required int memberId,
  }) async {
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

  bool _tryStartSubmitting() {
    if (_isSubmitting) {
      _errorMessage =
          'Perubahan lain masih diproses. Tunggu sampai selesai lalu coba lagi.';
      notifyListeners();
      return false;
    }
    _setSubmitting(true);
    return true;
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
            gender: member.gender,
            address: member.address,
            birthYear: member.birthYear,
            avatar: member.avatarUrl ?? member.avatar,
          ),
        )
        .toList();
  }
}
