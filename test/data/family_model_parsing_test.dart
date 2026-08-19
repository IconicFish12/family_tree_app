import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('person dan directory parse gender nullable serta parent relation', () {
    final person = UserData.fromJson({
      'user_id': 4,
      'nit': '1.2',
      'family_tree_id': '1.a.2',
      'full_name': 'Anak Adopsi',
      'gender': null,
      'birth_year': 1995,
      'avatar_url': 'https://example.test/avatar.webp',
      'parent_relation': {
        'relation_id': '12',
        'parent_id': 1,
        'child_id': 4,
        'marriage_id': null,
        'is_biological': false,
        'lineage_order': 2,
        'child_order': null,
      },
    });

    expect(person.gender, isNull);
    expect(person.birthYear, '1995');
    expect(person.avatarUrl, 'https://example.test/avatar.webp');
    expect(
      person.parentRelation?.relationshipType,
      ChildRelationshipType.adopted,
    );
    expect(person.parentRelation?.marriageId, isNull);

    final directoryMember = FamilyDirectoryMember.fromJson({
      'user_id': 5,
      'nit': '1.3',
      'family_tree_id': '1.1.2',
      'level': '2',
      'full_name': 'Anak Kandung',
      'gender': 'female',
      'parent_relation': {
        'relation_id': 13,
        'parent': {'user_id': '1'},
        'child_id': 5,
        'marriage': {'marriage_id': '10'},
        'is_biological': true,
        'lineage_order': 3,
        'child_order': 2,
      },
    });

    expect(directoryMember.gender, PersonGender.female);
    expect(directoryMember.parentRelation?.parentId, 1);
    expect(directoryMember.parentRelation?.marriageId, 10);
    expect(
      directoryMember.parentRelation?.relationshipType,
      ChildRelationshipType.biological,
    );
  });

  test('tree parse role terorientasi dan adopted children secara rekursif', () {
    final response = FamilyTreeResponse.fromJson({
      'data': {
        'user_id': 1,
        'nit': '1',
        'family_tree_id': '9000',
        'level': 1,
        'full_name': 'Root',
        'gender': 'female',
        'marriages': [
          {
            'marriage_id': 10,
            'marriage_order': 1,
            'member_role': 'wife',
            'spouse_role': 'husband',
            'is_role_classified': true,
            'family_head_position': 'spouse',
            'family_head_user_id': 2,
            'spouse': {
              'user_id': 2,
              'nit': null,
              'family_tree_id': '1.0.1',
              'level': 1,
              'full_name': 'Pasangan',
              'gender': 'male',
            },
            'children': [
              {
                'relation_id': 20,
                'parent_id': 1,
                'child_id': 3,
                'marriage_id': 10,
                'is_biological': true,
                'lineage_order': 1,
                'child_order': 1,
                'user_id': 3,
                'nit': '1.1',
                'family_tree_id': '1.1.1',
                'level': 2,
                'full_name': 'Anak Kandung',
                'gender': null,
                'marriages': <dynamic>[],
                'adopted_children': <dynamic>[],
              },
            ],
          },
        ],
        'adopted_children': [
          {
            'relation_id': 21,
            'parent_id': 1,
            'child_id': 4,
            'marriage_id': null,
            'is_biological': false,
            'lineage_order': 2,
            'child_order': null,
            'user_id': 4,
            'nit': '1.2',
            'family_tree_id': '1.a.2',
            'level': 2,
            'full_name': 'Anak Adopsi',
            'gender': null,
            'marriages': <dynamic>[],
            'adopted_children': [
              {
                'relation_id': 22,
                'parent_id': 4,
                'child_id': 5,
                'marriage_id': null,
                'is_biological': false,
                'lineage_order': 1,
                'child_order': null,
                'user_id': 5,
                'nit': '1.2.1',
                'family_tree_id': '1.a.2.a.1',
                'level': 3,
                'full_name': 'Cucu Adopsi',
                'gender': 'male',
                'marriages': <dynamic>[],
                'adopted_children': <dynamic>[],
              },
            ],
          },
        ],
      },
      'meta': {'authenticated_member_id': '1', 'subtree_root_id': 1},
    });

    expect(response.meta.authenticatedMemberId, 1);
    expect(response.root.gender, PersonGender.female);
    expect(response.root.nit, isNot(response.root.familyTreeId));

    final marriage = response.root.marriages.single;
    expect(marriage.memberRole, MarriageRole.wife);
    expect(marriage.spouseRole, MarriageRole.husband);
    expect(marriage.isRoleClassified, isTrue);
    expect(marriage.familyHeadPosition, FamilyHeadPosition.spouse);
    expect(marriage.spouse?.gender, PersonGender.male);
    expect(marriage.spouse?.nit, isNull);
    expect(
      marriage.children.single.relationshipType,
      ChildRelationshipType.biological,
    );

    final adopted = response.root.adoptedChildren.single;
    expect(adopted.relationshipType, ChildRelationshipType.adopted);
    expect(adopted.marriageId, isNull);
    expect(adopted.adoptedChildren.single.fullName, 'Cucu Adopsi');
    expect(adopted.hasDescendants, isTrue);
    expect(response.root.hasDescendants, isTrue);
  });

  test('legacy marriage dan nilai enum asing tetap aman diparse', () {
    final marriage = FamilyTreeMarriage.fromJson({
      'marriage_id': '15',
      'marriage_order': '2',
      'member_role': null,
      'spouse_role': 'unknown-role',
      'is_role_classified': false,
      'family_head_position': null,
      'family_head_user_id': null,
      'spouse': null,
      'children': <dynamic>[],
    });

    expect(marriage.memberRole, isNull);
    expect(marriage.spouseRole, isNull);
    expect(marriage.isRoleClassified, isFalse);
    expect(marriage.familyHeadPosition, isNull);
    expect(marriage.familyHeadUserId, isNull);
    expect(marriage.spouse, isNull);
    expect(personGenderFromJson('unknown'), isNull);
  });

  test(
    'is_biological diprioritaskan dan relationship_type legacy tetap dibaca',
    () {
      final currentRelation = ParentChildRelationData.fromJson({
        'relation_id': 30,
        'is_biological': '0',
        'relationship_type': 'biological',
      });
      final legacyRelation = ParentChildRelationData.fromJson({
        'relation_id': 31,
        'relationship_type': 'adopted',
      });

      expect(currentRelation.relationshipType, ChildRelationshipType.adopted);
      expect(legacyRelation.relationshipType, ChildRelationshipType.adopted);

      final serialized = legacyRelation.toJson();
      expect(serialized['is_biological'], isFalse);
      expect(serialized, isNot(contains('relationship_type')));
    },
  );
}
