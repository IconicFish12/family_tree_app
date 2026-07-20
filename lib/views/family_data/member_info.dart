import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MemberInfoPage extends StatelessWidget {
  final ChildMember member;

  const MemberInfoPage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final allUsers = userProvider.allUsers;

    String? spouseNameStr = member.spouseName;
    String? spousePhotoUrl;

    if (member.nit.isNotEmpty && allUsers.isNotEmpty) {
      try {
        final spouse = allUsers.firstWhere((u) {
          return u.familyTreeId == member.nit &&
              u.parentId == null &&
              u.userId != member.id;
        });
        spouseNameStr ??= spouse.fullName;
        if (spouse.avatar is String) {
          spousePhotoUrl = spouse.avatar as String;
        }
      } catch (_) {}
    }

    final photoUrl = member.photoUrl != null && member.photoUrl!.isNotEmpty
        ? Config.getFullImageUrl(member.photoUrl!)
        : null;

    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.primary,
        elevation: 0,
        leading: CustomBackButton(
          color: Config.white,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.goNamed('familyList');
            }
          },
        ),
        title: const Text(
          "Detail Anggota",
          style: TextStyle(
            color: Config.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Config.white),
            tooltip: 'Edit Anggota',
            onPressed: () {
              context.pushNamed('editFamilyMember', extra: member);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Circle Avatar Header
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.grey.shade300,
                image: photoUrl != null
                    ? DecorationImage(
                        image: NetworkImage(photoUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: photoUrl == null
                  ? Icon(Icons.person, size: 54, color: Colors.grey.shade500)
                  : null,
            ),
            const SizedBox(height: 12),

            // Member Name
            Text(
              member.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Config.textHead,
              ),
            ),
            const SizedBox(height: 4),

            // Subtitle / Role
            Text(
              member.role ??
                  (spouseNameStr != null ? 'Kepala Keluarga' : 'Anggota Keluarga'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Config.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Side-by-side Cards: Nama Lengkap & Tanggal Lahir
            Row(
              children: [
                Expanded(
                  child: _buildSmallInfoCard(
                    title: 'Nama Lengkap',
                    value: member.name,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _buildSmallInfoCard(
                    title: 'Tanggal Lahir',
                    value: (member.birthYear != null && member.birthYear!.isNotEmpty)
                        ? member.birthYear!
                        : '-',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Wide Card: Jenis Kelamin
            _buildKeyValueCard(
              label: 'Jenis Kelamin',
              value: member.gender != null && member.gender!.isNotEmpty
                  ? _formatGender(member.gender)
                  : 'Laki – Laki',
            ),

            const SizedBox(height: 14),

            // Wide Card: NIT
            _buildKeyValueCard(
              label: 'NIT',
              value: member.nit.isNotEmpty ? member.nit : '-',
            ),

            const SizedBox(height: 14),

            // Note Card: Tempat tinggal
            _buildNoteCard(
              title: 'Tempat tinggal',
              content: member.location != null && member.location!.isNotEmpty
                  ? member.location!
                  : 'Belum ada data tempat tinggal.',
            ),

            const SizedBox(height: 24),

            // Section Hubungan (jika ada Pasangan)
            if (spouseNameStr != null) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Hubungan',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Config.textHead,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildRelationCard(
                context: context,
                name: spouseNameStr,
                subtitle: 'Pasangan / Ibu Rumah Tangga',
                photoUrl: spousePhotoUrl,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatGender(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '-';
    final g = raw.trim().toLowerCase();
    if (g == 'l' || g.startsWith('laki') || g == 'male' || g == 'm') {
      return 'Laki – Laki';
    }
    if (g == 'p' || g.startsWith('perempuan') || g == 'female' || g == 'f') {
      return 'Perempuan';
    }
    return raw;
  }

  Widget _buildSmallInfoCard({
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Config.textHead,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueCard({
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Config.textHead,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Config.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Config.textHead,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRelationCard({
    required BuildContext context,
    required String name,
    required String subtitle,
    String? photoUrl,
  }) {
    final fullPhotoUrl = photoUrl != null && photoUrl.isNotEmpty
        ? Config.getFullImageUrl(photoUrl)
        : null;

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // Photo / Placeholder Box
          Container(
            width: 95,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              image: fullPhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(fullPhotoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: fullPhotoUrl == null
                ? Icon(
                    Icons.person,
                    size: 44,
                    color: Colors.grey.shade500,
                  )
                : null,
          ),
          // Green Details Container
          Expanded(
            child: Container(
              height: double.infinity,
              color: Config.primary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Config.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 13,
                            color: Config.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: Config.white,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
