import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/repository/spouse_repository.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/material.dart';

enum ViewState { initial, loading, success, error }

class UserProvider extends ChangeNotifier {
  final UserRepositoryImpl _repositoryImpl;
  final SpouseRepository _spouseRepository;

  UserProvider(this._repositoryImpl, this._spouseRepository);

  ViewState _state = ViewState.initial;
  ViewState get state => _state;

  List<UserData> _rawAllUsers = [];
  List<UserData> get allUsers => _rawAllUsers;

  List<FamilyUnit> _familyUnits = [];
  List<FamilyUnit> get familyUnits => _familyUnits;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  DateTime? _lastFetchTime;
  static const _minRefreshInterval = Duration(seconds: 30);

  Future<void> forceRefresh() async {
    debugPrint('[UserProvider] Force refresh triggered');
    final result = await _repositoryImpl.getData(page: 1);

    result.fold(
      (failure) {
        debugPrint('[UserProvider] Force refresh failed: ${failure.message}');
      },
      (newUsers) {
        _rawAllUsers = newUsers;
        _familyUnits = _buildFamilyTree(_rawAllUsers);
        _lastFetchTime = DateTime.now();
        notifyListeners();
      },
    );
  }

  Future<void> silentRefresh() async {
    if (_lastFetchTime != null) {
      final timeSinceLastFetch = DateTime.now().difference(_lastFetchTime!);
      if (timeSinceLastFetch < _minRefreshInterval) {
        debugPrint(
          '[UserProvider] Skipped refresh - last fetch ${timeSinceLastFetch.inSeconds}s ago',
        );
        return;
      }
    }
    await forceRefresh();
  }

