import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:family_tree_app/data/repository/failure.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:family_tree_app/views/family_data/tree_visual.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'tree menampilkan role oriented, head, legacy, dan dua cabang adopted',
    (tester) async {
      final provider = TreeProvider(_TreeVisualRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<TreeProvider>.value(
          value: provider,
          child: const MaterialApp(home: TreeVisualPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Awal Cabang'), findsOneWidget);
      expect(find.text('Jenis kelamin: Perempuan'), findsOneWidget);
      expect(find.text('Istri'), findsNothing);
      expect(find.text('Suami'), findsOneWidget);
      expect(find.text('Kepala Keluarga'), findsOneWidget);
      expect(find.text('Belum diklasifikasikan'), findsNWidgets(2));

      expect(find.text('Cabang Pasangan 1'), findsOneWidget);
      expect(find.text('Cabang Pasangan 2'), findsOneWidget);
      expect(find.text('Cabang Anak Adopsi'), findsOneWidget);
      expect(find.text('Anak Kandung'), findsNWidgets(2));
      expect(find.text('Anak Adopsi'), findsNWidgets(2));
      expect(find.text('Anak Adopsi Pasangan'), findsOneWidget);
      expect(find.text('Anak Adopsi Personal'), findsOneWidget);
      expect(find.text('Pasangan belum diketahui'), findsOneWidget);
    },
  );

  testWidgets(
    'mixed role menampilkan konflik tanpa badge role dan head global',
    (tester) async {
      final provider = TreeProvider(_MixedRoleTreeRepository());

      await tester.pumpWidget(
        ChangeNotifierProvider<TreeProvider>.value(
          value: provider,
          child: const MaterialApp(home: TreeVisualPage()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Konflik peran'), findsOneWidget);
      expect(find.text('Suami'), findsOneWidget);
      expect(find.text('Istri'), findsOneWidget);
      expect(find.text('Kepala Keluarga'), findsNothing);
      expect(find.text('Pasangan Pertama'), findsOneWidget);
      expect(find.text('Pasangan Kedua'), findsOneWidget);
    },
  );
}

class _TreeVisualRepository extends UserRepositoryImpl {
  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    return const Right(
      FamilyTreeResponse(
        root: FamilyTreeNode(
          userId: 1,
          nit: '1',
          familyTreeId: '1',
          level: 1,
          fullName: 'Roisah',
          gender: PersonGender.female,
          marriages: [
            FamilyTreeMarriage(
              marriageId: 10,
              marriageOrder: 1,
              memberRole: MarriageRole.wife,
              spouseRole: MarriageRole.husband,
              isRoleClassified: true,
              familyHeadPosition: FamilyHeadPosition.spouse,
              familyHeadUserId: 2,
              spouse: FamilyTreeSpouse(
                userId: 2,
                familyTreeId: '1.0.1',
                level: 1,
                fullName: 'K. Iskandar',
                gender: PersonGender.male,
              ),
              children: [
                FamilyTreeNode(
                  userId: 3,
                  familyTreeId: '1.1.1',
                  level: 2,
                  fullName: 'Moh. Hardjo',
                  relationshipType: ChildRelationshipType.biological,
                ),
                FamilyTreeNode(
                  userId: 4,
                  familyTreeId: '1.1.2',
                  level: 2,
                  fullName: 'Anak Adopsi Pasangan',
                  relationshipType: ChildRelationshipType.adopted,
                ),
              ],
            ),
            FamilyTreeMarriage(
              marriageId: 11,
              marriageOrder: 2,
              spouse: null,
              children: [
                FamilyTreeNode(
                  userId: 6,
                  familyTreeId: '1.2.1',
                  level: 2,
                  fullName: 'Anak Legacy',
                  relationshipType: ChildRelationshipType.biological,
                ),
              ],
            ),
          ],
          adoptedChildren: [
            FamilyTreeNode(
              userId: 5,
              familyTreeId: '1.a.2',
              level: 2,
              fullName: 'Anak Adopsi Personal',
              relationshipType: ChildRelationshipType.adopted,
            ),
          ],
        ),
        meta: FamilyTreeMeta(authenticatedMemberId: 1, subtreeRootId: 1),
      ),
    );
  }
}

class _MixedRoleTreeRepository extends UserRepositoryImpl {
  @override
  Future<Either<Failure, FamilyTreeResponse>> getTree() async {
    return const Right(
      FamilyTreeResponse(
        root: FamilyTreeNode(
          userId: 1,
          nit: '1',
          familyTreeId: '1',
          level: 1,
          fullName: 'Anggota Konflik',
          marriages: [
            FamilyTreeMarriage(
              marriageId: 20,
              marriageOrder: 1,
              memberRole: MarriageRole.husband,
              spouseRole: MarriageRole.wife,
              isRoleClassified: true,
              familyHeadPosition: FamilyHeadPosition.member,
              familyHeadUserId: 1,
              spouse: FamilyTreeSpouse(
                userId: 20,
                familyTreeId: '1.0.1',
                level: 1,
                fullName: 'Pasangan Pertama',
              ),
              children: [],
            ),
            FamilyTreeMarriage(
              marriageId: 21,
              marriageOrder: 2,
              memberRole: MarriageRole.wife,
              spouseRole: MarriageRole.husband,
              isRoleClassified: true,
              familyHeadPosition: FamilyHeadPosition.member,
              familyHeadUserId: 1,
              spouse: FamilyTreeSpouse(
                userId: 21,
                familyTreeId: '1.0.2',
                level: 1,
                fullName: 'Pasangan Kedua',
              ),
              children: [],
            ),
          ],
        ),
        meta: FamilyTreeMeta(authenticatedMemberId: 1, subtreeRootId: 1),
      ),
    );
  }
}
