import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';

enum MarriageRolePolicyState {
  unset,
  lockedHusband,
  lockedWife,
  legacyUnclassified,
  conflicting,
}

class MarriageRolePolicy {
  final MarriageRolePolicyState state;

  const MarriageRolePolicy._(this.state);

  factory MarriageRolePolicy.fromMarriages(
    Iterable<FamilyTreeMarriage> marriages,
  ) {
    var hasInvalidMarriage = false;
    var hasHusbandRole = false;
    var hasWifeRole = false;

    for (final marriage in marriages) {
      if (!_isValidClassification(marriage)) {
        hasInvalidMarriage = true;
        continue;
      }

      if (marriage.memberRole == MarriageRole.husband) {
        hasHusbandRole = true;
      } else {
        hasWifeRole = true;
      }
    }

    // A mixed set is a stronger signal than an additional legacy row: the
    // participant already has contradictory authoritative classifications.
    if (hasHusbandRole && hasWifeRole) {
      return const MarriageRolePolicy._(MarriageRolePolicyState.conflicting);
    }
    if (hasInvalidMarriage) {
      return const MarriageRolePolicy._(
        MarriageRolePolicyState.legacyUnclassified,
      );
    }
    if (hasHusbandRole) {
      return const MarriageRolePolicy._(MarriageRolePolicyState.lockedHusband);
    }
    if (hasWifeRole) {
      return const MarriageRolePolicy._(MarriageRolePolicyState.lockedWife);
    }
    return const MarriageRolePolicy._(MarriageRolePolicyState.unset);
  }

  MarriageRole? get lockedRole => switch (state) {
    MarriageRolePolicyState.lockedHusband => MarriageRole.husband,
    MarriageRolePolicyState.lockedWife => MarriageRole.wife,
    _ => null,
  };

  bool get canChooseRole => state == MarriageRolePolicyState.unset;

  bool get canCreateMarriage => switch (state) {
    MarriageRolePolicyState.unset ||
    MarriageRolePolicyState.lockedHusband => true,
    MarriageRolePolicyState.lockedWife ||
    MarriageRolePolicyState.legacyUnclassified ||
    MarriageRolePolicyState.conflicting => false,
  };

  bool get hasBlockingIssue => !canCreateMarriage;

  bool get canAddChild => switch (state) {
    MarriageRolePolicyState.unset ||
    MarriageRolePolicyState.lockedHusband ||
    MarriageRolePolicyState.lockedWife => true,
    MarriageRolePolicyState.legacyUnclassified ||
    MarriageRolePolicyState.conflicting => false,
  };

  String? get childCreationBlockingMessage => switch (state) {
    MarriageRolePolicyState.legacyUnclassified =>
      'Anak belum dapat ditambahkan karena peran Suami/Istri pada pasangan lama belum lengkap. Rapikan relasi tersebut terlebih dahulu.',
    MarriageRolePolicyState.conflicting =>
      'Anak belum dapat ditambahkan karena anggota tercatat sebagai Suami dan Istri pada pasangan yang berbeda. Rapikan konflik peran terlebih dahulu.',
    _ => null,
  };

  String get guidanceMessage => switch (state) {
    MarriageRolePolicyState.unset =>
      'Pilih status hubungan yang benar',
    MarriageRolePolicyState.lockedHusband =>
      'Peran anggota dikunci sebagai Suami berdasarkan riwayat pernikahan. Untuk mengganti peran, hapus anak terkait terlebih dahulu lalu hapus seluruh data pasangan.',
    MarriageRolePolicyState.lockedWife =>
      'Peran anggota dikunci sebagai Istri dan Istri hanya dapat mempunyai satu Suami. Untuk mengganti peran, hapus anak terkait terlebih dahulu lalu hapus seluruh data pasangan.',
    MarriageRolePolicyState.legacyUnclassified =>
      'Riwayat pasangan lama belum memiliki peran Suami/Istri yang lengkap. Periksa dan rapikan data sebelum menambah pasangan baru. Jika relasi perlu dibuat ulang, hapus anak terkait terlebih dahulu, lalu hapus pasangan lama.',
    MarriageRolePolicyState.conflicting =>
      'Riwayat pernikahan memiliki konflik peran Suami dan Istri. Periksa dan rapikan data sebelum menambah pasangan baru. Jika data perlu dibuat ulang, hapus anak terkait terlebih dahulu, lalu hapus pasangan lama.',
  };

  String? get blockingMessage => switch (state) {
    MarriageRolePolicyState.unset ||
    MarriageRolePolicyState.lockedHusband => null,
    MarriageRolePolicyState.lockedWife =>
      'Anggota berperan sebagai Istri dan tidak dapat menambah Suami lagi. Jika peran ini salah, hapus anak terkait terlebih dahulu lalu hapus seluruh data pasangan.',
    MarriageRolePolicyState.legacyUnclassified =>
      'Peran Suami/Istri pada pasangan lama belum lengkap. Periksa dan rapikan data; bila relasi perlu dibuat ulang, hapus anak terkait terlebih dahulu, lalu hapus pasangan lama.',
    MarriageRolePolicyState.conflicting =>
      'Peran anggota berbeda pada riwayat pernikahan. Rapikan konflik data; bila perlu dibuat ulang, hapus anak terkait terlebih dahulu, lalu hapus pasangan lama.',
  };

  bool allowsRole(MarriageRole role) {
    if (!canCreateMarriage) return false;
    return switch (state) {
      MarriageRolePolicyState.unset => true,
      MarriageRolePolicyState.lockedHusband => role == MarriageRole.husband,
      MarriageRolePolicyState.lockedWife ||
      MarriageRolePolicyState.legacyUnclassified ||
      MarriageRolePolicyState.conflicting => false,
    };
  }

  static bool _isValidClassification(FamilyTreeMarriage marriage) {
    final memberRole = marriage.memberRole;
    final spouseRole = marriage.spouseRole;
    return marriage.isRoleClassified &&
        memberRole != null &&
        spouseRole != null &&
        spouseRole == _opposite(memberRole);
  }

  static MarriageRole _opposite(MarriageRole role) => switch (role) {
    MarriageRole.husband => MarriageRole.wife,
    MarriageRole.wife => MarriageRole.husband,
  };
}