  Future<void> fetchData({bool isRefresh = false}) async {
    if (isRefresh) {
      _rawAllUsers.clear();
      _state = ViewState.loading;
      notifyListeners();
    }

    final result = await _repositoryImpl.getData(page: 1);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        if (isRefresh) _state = ViewState.error;
      },
      (newUsers) {
        _rawAllUsers.addAll(newUsers);
        _familyUnits = _buildFamilyTree(_rawAllUsers);
        _lastFetchTime = DateTime.now();
        _state = ViewState.success;
      },
    );
    notifyListeners();
  }

  Future<UserData?> updateProfile({
    required String id,
    required UserData data,
  }) async {
    debugPrint('[UserProvider] updateProfile called with id: $id');
    debugPrint('[UserProvider] updateProfile data: ${data.toJson()}');

    _isSubmitting = true;
    notifyListeners();

    final result = await _repositoryImpl.updateProfile(id, data);

    return result.fold(
      (failure) {
        debugPrint('[UserProvider] updateProfile FAILED: ${failure.message}');
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return null;
      },
      (updatedUser) async {
        debugPrint(
          '[UserProvider] updateProfile SUCCESS: ${updatedUser.toJson()}',
        );
        await forceRefresh();
        _isSubmitting = false;
        notifyListeners();
        return updatedUser;
      },
    );
  }

  Future<bool> addUser(UserData newUser) async {
    _isSubmitting = true;
    notifyListeners();

    String generatedId = _generateNextFamilyTreeId(newUser.parentId);

    final userToSend = newUser.copyWith(
      familyTreeId: generatedId,
      parentId: newUser.parentId,
    );

    final result = await _repositoryImpl.createUser(userToSend);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (createdUser) async {
        await forceRefresh();
        _isSubmitting = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> addSpouse({
    required UserData spouseData,
    required int currentUserId,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    await fetchData(isRefresh: true);

    String spouseTreeId = _generateNextFamilyTreeId(currentUserId);

    final spouseToSend = spouseData.copyWith(
      familyTreeId: spouseTreeId, // Satu grup
      parentId: currentUserId,
    );

    final userResult = await _repositoryImpl.createUser(spouseToSend);

    return userResult.fold(
      (failure) {
        _errorMessage = "Gagal membuat user pasangan: ${failure.message}";
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (createdSpouse) async {
        if (createdSpouse.userId == null) {
          _errorMessage = "ID Pasangan tidak ditemukan.";
          _isSubmitting = false;
          notifyListeners();
          return false;
        }

        final spouseResult = await _spouseRepository.addSpouse(
          primaryUserId: currentUserId,
          spouseUserId: createdSpouse.userId!,
        );

        return spouseResult.fold(
          (failure) {
            _errorMessage = failure.message;
            _isSubmitting = false;
            notifyListeners();
            return false;
          },
          (success) async {
            await fetchData(isRefresh: true);
            _isSubmitting = false;
            notifyListeners();
            return true;
          },
        );
      },
    );
  }

  Future<bool> addChild(UserData childData) async {
    _isSubmitting = true;
    notifyListeners();

    // Generate ID Anak based on Parent
    String generatedId = _generateNextFamilyTreeId(childData.parentId);

    final userToSend = childData.copyWith(familyTreeId: generatedId);

    final result = await _repositoryImpl.createUser(userToSend);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (createdUser) async {
        await fetchData(isRefresh: true);
        _isSubmitting = false;
        notifyListeners();
        return true;
      },
    );
  }

  String _generateNextFamilyTreeId(int? parentId) {
    try {
      if (parentId == null) {
        final rootUsers = _rawAllUsers
            .where((u) => u.parentId == null)
            .toList();

        if (rootUsers.isEmpty) return "1";

        int maxId = 0;
        for (var user in rootUsers) {
          if (user.familyTreeId != null) {
            int? currentId = int.tryParse(
              user.familyTreeId!.replaceAll(RegExp(r'[^0-9]'), ''),
            );
            if (currentId != null && currentId > maxId) {
              maxId = currentId;
            }
          }
        }
        return (maxId + 1).toString();
      } else {
        final parent = _rawAllUsers.firstWhere(
          (u) => u.userId == parentId,
          orElse: () => const UserData(familyTreeId: "0"),
        );

        String parentPrefix = parent.familyTreeId ?? "0";

        final siblings = _rawAllUsers
            .where((u) => u.parentId == parentId)
            .toList();

        int maxSuffix = 0;
        for (var sibling in siblings) {
          if (sibling.familyTreeId != null &&
              sibling.familyTreeId!.startsWith("$parentPrefix.")) {
            List<String> parts = sibling.familyTreeId!.split('.');
            if (parts.isNotEmpty) {
              int? suffix = int.tryParse(
                parts.last.replaceAll(RegExp(r'[^0-9]'), ''),
              );
              if (suffix != null && suffix > maxSuffix) {
                maxSuffix = suffix;
              }
            }
          }
        }
        return "$parentPrefix.${maxSuffix + 1}";
      }
    } catch (e) {
      return "0";
    }
  }

  List<FamilyUnit> _buildFamilyTree(List<UserData> allUsers) {
    final rootUsers = allUsers.where((u) => u.parentId == null).toList();
    List<FamilyUnit> units = [];
    for (var root in rootUsers) {
      if (root.userId == null) continue;
      final children = _findChildren(root.userId!, allUsers);
      units.add(
        FamilyUnit(
          headId: root.userId,
          nit: root.familyTreeId ?? "-",
          headName: root.fullName ?? "No Name",
          spouseName: null,
          location: root.address ?? "-",
          avatar: root.avatar is String ? root.avatar : null,
          birthYear: root.birthYear,
          children: children,
        ),
      );
    }
    return units;
  }

  List<ChildMember> _findChildren(int parentId, List<UserData> allUsers) {
    final children = allUsers.where((u) => u.parentId == parentId).toList();
    if (children.isEmpty) return [];
    return children.map((child) {
      List<ChildMember> grandChildren = [];
      if (child.userId != null) {
        grandChildren = _findChildren(child.userId!, allUsers);
      }
      return ChildMember(
        id: child.userId,
        nit: child.familyTreeId ?? "-",
        name: child.fullName ?? "No Name",
        spouseName: null,
        location: child.address ?? "-",
        emoji: '👤',
        photoUrl: child.avatar is String ? child.avatar : null,
        birthYear: child.birthYear,
        children: grandChildren,
      );
    }).toList();
  }
}
