import 'dart:collection';

import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/marriage_role_policy.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:family_tree_app/core/nit_hierarchy.dart';
import 'package:flutter/foundation.dart';

class MarriageFormProvider extends ChangeNotifier {
  List<FamilyDirectoryMember> _availableMembers = const [];
  int? _selectedMemberId;
  MarriageRole? _memberRole;
  UserData? _selectedMemberDetail;
  MarriageRolePolicy? _rolePolicy;
  bool _isLoading = false;
  bool _isLoadingMemberDetail = false;
  bool _isLoadingMarriages = false;
  String? _errorMessage;
  String? _memberDetailError;
  String? _marriageError;
  UserProvider? _userProvider;
  int _requestEpoch = 0;
  bool _isDisposed = false;

  UnmodifiableListView<FamilyDirectoryMember> get availableMembers =>
      UnmodifiableListView(_availableMembers);
  int? get selectedMemberId => _selectedMemberId;
  MarriageRole? get memberRole => _memberRole;
  PersonGender? get spouseGender => _memberRole?.requiredSpouseGender;
  UserData? get selectedMemberDetail => _selectedMemberDetail;
  MarriageRolePolicy? get rolePolicy => _rolePolicy;
  bool get isLoading => _isLoading;
  bool get isLoadingMemberDetail => _isLoadingMemberDetail;
  bool get isLoadingMarriages => _isLoadingMarriages;
  bool get isLoadingMemberContext =>
      _isLoadingMemberDetail || _isLoadingMarriages;
  String? get errorMessage => _errorMessage;
  String? get memberDetailError => _memberDetailError;
  String? get marriageError => _marriageError;

  bool get canChooseRole => _rolePolicy?.canChooseRole ?? false;
  bool get isRoleLocked => _rolePolicy?.lockedRole != null;
  bool get spouseInputsEnabled =>
      !isLoadingMemberContext &&
      _marriageError == null &&
      (_rolePolicy?.canCreateMarriage ?? false);
  String? get policyGuidanceMessage => _rolePolicy?.guidanceMessage;
  String? get blockingMessage => _marriageError ?? _rolePolicy?.blockingMessage;
  bool get hasBlockingIssue =>
      _marriageError != null || (_rolePolicy?.hasBlockingIssue ?? false);

  FamilyDirectoryMember? get selectedMember {
    for (final member in _availableMembers) {
      if (member.userId == _selectedMemberId) return member;
    }
    return null;
  }

  String? get roleCompatibilityError {
    final role = _memberRole;
    if (role == null) return null;

    final memberGender = _selectedMemberDetail?.gender;
    if (memberGender == PersonGender.male && role == MarriageRole.wife) {
      return 'Gender anggota laki-laki tidak sesuai dengan peran Istri.';
    }
    if (memberGender == PersonGender.female && role == MarriageRole.husband) {
      return 'Gender anggota perempuan tidak sesuai dengan peran Suami.';
    }

    return null;
  }

  bool get canSubmit {
    final policy = _rolePolicy;
    final role = _memberRole;
    return _selectedMemberId != null &&
        role != null &&
        !_isLoading &&
        !isLoadingMemberContext &&
        _marriageError == null &&
        policy != null &&
        policy.canCreateMarriage &&
        policy.allowsRole(role) &&
        spouseGender != null &&
        roleCompatibilityError == null;
  }

  Future<void> initialize({
    required UserProvider userProvider,
    required UserData actor,
    int? initialMemberId,
  }) async {
    _userProvider = userProvider;
    final epoch = ++_requestEpoch;
    _isLoading = true;
    _errorMessage = null;
    _memberDetailError = null;
    _marriageError = null;
    _rolePolicy = null;
    _memberRole = null;
    _notifyIfMounted();

    await userProvider.fetchData(isRefresh: true, keyword: '');
    if (!_isCurrent(epoch)) return;
    while (userProvider.canLoadMore && userProvider.perPage < 100) {
      await userProvider.loadMore();
      if (!_isCurrent(epoch)) return;
    }

    if (userProvider.state == ViewState.error &&
        userProvider.directoryMembers.isEmpty) {
      _errorMessage =
          userProvider.errorMessage ??
          'Data anggota gagal dimuat. Silakan coba lagi.';
      _availableMembers = const [];
      _selectedMemberId = null;
      _isLoading = false;
      _notifyIfMounted();
      return;
    }

    _availableMembers =
        userProvider.directoryMembers
            .where((member) => member.userId != null)
            .where(
              (member) =>
                  canManageNit(actorNit: actor.nit, targetNit: member.nit),
            )
            .toList()
          ..sort((a, b) => a.nit.compareTo(b.nit));

    if (initialMemberId != null &&
        !_availableMembers.any((member) => member.userId == initialMemberId)) {
      _errorMessage = 'Anggota tersebut berada di luar tingkat akses Anda.';
    }

    if (_availableMembers.isEmpty) {
      _errorMessage = 'Data anggota yang dapat dipilih belum tersedia.';
      _selectedMemberId = null;
    } else if (_availableMembers.any(
      (member) => member.userId == initialMemberId,
    )) {
      _selectedMemberId = initialMemberId;
    } else if (_availableMembers.any(
      (member) => member.userId == actor.userId,
    )) {
      _selectedMemberId = actor.userId;
    } else {
      _selectedMemberId = _availableMembers.first.userId;
    }

    _isLoading = false;
    _notifyIfMounted();
    await _loadSelectedMemberContext(userProvider, epoch: epoch);
  }

