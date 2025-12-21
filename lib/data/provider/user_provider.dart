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
        _state = ViewState.success;
      },
    );
    notifyListeners();
  }

  String _generateNextFamilyTreeId(int? parentId) {
    try {
      if (_rawAllUsers.isEmpty) {
        print(
          "⚠️ WARNING: Data lokal kosong. ID yang digenerate mungkin konflik dengan server.",
        );
      }

      if (parentId == null) {
        final rootUsers = _rawAllUsers
            .where((u) => u.parentId == null)
            .toList();

        if (rootUsers.isEmpty) return "1";

        int maxId = 0;
        for (var user in rootUsers) {
          if (user.familyTreeId != null) {
            String cleanId = user.familyTreeId!
                .split('.')
                .first
                .replaceAll(RegExp(r'[^0-9]'), '');
            int? currentId = int.tryParse(cleanId);
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
      print("ERROR: Gagal generate ID: $e");
      return "0";
    }
  }

  Future<bool> addUser(UserData newUser) async {
    _isSubmitting = true;
    notifyListeners();

    String generatedId = _generateNextFamilyTreeId(newUser.parentId);
    print(
      "DEBUG: Menambahkan User. ParentID: ${newUser.parentId}, Generated ID: $generatedId",
    );
    print(newUser);
    
    final userToSend = newUser.copyWith(
      familyTreeId: generatedId,
      parentId: newUser.parentId, 
    );

    final result = await _repositoryImpl.createUser(userToSend);

    return result.fold(
      (failure) {
        print(
          "DEBUG: Gagal ke Server: ${failure.message}",
        ); // Lihat pesan asli errornya
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (createdUser) {
        print("DEBUG: Sukses tambah user: ${createdUser.fullName}");
        _rawAllUsers.add(createdUser);
        _familyUnits = _buildFamilyTree(_rawAllUsers); 
        _isSubmitting = false;
        notifyListeners();
        return true;
      },
    );
  }

  Future<bool> addSpouse({
    required UserData spouseData, 
    required int currentUserId 
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final userResult = await _repositoryImpl.createUser(spouseData);

    return userResult.fold(
      (failure) {
        _errorMessage = "Gagal membuat user pasangan: ${failure.message}";
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (createdSpouse) async {
        if (createdSpouse.userId == null) {
          _errorMessage = "ID Pasangan tidak ditemukan dari server.";
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
          (success) {
            _rawAllUsers.add(createdSpouse);
            _familyUnits = _buildFamilyTree(_rawAllUsers);
            _isSubmitting = false;
            notifyListeners();
            return true;
          },
        );
      },
    );
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
        children: grandChildren,
      );
    }).toList();
  }

  Future<UserData?> updateProfile({
    required String id,
    required UserData data,
  }) async {
    _isSubmitting = true;
    notifyListeners();

    final result = await _repositoryImpl.updateProfile(id, data);

    return result.fold(
      (failure) {
        print(
          "DEBUG: Gagal ke Server: ${failure.message}",
        ); 
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return null;
      },
      (updatedUser) {
        final index = _rawAllUsers.indexWhere((u) => u.userId.toString() == id);
        if (index != -1) {
          _rawAllUsers[index] = updatedUser;
          _familyUnits = _buildFamilyTree(_rawAllUsers);
        }

        _isSubmitting = false;
        notifyListeners();
        return updatedUser;
      },
    );
  }
}
