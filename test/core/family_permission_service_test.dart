import 'package:family_tree_app/core/family_permission_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FamilyPermissionService();

  group('FamilyPermissionService', () {
    test('aktor dapat mengelola diri dan seluruh keturunannya', () {
      expect(service.canManageMember(actorNit: '1', targetNit: '1'), isTrue);
      expect(
        service.canManageMember(actorNit: '1', targetNit: '1.1.2'),
        isTrue,
      );
      expect(
        service.canDeleteFamilyMember(actorNit: '1', targetNit: '1.2'),
        isTrue,
        reason: 'Anak dari pasangan kedua tetap keturunan langsung NIT 1.',
      );
    });

    test('aktor tidak dapat mengelola ancestor atau cabang saudara', () {
      expect(service.canManageMember(actorNit: '1.1', targetNit: '1'), isFalse);
      expect(
        service.canManageMember(actorNit: '1.1', targetNit: '1.2'),
        isFalse,
      );
      expect(
        service.canManageMember(actorNit: '1', targetNit: '10.1'),
        isFalse,
      );
    });

    test('edit dan delete member biasa tidak berlaku untuk diri sendiri', () {
      expect(
        service.canEditFamilyMember(actorNit: '1', targetNit: '1'),
        isFalse,
      );
      expect(
        service.canDeleteFamilyMember(actorNit: '1', targetNit: '1'),
        isFalse,
      );
      expect(
        service.canEditFamilyMember(actorNit: '1', targetNit: '1.1'),
        isTrue,
      );
    });

    test('izin ditolak jika salah satu NIT tidak tersedia', () {
      expect(
        service.canManageMember(actorNit: null, targetNit: '1.1'),
        isFalse,
      );
      expect(service.canManageMember(actorNit: '1', targetNit: ''), isFalse);
    });
  });
}
