import 'package:family_tree_app/core/nit_generator_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = NitGeneratorService();

  group('NitGeneratorService', () {
    test('membuat anak pertama untuk parent NIT 1', () {
      expect(
        service.generateNextNit(parentNit: '1', directChildNits: const []),
        '1.1',
      );
    });

    test('melanjutkan urutan terbesar anak langsung', () {
      expect(
        service.generateNextNit(
          parentNit: '1',
          directChildNits: const ['1.1', '1.2'],
        ),
        '1.3',
      );
    });

    test('tidak memakai kembali nomor yang hilang', () {
      expect(
        service.generateNextNit(
          parentNit: '1',
          directChildNits: const ['1.1', '1.2', '1.4'],
        ),
        '1.5',
      );
    });

    test('membuat NIT cucu dari NIT parent lengkap', () {
      expect(
        service.generateNextNit(parentNit: '1.1', directChildNits: const []),
        '1.1.1',
      );
    });

    test('mengabaikan keturunan yang bukan anak langsung', () {
      expect(
        service.generateNextNit(
          parentNit: '1.1',
          directChildNits: const ['1.1.1', '1.1.2', '1.1.1.1'],
        ),
        '1.1.3',
      );
    });

    test('urutan gabungan marriage tetap menghasilkan satu suffix', () {
      final childrenFromAllMarriages = <String>[
        ...const ['1.1'],
        ...const ['1.2'],
      ];

      expect(
        service.generateNextNit(
          parentNit: '1',
          directChildNits: childrenFromAllMarriages,
        ),
        '1.3',
      );
    });

    test('menolak NIT parent kosong atau tidak valid', () {
      expect(
        () => service.generateNextNit(parentNit: '', directChildNits: const []),
        throwsA(isA<NitGenerationException>()),
      );
      expect(
        () => service.generateNextNit(
          parentNit: '1.0.1',
          directChildNits: const [],
        ),
        throwsA(isA<NitGenerationException>()),
      );
    });

    test('menolak data NIT anak yang tidak lengkap', () {
      expect(
        () => service.generateNextNit(
          parentNit: '1',
          directChildNits: const ['1.1', ''],
        ),
        throwsA(isA<NitGenerationException>()),
      );
    });
  });
}
