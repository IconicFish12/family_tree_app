import 'dart:collection';

import 'package:family_tree_app/core/family_permission_service.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/foundation.dart';

class MarriageFormProvider extends ChangeNotifier {
  final FamilyPermissionService _permissionService;

  MarriageFormProvider({
    FamilyPermissionService permissionService = const FamilyPermissionService(),
  }) : _permissionService = permissionService;

  List<FamilyDirectoryMember> _availableMembers = const [];
  int? _selectedMemberId;
  bool _isLoading = false;
  String? _errorMessage;

  UnmodifiableListView<FamilyDirectoryMember> get availableMembers =>
      UnmodifiableListView(_availableMembers);
  int? get selectedMemberId => _selectedMemberId;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  FamilyDirectoryMember? get selectedMember {
    for (final member in _availableMembers) {
      if (member.userId == _selectedMemberId) return member;
    }
    return null;
  }

  Future<void> initialize({
    required UserProvider userProvider,
    required UserData actor,
    int? initialMemberId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await userProvider.fetchData(isRefresh: true, keyword: '');
    while (userProvider.canLoadMore && userProvider.perPage < 100) {
      await userProvider.loadMore();
    }

    _availableMembers =
        userProvider.directoryMembers
            .where(
              (member) =>
                  member.userId != null &&
                  member.nit.trim().isNotEmpty &&
                  _permissionService.canManageMember(
                    actorNit: actor.nit,
                    targetNit: member.nit,
                  ),
            )
            .toList()
          ..sort((a, b) => a.nit.compareTo(b.nit));

    if (initialMemberId != null &&
        !_availableMembers.any((member) => member.userId == initialMemberId)) {
      final target = await userProvider.fetchMemberById(initialMemberId);
      if (target != null &&
          target.userId != null &&
          target.nit?.trim().isNotEmpty == true &&
          _permissionService.canManageMember(
            actorNit: actor.nit,
            targetNit: target.nit,
          )) {
        _availableMembers.add(_fromUserData(target));
      }
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
    notifyListeners();
  }

  void selectMember(int? memberId) {
    _selectedMemberId = memberId;
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
