import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/views/family_data/member_info.dart';
import 'package:flutter/material.dart';

/// Compatibility entry point for the former family-unit page.
///
/// Family relationships are no longer reconstructed from `family_tree_id`.
/// The authoritative member detail page loads the person and marriage records
/// directly from the backend by `user_id`.
class FamilyInfoPage extends StatelessWidget {
  final int? parentId;
  final String? initialHeadName;

  const FamilyInfoPage({
    super.key,
    this.parentId,
    this.initialHeadName,
    String? spouseName,
    List<ChildMember>? children,
  });

  @override
  Widget build(BuildContext context) {
    final memberId = parentId;
    if (memberId != null) {
      return MemberInfoPage(memberId: memberId);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Keluarga')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            initialHeadName == null
                ? 'Data anggota tidak valid.'
                : 'Data ${initialHeadName!} belum dapat dimuat.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
