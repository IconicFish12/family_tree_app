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

  List<FamilyUnit> _familyUnits = [];
  List<FamilyUnit> get familyUnits => _familyUnits;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> fetchData() async {
    _state = ViewState.loading;
    notifyListeners();

    final result = await _repositoryImpl.getData();

    print(result);
    result.fold(
      (failure) {
        _errorMessage = failure.message;
        _state = ViewState.error;
      },
      (successData) {
        try {
          _familyUnits = _buildFamilyTree(successData);
          _state = ViewState.success;
        } catch (e) {
          _errorMessage = "Gagal memproses data: $e";
          _state = ViewState.error;
        }
      },
    );

    notifyListeners();
  }

  
  List<FamilyUnit> _buildFamilyTree(List<UserData> allUsers) {
    final rootUsers = allUsers.where((u) => u.parentId == null).toList();

    List<FamilyUnit> units = [];

    for (var root in rootUsers) {

      if (root.userId == null) continue;

      final children = _findChildren(root.userId!, allUsers);

      units.add(FamilyUnit(
        nit: root.familyTreeId ?? "-",
        headName: root.fullName ?? "No Name",
        spouseName: null, 
        location: root.address ?? "-",
        children: children,
      ));
    }
    
    return units;
  }

  List<ChildMember> _findChildren(int parentId, List<UserData> allUsers) {
    final children = allUsers.where((u) => u.parentId == parentId).toList();

    if (children.isEmpty) {
      return [];
    }

    return children.map((child) {
      List<ChildMember> grandChildren = [];
      
      if (child.userId != null) {
        grandChildren = _findChildren(child.userId!, allUsers);
      }

      return ChildMember(
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