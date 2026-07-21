import 'dart:collection';

import 'package:family_tree_app/core/family_permission_service.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/foundation.dart';

class FamilyMemberFormProvider extends ChangeNotifier {
  final FamilyPermissionService _permissionService;

  FamilyMemberFormProvider({
    FamilyPermissionService permissionService = const FamilyPermissionService(),
  }) : _permissionService = permissionService;

  bool _isLoadingContext = false;
  List<FamilyDirectoryMember> _availableParents = const [];
  List<FamilyTreeMarriage> _marriages = const [];
  int? _selectedParentId;
  int? _selectedMarriageId;
  String? _generatedNit;
  String? _contextError;

  bool get isLoadingContext => _isLoadingContext;
  UnmodifiableListView<FamilyDirectoryMember> get availableParents =>
      UnmodifiableListView(_availableParents);
  UnmodifiableListView<FamilyTreeMarriage> get marriages =>
      UnmodifiableListView(_marriages);
  int? get selectedParentId => _selectedParentId;
  int? get selectedMarriageId => _selectedMarriageId;
  String? get generatedNit => _generatedNit;
  String? get contextError => _contextError;
  bool get hasNoMarriage =>
      !_isLoadingContext &&
      _marriages.isEmpty &&
      (_contextError?.contains('Tambahkan pasangan') ?? false);

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
    notifyListeners();

    await userProvider.fetchData(isRefresh: true, keyword: '');
    while (userProvider.canLoadMore && userProvider.perPage < 100) {
      await userProvider.loadMore();
    }

    final actorNit = actor.nit?.trim();
    _availableParents =
        userProvider.directoryMembers
            .where(
              (member) =>
                  member.userId != null &&
                  member.nit.trim().isNotEmpty &&
                  _permissionService.canManageMember(
                    actorNit: actorNit,
                    targetNit: member.nit,
                  ),
            )
            .toList()
          ..sort((a, b) => a.nit.compareTo(b.nit));

    if (initialParentId != null &&
        !_availableParents.any((member) => member.userId == initialParentId)) {
      final target = await userProvider.fetchMemberById(initialParentId);
      if (target != null &&
          target.userId != null &&
          target.nit?.trim().isNotEmpty == true &&
          _permissionService.canManageMember(
            actorNit: actorNit,
            targetNit: target.nit,
          )) {
        _availableParents.add(_fromUserData(target));
      }
    }

    if (_availableParents.isEmpty) {
      _contextError =
          'Data anggota yang dapat dipilih belum tersedia. Silakan muat ulang.';
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
    _generatedNit = null;
    _marriages = const [];
    _contextError = null;

    final parent = selectedParent;
    if (parentId == null || parent == null || parent.nit.trim().isEmpty) {
      _contextError =
          'NIT belum dapat dibuat. Silakan muat ulang data dan coba kembali.';
      notifyListeners();
      return;
    }

    _isLoadingContext = true;
    notifyListeners();
    final preparation = await userProvider.prepareChildCreation(
      parentId: parentId,
      parentNit: parent.nit,
    );
    _isLoadingContext = false;

    if (preparation == null) {
      _contextError =
          userProvider.errorMessage ??
          'NIT belum dapat dibuat. Silakan muat ulang data dan coba kembali.';
      notifyListeners();
      return;
    }

    _marriages = preparation.marriages;
    _generatedNit = preparation.generatedNit;
    _selectedMarriageId = _marriages.length == 1
        ? _marriages.first.marriageId
        : null;
    notifyListeners();
  }

  void selectMarriage(int? marriageId) {
    if (_selectedMarriageId == marriageId) return;
    _selectedMarriageId = marriageId;
    notifyListeners();
  }

  FamilyDirectoryMember _fromUserData(UserData data) {
    return FamilyDirectoryMember(
      userId: data.userId,
      familyTreeId: data.familyTreeId ?? '',
      nit: data.nit ?? '',
      level: data.level ?? 0,
      fullName: data.fullName ?? 'Tanpa Nama',
      address: data.address,
      birthYear: data.birthYear,
      avatar: data.avatar is String ? data.avatar as String : null,
      avatarUrl: null,
    );
  }
}
