import 'dart:collection';

import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

class FamilyMemberFormProvider extends ChangeNotifier {
  bool _isLoadingMarriages = false;
  List<FamilyTreeMarriage> _marriages = const [];
  String? _selectedMarriageId;
  XFile? _memberPhoto;

  bool get isLoadingMarriages => _isLoadingMarriages;
  UnmodifiableListView<FamilyTreeMarriage> get marriages =>
      UnmodifiableListView(_marriages);
  String? get selectedMarriageId => _selectedMarriageId;
  XFile? get memberPhoto => _memberPhoto;

  Future<void> loadMarriages(
    Future<List<FamilyTreeMarriage>> Function(int parentId) loader,
    int? parentId,
  ) async {
    if (parentId == null) {
      return;
    }

    _isLoadingMarriages = true;
    notifyListeners();

    final marriages = await loader(parentId);
    _marriages = marriages;
    _selectedMarriageId = marriages.length == 1
        ? marriages.first.marriageId.toString()
        : _selectedMarriageId;
    _isLoadingMarriages = false;
    notifyListeners();
  }

  void selectMarriage(String? marriageId) {
    if (_selectedMarriageId == marriageId) {
      return;
    }

    _selectedMarriageId = marriageId;
    notifyListeners();
  }

  void setMemberPhoto(XFile? file) {
    _memberPhoto = file;
  }
}
