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

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // --- STATE DATA ---
  final List<UserData> _rawAllUsers = [];
  List<FamilyUnit> _familyUnits = [];
  List<FamilyUnit> get familyUnits => _familyUnits;

  // --- STATE PAGINATION ---
  int _currentPage = 1;
  bool _hasMoreData = true;
  bool _isLoadingMore = false;
  bool get isLoadingMore => _isLoadingMore;

  // --- STATE POSTING  ---
  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  // ===========================
  // 1. FETCH DATA & PAGINATION
  // ===========================
  Future<void> fetchData({bool isRefresh = false}) async {
    if (isRefresh) {
      _currentPage = 1;
      _rawAllUsers.clear(); // Reset data
      _hasMoreData = true;
      _state = ViewState.loading;
      notifyListeners();
    } else {
      // Logic Load More
      if (!_hasMoreData || _isLoadingMore) return;
      _isLoadingMore = true;
      notifyListeners();
    }

    final result = await _repositoryImpl.getData(page: _currentPage);

    result.fold(
      (failure) {
        _errorMessage = failure.message;
        if (isRefresh) _state = ViewState.error;
        _isLoadingMore = false;
      },
      (newUsers) {
        if (newUsers.isEmpty) {
          _hasMoreData = false;
        } else {
          _rawAllUsers.addAll(newUsers);
          _currentPage++;

          _familyUnits = _buildFamilyTree(_rawAllUsers);
        }
        _state = ViewState.success;
        _isLoadingMore = false;
      },
    );
    notifyListeners();
  }

  Future<bool> addUser(UserData newUser) async {
    _isSubmitting = true;
    notifyListeners();

    final result = await _repositoryImpl.createUser(newUser);

    return result.fold(
      (failure) {
        _errorMessage = failure.message;
        _isSubmitting = false;
        notifyListeners();
        return false; // Gagal
      },
      (createdUser) {
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
    required int currentUserId, // ID Suami/Istri yang sudah ada
  }) async {
    _isSubmitting = true;
    notifyListeners();

    // LANGKAH 1: Buat User Pasangannya dulu (di tabel User)
    final userResult = await _repositoryImpl.createUser(spouseData);

    return userResult.fold(
      (failure) {
        _errorMessage = "Gagal membuat user pasangan: ${failure.message}";
        _isSubmitting = false;
        notifyListeners();
        return false;
      },
      (createdSpouse) async {
        // LANGKAH 2: Hubungkan User Baru dengan User Lama di tabel Spouse
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
            // Opsional: Hapus user yang baru dibuat jika gagal linking (Rollback manual)
            _isSubmitting = false;
            notifyListeners();
            return false;
          },
          (success) {
            // SUKSES TOTAL
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
          spouseName:
              null,
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
}
