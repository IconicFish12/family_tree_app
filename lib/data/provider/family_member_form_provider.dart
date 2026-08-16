import 'dart:collection';

import 'package:family_tree_app/core/nit_hierarchy.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/marriage_role_policy.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/foundation.dart';

enum MarriageLoadState { initial, loading, success, error }

class FamilyMemberFormProvider extends ChangeNotifier {
  bool _isLoadingContext = false;
  List<FamilyDirectoryMember> _availableParents = const [];
  List<FamilyTreeMarriage> _marriages = const [];
  int? _selectedParentId;
  int? _selectedMarriageId;
  PersonGender? _gender;
  bool _isAdopted = false;
  MarriageLoadState _marriageLoadState = MarriageLoadState.initial;
  String? _marriageError;
  String? _contextError;

  bool get isLoadingContext => _isLoadingContext;
  UnmodifiableListView<FamilyDirectoryMember> get availableParents =>
      UnmodifiableListView(_availableParents);
  UnmodifiableListView<FamilyTreeMarriage> get marriages =>
      UnmodifiableListView(_marriages);
  int? get selectedParentId => _selectedParentId;
  int? get selectedMarriageId => _selectedMarriageId;
  ChildRelationshipType get relationshipType => _isAdopted
      ? ChildRelationshipType.adopted
      : ChildRelationshipType.biological;
  PersonGender? get gender => _gender;
  bool get linkAdoptedToMarriage => _isAdopted;
  MarriageLoadState get marriageLoadState => _marriageLoadState;
  String? get marriageError => _marriageError;
  String? get contextError => _contextError;

  MarriageRolePolicy? get marriageRolePolicy =>
      _marriageLoadState == MarriageLoadState.success
      ? MarriageRolePolicy.fromMarriages(_marriages)
      : null;

  String? get childCreationBlockingMessage =>
      marriageRolePolicy?.childCreationBlockingMessage;

  bool get childDataInputsEnabled =>
      _marriageLoadState == MarriageLoadState.error ||
      (_marriageLoadState == MarriageLoadState.success &&
          (marriageRolePolicy?.canAddChild ?? false));

  bool get isBiological => !_isAdopted;

  bool get canSubmit {
    if (_isLoadingContext || _selectedParentId == null || _gender == null) {
      return false;
    }
    if (_marriageLoadState == MarriageLoadState.initial ||
        _marriageLoadState == MarriageLoadState.loading) {
      return false;
    }
    if (marriageRolePolicy?.canAddChild == false) return false;
    return _marriageLoadState == MarriageLoadState.success &&
        _selectedMarriageId != null;
  }

  FamilyDirectoryMember? get selectedParent {
    for (final member in _availableParents) {
      if (member.userId == _selectedParentId) {
        return member;
      }
    }
    return null;
  }

  Future<void> initialize({
    required UserProvider userProvider,
    required UserData actor,
    int? initialParentId,
  }) async {
    _isLoadingContext = true;
    _contextError = null;
    _marriageError = null;
    notifyListeners();

    await userProvider.fetchData(isRefresh: true, keyword: '');
    while (userProvider.canLoadMore && userProvider.perPage < 100) {
      await userProvider.loadMore();
    }

    if (userProvider.state == ViewState.error &&
        userProvider.directoryMembers.isEmpty) {
      _contextError =
          userProvider.errorMessage ??
          'Data anggota gagal dimuat. Silakan coba lagi.';
      _availableParents = const [];
      _isLoadingContext = false;
      notifyListeners();
      return;
    }

    _availableParents =
        userProvider.directoryMembers
            .where((member) => member.userId != null)
            .where(
              (member) =>
                  canAddChildForNit(actorNit: actor.nit, parentNit: member.nit),
            )
            .toList()
          ..sort((a, b) => a.nit.compareTo(b.nit));

    if (initialParentId != null &&
        !_availableParents.any((member) => member.userId == initialParentId)) {
      final target = await userProvider.fetchMemberById(initialParentId);
      if (target?.userId != null &&
          canAddChildForNit(actorNit: actor.nit, parentNit: target?.nit)) {
        _availableParents.add(_fromUserData(target!));
      } else if (target != null) {
        _contextError =
            'Anggota tersebut berada di luar batas dua tingkat keturunan Anda.';
      }
    }

    if (_availableParents.isEmpty) {
      _contextError = actor.nit?.trim().isEmpty != false
          ? 'NIT pengguna belum tersedia sehingga daftar orang tua tidak dapat ditentukan.'
          : 'Data diri, anak, atau cucu yang dapat dipilih belum tersedia. Silakan muat ulang.';
      _isLoadingContext = false;
      notifyListeners();
      return;
    }

    final preferredId =
        _availableParents.any((member) => member.userId == initialParentId)
        ? initialParentId
        : actor.userId;
    final selectedId =
        _availableParents.any((member) => member.userId == preferredId)
        ? preferredId
        : _availableParents.first.userId;

    _isLoadingContext = false;
    await selectParent(selectedId, userProvider: userProvider);
  }

