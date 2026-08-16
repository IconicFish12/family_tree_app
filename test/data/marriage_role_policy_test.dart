import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/marriage_role_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MarriageRolePolicy', () {
    test('empty history allows choosing either role', () {
      final policy = MarriageRolePolicy.fromMarriages(const []);

      expect(policy.state, MarriageRolePolicyState.unset);
      expect(policy.lockedRole, isNull);
      expect(policy.canChooseRole, isTrue);
      expect(policy.canCreateMarriage, isTrue);
      expect(policy.hasBlockingIssue, isFalse);
      expect(policy.canAddChild, isTrue);
      expect(policy.childCreationBlockingMessage, isNull);
      expect(policy.blockingMessage, isNull);
      expect(policy.guidanceMessage, isNotEmpty);
      expect(policy.allowsRole(MarriageRole.husband), isTrue);
      expect(policy.allowsRole(MarriageRole.wife), isTrue);
    });

    test('consistent husband history locks and allows only husband', () {
      final policy = MarriageRolePolicy.fromMarriages([
        _marriage(
          id: 1,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
          status: 'married',
        ),
        _marriage(
          id: 2,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
          status: 'divorced',
        ),
      ]);

      expect(policy.state, MarriageRolePolicyState.lockedHusband);
      expect(policy.lockedRole, MarriageRole.husband);
      expect(policy.canChooseRole, isFalse);
      expect(policy.canCreateMarriage, isTrue);
      expect(policy.hasBlockingIssue, isFalse);
      expect(policy.canAddChild, isTrue);
      expect(policy.blockingMessage, isNull);
      expect(policy.allowsRole(MarriageRole.husband), isTrue);
      expect(policy.allowsRole(MarriageRole.wife), isFalse);
    });

    test('wife history stays locked and blocks every new marriage', () {
      final policy = MarriageRolePolicy.fromMarriages([
        _marriage(
          id: 1,
          memberRole: MarriageRole.wife,
          spouseRole: MarriageRole.husband,
          status: 'divorced',
        ),
      ]);

      expect(policy.state, MarriageRolePolicyState.lockedWife);
      expect(policy.lockedRole, MarriageRole.wife);
      expect(policy.canChooseRole, isFalse);
      expect(policy.canCreateMarriage, isFalse);
      expect(policy.hasBlockingIssue, isTrue);
      expect(policy.canAddChild, isTrue);
      expect(policy.blockingMessage, isNotEmpty);
      expect(policy.allowsRole(MarriageRole.husband), isFalse);
      expect(policy.allowsRole(MarriageRole.wife), isFalse);
    });

    test('one invalid classification makes the history legacy', () {
      final policy = MarriageRolePolicy.fromMarriages([
        _marriage(
          id: 1,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
        ),
        _marriage(
          id: 2,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.husband,
        ),
      ]);

      expect(policy.state, MarriageRolePolicyState.legacyUnclassified);
      expect(policy.lockedRole, isNull);
      expect(policy.canChooseRole, isFalse);
      expect(policy.canCreateMarriage, isFalse);
      expect(policy.hasBlockingIssue, isTrue);
      expect(policy.canAddChild, isFalse);
      expect(policy.childCreationBlockingMessage, isNotEmpty);
      expect(policy.blockingMessage, isNotEmpty);
      expect(policy.allowsRole(MarriageRole.husband), isFalse);
    });

    test('mixed valid roles take conflict priority over a legacy row', () {
      final policy = MarriageRolePolicy.fromMarriages([
        _marriage(
          id: 1,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
        ),
        _marriage(
          id: 2,
          memberRole: MarriageRole.wife,
          spouseRole: MarriageRole.husband,
        ),
        _marriage(id: 3, isRoleClassified: false),
      ]);

      expect(policy.state, MarriageRolePolicyState.conflicting);
      expect(policy.lockedRole, isNull);
      expect(policy.canChooseRole, isFalse);
      expect(policy.canCreateMarriage, isFalse);
      expect(policy.hasBlockingIssue, isTrue);
      expect(policy.canAddChild, isFalse);
      expect(policy.childCreationBlockingMessage, isNotEmpty);
      expect(policy.blockingMessage, isNotEmpty);
      expect(policy.allowsRole(MarriageRole.husband), isFalse);
      expect(policy.allowsRole(MarriageRole.wife), isFalse);
    });

    test('classified flag is required even for complementary role values', () {
      final policy = MarriageRolePolicy.fromMarriages([
        _marriage(
          id: 1,
          isRoleClassified: false,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
        ),
      ]);

      expect(policy.state, MarriageRolePolicyState.legacyUnclassified);
    });

    test('suami dengan empat istri tidak dapat menambah pasangan lagi', () {
      final policy = MarriageRolePolicy.fromMarriages([
        _marriage(
          id: 1,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
        ),
        _marriage(
          id: 2,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
        ),
        _marriage(
          id: 3,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
        ),
        _marriage(
          id: 4,
          memberRole: MarriageRole.husband,
          spouseRole: MarriageRole.wife,
        ),
      ]);

      expect(policy.wifeCount, 4);
      expect(policy.hasReachedWifeLimit, isTrue);
      expect(policy.canCreateMarriage, isFalse);
      expect(policy.allowsRole(MarriageRole.husband), isFalse);
      expect(policy.blockingMessage, contains('4 istri'));
    });
  });
}

FamilyTreeMarriage _marriage({
  required int id,
  bool isRoleClassified = true,
  MarriageRole? memberRole,
  MarriageRole? spouseRole,
  String status = 'married',
}) {
  return FamilyTreeMarriage(
    marriageId: id,
    marriageOrder: id,
    status: status,
    memberRole: memberRole,
    spouseRole: spouseRole,
    isRoleClassified: isRoleClassified,
    spouse: null,
    children: const [],
  );
}