  Future<void> selectMember(int? memberId, {UserProvider? userProvider}) async {
    if (_selectedMemberId == memberId) return;
    final epoch = ++_requestEpoch;
    _selectedMemberId = memberId;
    _memberRole = null;
    _selectedMemberDetail = null;
    _rolePolicy = null;
    _memberDetailError = null;
    _marriageError = null;
    _isLoadingMemberDetail = false;
    _isLoadingMarriages = false;
    _notifyIfMounted();
    final source = userProvider ?? _userProvider;
    if (source != null) {
      await _loadSelectedMemberContext(source, epoch: epoch);
    }
  }

  Future<void> retrySelectedMemberContext({UserProvider? userProvider}) async {
    if (_selectedMemberId == null) return;
    final source = userProvider ?? _userProvider;
    if (source == null) return;
    final epoch = ++_requestEpoch;
    await _loadSelectedMemberContext(
      source,
      epoch: epoch,
      preserveChosenRole: true,
    );
  }

  Future<void> retrySelectedMemberDetail({
    required UserProvider userProvider,
  }) => retrySelectedMemberContext(userProvider: userProvider);

  Future<void> _loadSelectedMemberContext(
    UserProvider userProvider, {
    required int epoch,
    bool preserveChosenRole = false,
  }) async {
    final memberId = _selectedMemberId;
    if (memberId == null || !_isCurrent(epoch)) return;

    final previousRole = preserveChosenRole ? _memberRole : null;
    _memberRole = null;
    _selectedMemberDetail = null;
    _rolePolicy = null;
    _memberDetailError = null;
    _marriageError = null;
    _isLoadingMemberDetail = true;
    _isLoadingMarriages = true;
    _notifyIfMounted();

    final detail = await userProvider.fetchMemberById(memberId);
    if (!_isCurrentForMember(epoch, memberId)) return;
    _selectedMemberDetail = detail;
    _isLoadingMemberDetail = false;
    if (detail == null) {
      _memberDetailError =
          'Detail gender anggota belum dapat dimuat. Validasi akhir tetap dilakukan oleh server.';
    }
    _notifyIfMounted();

    final marriages = await userProvider.getMarriagesForMember(
      memberId,
      forceRefresh: true,
    );
    if (!_isCurrentForMember(epoch, memberId)) return;
    _isLoadingMarriages = false;

    if (marriages == null) {
      _marriageError =
          userProvider.marriageErrorForMember(memberId) ??
          'Riwayat pernikahan gagal dimuat. Coba lagi sebelum menambah pasangan.';
      _rolePolicy = null;
      _memberRole = null;
      _notifyIfMounted();
      return;
    }

    final policy = MarriageRolePolicy.fromMarriages(marriages);
    _rolePolicy = policy;
    _marriageError = null;
    if (policy.lockedRole != null) {
      _memberRole = policy.lockedRole;
    } else if (previousRole != null &&
        policy.canChooseRole &&
        policy.allowsRole(previousRole)) {
      _memberRole = previousRole;
    } else {
      _memberRole = null;
    }
    _notifyIfMounted();
  }

  void selectMemberRole(MarriageRole? role) {
    final policy = _rolePolicy;
    if (policy == null || !policy.canChooseRole) return;
    if (role != null && !policy.allowsRole(role)) return;
    if (_memberRole == role) return;
    _memberRole = role;
    _notifyIfMounted();
  }

  bool _isCurrent(int epoch) => !_isDisposed && epoch == _requestEpoch;

  bool _isCurrentForMember(int epoch, int memberId) =>
      _isCurrent(epoch) && _selectedMemberId == memberId;

  void _notifyIfMounted() {
    if (!_isDisposed) notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _userProvider = null;
    _requestEpoch++;
    super.dispose();
  }
}
