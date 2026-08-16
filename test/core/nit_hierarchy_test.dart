import 'package:family_tree_app/core/nit_hierarchy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('akun dapat mengelola NIT miliknya sendiri', () {
    expect(canManageNit(actorNit: '1.1', targetNit: '1.1'), isTrue);
  });

  test('akun dapat mengelola anak langsung', () {
    expect(canManageNit(actorNit: '1.1', targetNit: '1.1.1'), isTrue);
  });

  test('akun tidak dapat mengelola orang tua atau cucu', () {
    expect(canManageNit(actorNit: '1.1', targetNit: '1'), isFalse);
    expect(canManageNit(actorNit: '1.1', targetNit: '1.1.1.1'), isFalse);
  });

  test('NIT kosong atau tidak valid ditolak', () {
    expect(canManageNit(actorNit: null, targetNit: '1'), isFalse);
    expect(canManageNit(actorNit: '1..1', targetNit: '1.1'), isFalse);
  });
}
