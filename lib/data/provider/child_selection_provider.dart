import 'dart:collection';

import 'package:flutter/foundation.dart';

class ChildSelectionProvider extends ChangeNotifier {
  ChildSelectionProvider({List<Map<String, dynamic>>? initialSelectedChildren})
    : _selectedChildren = List<Map<String, dynamic>>.from(
        initialSelectedChildren ?? const [],
      );

  final List<Map<String, dynamic>> _selectedChildren;

  UnmodifiableListView<Map<String, dynamic>> get selectedChildren =>
      UnmodifiableListView(_selectedChildren);

  bool isSelected(Map<String, dynamic> child) {
    return _selectedChildren.any((item) => item['id'] == child['id']);
  }

  void toggleChild(Map<String, dynamic> child) {
    final existingIndex = _selectedChildren.indexWhere(
      (item) => item['id'] == child['id'],
    );

    if (existingIndex >= 0) {
      _selectedChildren.removeAt(existingIndex);
    } else {
      _selectedChildren.add(child);
    }

    notifyListeners();
  }
}
