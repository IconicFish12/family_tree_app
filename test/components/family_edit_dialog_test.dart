import 'package:family_tree_app/components/family_edit_dialog.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final mode in FamilyEditMode.values) {
    testWidgets('dialog ${mode.name} aman dibatalkan ketika keyboard aktif', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showFamilyEditDialog(
                    context: context,
                    mode: mode,
                    initialData: const UserData(
                      userId: 1,
                      nit: '1',
                      fullName: 'Roisah',
                      birthYear: '1950',
                    ),
                    memberId: 1,
                    marriageId: mode == FamilyEditMode.spouse ? 10 : null,
                  ),
                  child: const Text('Buka Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Buka Dialog'));
      await tester.pumpAndSettle();

      final nameField = find
          .byType(TextFormField)
          .at(mode == FamilyEditMode.member ? 1 : 0);
      await tester.tap(nameField);
      await tester.showKeyboard(nameField);
      await tester.enterText(nameField, 'Nama Sementara');
      await tester.pump();

      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      expect(find.text('Batal'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
