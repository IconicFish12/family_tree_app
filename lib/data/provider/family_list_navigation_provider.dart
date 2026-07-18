import 'dart:collection';

import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:flutter/foundation.dart';

class FamilyListNavigationProvider extends ChangeNotifier {
  final List<Object> _breadcrumbs = [];

  UnmodifiableListView<Object> get breadcrumbs => UnmodifiableListView(
    _breadcrumbs,
  );

  bool get isAtRoot => _breadcrumbs.isEmpty;

  Object? get currentItem => _breadcrumbs.isEmpty ? null : _breadcrumbs.last;

  void navigateTo(Object item) {
    _breadcrumbs.add(item);
    notifyListeners();
  }

  void navigateBack() {
    if (_breadcrumbs.isEmpty) {
      return;
    }

    _breadcrumbs.removeLast();
    notifyListeners();
  }

  void navigateBackTo(int index) {
    final targetLength = index + 1;
    if (_breadcrumbs.length <= targetLength) {
      return;
    }

    _breadcrumbs.removeRange(targetLength, _breadcrumbs.length);
    notifyListeners();
  }

  void navigateHome() {
    if (_breadcrumbs.isEmpty) {
      return;
    }

    _breadcrumbs.clear();
    notifyListeners();
  }

  List<dynamic> resolveCurrentList(List<FamilyUnit> familyUnits) {
    if (_breadcrumbs.isEmpty) {
      return familyUnits;
    }

    final lastItem = _breadcrumbs.last;
    if (lastItem is FamilyUnit) {
      return lastItem.children;
    }
    if (lastItem is ChildMember) {
      return lastItem.children;
    }
    return const [];
  }

  int? resolveCurrentParentId() {
    final item = currentItem;
    if (item is FamilyUnit) {
      return item.headId;
    }
    if (item is ChildMember) {
      return item.id;
    }
    return null;
  }

  String? resolveCurrentParentName() {
    final item = currentItem;
    if (item is FamilyUnit) {
      return item.headName;
    }
    if (item is ChildMember) {
      return item.name;
    }
    return null;
  }
}