  Future<void> selectParent(
    int? parentId, {
    required UserProvider userProvider,
  }) async {
    _selectedParentId = parentId;
    _selectedMarriageId = null;
    _marriages = const [];
    _marriageLoadState = MarriageLoadState.initial;
    _marriageError = null;
    _contextError = null;

    if (parentId == null || selectedParent == null) {
      _contextError = 'Pilih anggota yang akan menjadi orang tua.';
      notifyListeners();
      return;
    }

    await _loadMarriages(userProvider, forceRefresh: true);
  }

  Future<void> retryMarriages({required UserProvider userProvider}) async {
    if (_selectedParentId == null) return;
    await _loadMarriages(userProvider, forceRefresh: true);
  }

  Future<void> _loadMarriages(
    UserProvider userProvider, {
    required bool forceRefresh,
  }) async {
    final parentId = _selectedParentId;
    if (parentId == null) return;

    _marriageLoadState = MarriageLoadState.loading;
    _marriageError = null;
    notifyListeners();

    final marriages = await userProvider.getMarriagesForMember(
      parentId,
      forceRefresh: forceRefresh,
    );
    if (_selectedParentId != parentId) return;

    if (marriages == null) {
      _marriages = const [];
      _selectedMarriageId = null;
      _marriageLoadState = MarriageLoadState.error;
      _marriageError =
          userProvider.marriageErrorForMember(parentId) ??
          'Data pernikahan gagal dimuat. Silakan coba lagi.';
      notifyListeners();
      return;
    }

    _marriages = marriages;
    _marriageLoadState = MarriageLoadState.success;
    _marriageError = null;
    if (_marriages.length == 1) {
      _selectedMarriageId = _marriages.first.marriageId;
    } else {
      _selectedMarriageId = null;
    }
    notifyListeners();
  }

  void setAdoptedMarriageLink(bool linkToMarriage) {
    if (_isAdopted == linkToMarriage) return;
    _isAdopted = linkToMarriage;
    notifyListeners();
  }

  void selectMarriage(int? marriageId) {
    if (_selectedMarriageId == marriageId) return;
    _selectedMarriageId = marriageId;
    notifyListeners();
  }

  void selectGender(PersonGender? gender) {
    if (_gender == gender) return;
    _gender = gender;
    notifyListeners();
  }

  FamilyDirectoryMember _fromUserData(UserData data) {
    return FamilyDirectoryMember(
      userId: data.userId,
      familyTreeId: data.familyTreeId ?? '',
      nit: data.nit ?? '',
      level: data.level ?? 0,
      fullName: data.fullName ?? 'Tanpa Nama',
      gender: data.gender,
      address: data.address,
      birthYear: data.birthYear,
      avatar: data.avatar is String ? data.avatar as String : null,
      avatarUrl: data.avatarUrl,
    );
  }
}
