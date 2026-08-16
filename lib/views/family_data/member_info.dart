import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/components/family_edit_dialog.dart';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/marriage_role_policy.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/member_detail_provider.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:family_tree_app/core/nit_hierarchy.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MemberInfoPage extends StatefulWidget {
  final int memberId;
  final UserRepository? repository;

  const MemberInfoPage({super.key, required this.memberId, this.repository});

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends State<MemberInfoPage> {
  late final MemberDetailProvider _detailProvider;

  @override
  void initState() {
    super.initState();
    _detailProvider = MemberDetailProvider(
      widget.repository ?? UserRepositoryImpl(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detailProvider.load(widget.memberId);
    });
  }

  @override
  void dispose() {
    _detailProvider.dispose();
    super.dispose();
  }

  Future<void> _reload() => _detailProvider.load(widget.memberId);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MemberDetailProvider>.value(
      value: _detailProvider,
      child: Consumer<MemberDetailProvider>(
        builder: (context, detail, child) {
          return Scaffold(
            backgroundColor: Config.background,
            appBar: AppBar(
              backgroundColor: Color(0xFF559260),
              elevation: 0,
              leading: CustomBackButton(onPressed: () => context.pop()),
              title: const Text(
                'Detail Anggota',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              centerTitle: true,
            ),
            body: _buildBody(detail),
          );
        },
      ),
    );
  }

  Widget _buildBody(MemberDetailProvider detail) {
    if (detail.state == MemberDetailState.initial ||
        detail.state == MemberDetailState.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (detail.state == MemberDetailState.error || detail.member == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                detail.errorMessage ?? 'Detail anggota belum dapat dimuat.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Muat Ulang'),
              ),
            ],
          ),
        ),
      );
    }

    final member = detail.member!;
    final actor = context.watch<AuthProvider?>()?.currentUser;
    final isSelf = actor?.userId == member.userId;
    final canManage =
        actor == null ||
        canManageNit(actorNit: actor.nit, targetNit: member.nit);
    final canDelete = member.userId != null && !isSelf;

    return RefreshIndicator(
      onRefresh: _reload,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(member),
          const SizedBox(height: 16),
          _buildFamilyStatus(detail.marriages),
          const SizedBox(height: 16),
          _buildInfoSection(member),
          const SizedBox(height: 20),
          if (canManage)
            _buildManagementActions(detail, member, isSelf: isSelf)
          else
            _buildReadOnlyNotice(),
          const SizedBox(height: 24),
          _buildMarriageSection(detail, canManage: canManage),
          const SizedBox(height: 24),
          _buildDescendantSection(detail),
          if (canDelete) ...[
            const SizedBox(height: 24),
            _buildDeleteMemberButton(detail),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserData member) {
    final avatar = Config.getAvatarUrl(
      avatar: member.avatar,
      avatarUrl: member.avatarUrl,
    );
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            MemberAvatar(photoUrl: avatar, size: 96, borderRadius: 48),
            const SizedBox(height: 12),
            Text(
              member.fullName ?? 'Tanpa Nama',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Config.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'NIT ${member.nit ?? '-'}',
                style: const TextStyle(
                  color: Config.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFamilyStatus(List<FamilyTreeMarriage> marriages) {
    final hasFamily = marriages.isNotEmpty;
    final spouseNames = marriages
        .map((marriage) => marriage.spouse?.fullName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasFamily
            ? Config.primary.withValues(alpha: 0.10)
            : Colors.grey.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasFamily
              ? Config.primary.withValues(alpha: 0.30)
              : Colors.grey.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hasFamily ? Icons.favorite : Icons.favorite_border,
            color: hasFamily ? Config.primary : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFamily ? 'Sudah berkeluarga' : 'Belum berkeluarga',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (spouseNames.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Pasangan: ${spouseNames.join(', ')}'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(UserData member) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildInfoRow(
              'Jenis Kelamin',
              member.gender?.label ?? 'Belum diketahui',
            ),
            const Divider(height: 24),
            _buildInfoRow('Tahun Lahir', member.birthYear ?? '-'),
            const Divider(height: 24),
            _buildInfoRow('Alamat', member.address ?? '-'),
            if (member.parentRelation?.relationshipType != null) ...[
              const Divider(height: 24),
              _buildInfoRow(
                'Status Relasi',
                member.parentRelation!.relationshipType!.label,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: TextStyle(color: Config.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildManagementActions(
    MemberDetailProvider detail,
    UserData member, {
    required bool isSelf,
  }) {
    final memberId = member.userId!;
    final rolePolicy = detail.marriageRolePolicy;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kelola Data',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildMarriageRolePolicyNotice(rolePolicy),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: _blocksChildCreation(rolePolicy)
                  ? null
                  : () async {
                      final changed = await context.pushNamed<bool>(
                        'addFamilyMember',
                        queryParameters: {'parentId': '$memberId'},
                      );
                      if (changed == true && mounted) await _reload();
                    },
              icon: const Icon(Icons.child_care),
              label: const Text('Tambah Anak'),
            ),
            ElevatedButton.icon(
              onPressed: rolePolicy.canCreateMarriage
                  ? () async {
                      final changed = await context.pushNamed<bool>(
                        'addFamily',
                        queryParameters: {'memberId': '$memberId'},
                      );
                      if (changed == true && mounted) await _reload();
                    }
                  : null,
              icon: const Icon(Icons.favorite_outline),
              label: const Text('Tambah Pasangan'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                if (isSelf) {
                  final changed = await context.pushNamed<bool>('profileEdit');
                  if (changed == true && mounted) await _reload();
                } else {
                  await _showEditMemberDialog(member);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: Text(isSelf ? 'Edit Profil Saya' : 'Edit Anggota'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMarriageRolePolicyNotice(MarriageRolePolicy policy) {
    final hasRelationshipIssue = _blocksChildCreation(policy);
    final message = switch (policy.state) {
      MarriageRolePolicyState.conflicting =>
        '${policy.blockingMessage} Untuk merapikannya, hapus anak pada pernikahan yang salah terlebih dahulu, lalu hapus pasangan tersebut.',
      MarriageRolePolicyState.legacyUnclassified =>
        '${policy.blockingMessage} Rapikan relasi pernikahan lama terlebih dahulu agar anak tidak ditambahkan ke cabang yang belum pasti.',
      _ => policy.blockingMessage ?? policy.guidanceMessage,
    };
    final isBlocking = policy.hasBlockingIssue;
    final accentColor = isBlocking ? Colors.orange.shade800 : Config.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isBlocking ? Icons.info_outline : Icons.check_circle_outline,
            color: accentColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(switch (policy.state) {
                  MarriageRolePolicyState.conflicting ||
                  MarriageRolePolicyState.legacyUnclassified =>
                    'Rapikan data pernikahan terlebih dahulu',
                  MarriageRolePolicyState.unset =>
                    'Peran pernikahan belum ditentukan',
                  MarriageRolePolicyState.lockedHusband ||
                  MarriageRolePolicyState.lockedWife =>
                    'Peran anggota: ${policy.lockedRole!.label}',
                }, style: const TextStyle(fontWeight: FontWeight.w700)),
                if (message.trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(message, style: const TextStyle(height: 1.4)),
                ],
                if (hasRelationshipIssue) ...[
                  const SizedBox(height: 6),
                  const Text(
                    'Tambah Anak dan Tambah Pasangan dinonaktifkan sementara supaya data tidak semakin membesar.',
                    style: TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _blocksChildCreation(MarriageRolePolicy policy) {
    return !policy.canAddChild;
  }

  Widget _buildReadOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, color: Colors.blue),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data ini dapat dilihat, tetapi hanya anggota tersebut dan keturunannya yang dapat Anda kelola.',
              style: TextStyle(height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarriageSection(
    MemberDetailProvider detail, {
    required bool canManage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pasangan (${detail.marriages.length})',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (detail.marriages.isEmpty)
          _buildEmptyCard('Belum ada data pasangan.')
        else
          ...detail.marriages.map(
            (marriage) =>
                _buildMarriageCard(detail, marriage, canManage: canManage),
          ),
      ],
    );
  }

  Widget _buildMarriageCard(
    MemberDetailProvider detail,
    FamilyTreeMarriage marriage, {
    required bool canManage,
  }) {
    final spouse = marriage.spouse;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(child: Icon(Icons.favorite_outline)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spouse?.fullName ?? 'Pasangan belum diketahui',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pasangan ${marriage.marriageOrder} • ${marriage.children.length} anak',
                        style: TextStyle(color: Config.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (!marriage.isRoleClassified)
              _buildMarriageClassificationNotice()
            else ...[
              _buildMarriageParticipantRow(
                name: detail.member?.fullName ?? 'Anggota keluarga',
                role: marriage.memberRole,
                isFamilyHead:
                    marriage.familyHeadPosition == FamilyHeadPosition.member,
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 8),
              _buildMarriageParticipantRow(
                name: spouse?.fullName ?? 'Pasangan belum diketahui',
                role: marriage.spouseRole,
                isFamilyHead:
                    marriage.familyHeadPosition == FamilyHeadPosition.spouse,
                icon: Icons.favorite_outline,
              ),
            ],
            const SizedBox(height: 10),
            Text(
              'Jenis kelamin pasangan: ${spouse?.gender?.label ?? 'Belum diketahui'}',
            ),
            if (spouse?.birthYear?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text('Tahun lahir: ${spouse!.birthYear}'),
            ],
            if (spouse?.address?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text('Alamat: ${spouse!.address}'),
            ],
            if (canManage) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () =>
                        _showEditMarriageDialog(detail.member!, marriage),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Pasangan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () =>
                        _confirmDeleteMarriage(detail.member!, marriage),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMarriageClassificationNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 18, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(child: Text('Status pasangan belum diklasifikasikan')),
        ],
      ),
    );
  }

  Widget _buildMarriageParticipantRow({
    required String name,
    required MarriageRole? role,
    required bool isFamilyHead,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Config.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Config.primaryDark),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(
                  role?.label ?? 'Belum diklasifikasikan',
                  style: TextStyle(color: Config.textSecondary),
                ),
              ],
            ),
          ),
          if (isFamilyHead) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Config.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Kepala Keluarga',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Config.primaryDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDescendantSection(MemberDetailProvider detail) {
    final children = detail.directChildren;
    final descendantTreeError = detail.descendantTreeError;
    final hasCompleteCount =
        descendantTreeError == null && !detail.isLoadingDescendantTree;
    final childCountLabel = hasCompleteCount
        ? '${children.length} anak'
        : children.isEmpty
        ? 'data belum lengkap'
        : 'minimal ${children.length} anak';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Anak dan Cucu ($childCountLabel)',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        if (detail.isLoadingDescendantTree)
          _buildDescendantTreeStatus(
            message: 'Memuat data anak adopsi tanpa pernikahan...',
            isLoading: true,
          )
        else if (descendantTreeError != null)
          _buildDescendantTreeStatus(
            message:
                'Data anak adopsi tanpa pernikahan belum dapat dimuat. '
                '$descendantTreeError',
            onRetry: detail.retryDescendantTree,
          ),
        if (children.isEmpty &&
            descendantTreeError == null &&
            !detail.isLoadingDescendantTree)
          _buildEmptyCard('Belum ada data anak.'),
        if (children.isNotEmpty)
          ...children.map((child) => _buildChildCard(detail, child)),
      ],
    );
  }

  Widget _buildDescendantTreeStatus({
    required String message,
    bool isLoading = false,
    VoidCallback? onRetry,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isLoading
            ? Config.primary.withValues(alpha: 0.07)
            : Colors.orange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(Icons.info_outline, size: 20, color: Colors.orange),
              const SizedBox(width: 9),
              Expanded(
                child: Text(message, style: const TextStyle(height: 1.4)),
              ),
            ],
          ),
          if (onRetry != null)
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Coba Lagi'),
            ),
        ],
      ),
    );
  }

  Widget _buildChildCard(MemberDetailProvider detail, FamilyTreeNode child) {
    final childId = child.userId;
    final childDetail = childId == null ? null : detail.detailForChild(childId);
    final grandchildren = childId == null
        ? const <FamilyTreeNode>[]
        : detail.grandchildrenForChild(childId);
    final childError = childId == null ? null : detail.errorForChild(childId);
    final isLoadingChild = childId != null && detail.isLoadingChild(childId);
    final hasCompleteTreeBranch =
        childId != null && detail.hasCompleteTreeBranchFor(childId);
    final grandchildSummary = grandchildren.isEmpty
        ? hasCompleteTreeBranch
              ? 'Belum ada cucu dari cabang ini.'
              : 'Data cucu adopsi tanpa pernikahan belum dapat dipastikan.'
        : hasCompleteTreeBranch
        ? 'Cucu: ${grandchildren.map((item) => item.fullName).join(', ')}'
        : 'Cucu yang berhasil dimuat: '
              '${grandchildren.map((item) => item.fullName).join(', ')}. '
              'Data cucu adopsi tanpa pernikahan belum dapat dipastikan.';
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: childId == null
            ? null
            : () async {
                final changed = await context.pushNamed<bool>(
                  'memberInfo',
                  pathParameters: {'memberId': '$childId'},
                );
                if (changed == true && mounted) await _reload();
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(
                    photoUrl: Config.getAvatarUrl(
                      avatar: child.avatar,
                      avatarUrl: child.avatarUrl,
                    ),
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          child.fullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'NIT ${childDetail?.nit ?? child.nit ?? '-'}',
                          style: TextStyle(color: Config.textSecondary),
                        ),
                        if (child.relationshipType != null) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    child.relationshipType ==
                                        ChildRelationshipType.adopted
                                    ? Colors.orange.withValues(alpha: 0.12)
                                    : Config.primary.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                child.relationshipType!.label,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              if (isLoadingChild)
                const Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Memuat ulang data cabang...'),
                  ],
                )
              else if (childError != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data cabang gagal dimuat. $childError',
                        style: const TextStyle(color: Colors.red, height: 1.4),
                      ),
                      if (childId != null)
                        TextButton.icon(
                          onPressed: () => detail.retryChildData(childId),
                          icon: const Icon(Icons.refresh, size: 18),
                          label: const Text('Coba Lagi'),
                        ),
                    ],
                  ),
                )
              else
                Text(
                  grandchildSummary,
                  style: TextStyle(color: Config.textSecondary, height: 1.4),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  Widget _buildDeleteMemberButton(MemberDetailProvider detail) {
    final hasStructure =
        detail.marriages.isNotEmpty || detail.directChildren.isNotEmpty;
    final isStructureIncomplete =
        detail.descendantTreeError != null || detail.isLoadingDescendantTree;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: hasStructure || isStructureIncomplete
              ? null
              : () => _confirmDeleteMember(detail.member!),
          icon: const Icon(Icons.delete_outline),
          label: const Text('Hapus Anggota'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
        ),
        if (hasStructure)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Hapus pasangan dan keturunannya terlebih dahulu sebelum menghapus anggota ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
        if (!hasStructure && isStructureIncomplete)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Muat data anak adopsi terlebih dahulu sebelum menghapus anggota ini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }

  Future<void> _showEditMemberDialog(UserData member) async {
    final changed = await showFamilyEditDialog(
      context: context,
      mode: FamilyEditMode.member,
      initialData: member,
      memberId: member.userId!,
    );
    if (changed == true && mounted) await _reload();
  }

  Future<void> _showEditMarriageDialog(
    UserData member,
    FamilyTreeMarriage marriage,
  ) async {
    final spouse = marriage.spouse;
    final changed = await showFamilyEditDialog(
      context: context,
      mode: FamilyEditMode.spouse,
      initialData: UserData(
        fullName: spouse?.fullName,
        gender: spouse?.gender,
        address: spouse?.address,
        birthYear: spouse?.birthYear,
      ),
      memberId: member.userId!,
      marriageId: marriage.marriageId,
      actorNit: context.read<AuthProvider?>()?.currentUser?.nit,
      targetNit: member.nit,
    );
    if (changed == true && mounted) {
      await context.read<TreeProvider>().refreshCurrentTree();
      await _reload();
    }
  }

  Future<void> _confirmDeleteMarriage(
    UserData member,
    FamilyTreeMarriage marriage,
  ) async {
    if (marriage.children.isNotEmpty) {
      _showError(
        'Pernikahan masih mempunyai anak. Hapus data anak terlebih dahulu.',
      );
      return;
    }
    final confirmed = await _confirm(
      title: 'Hapus pasangan?',
      message:
          'Data pasangan ${marriage.spouse?.fullName ?? ''} akan dihapus dari silsilah.',
    );
    if (!confirmed || !mounted) return;
    final provider = context.read<UserProvider>();
    final success = await provider.deleteMarriage(
      marriageId: marriage.marriageId,
      memberId: member.userId!,
      actorNit: context.read<AuthProvider?>()?.currentUser?.nit,
      targetNit: member.nit,
    );
    if (!mounted) return;
    if (!success) {
      _showError(provider.errorMessage ?? 'Pasangan gagal dihapus.');
      return;
    }
    await context.read<TreeProvider>().refreshCurrentTree();
    await _reload();
  }

  Future<void> _confirmDeleteMember(UserData member) async {
    final confirmed = await _confirm(
      title: 'Hapus anggota?',
      message:
          'Data ${member.fullName ?? 'anggota ini'} akan dihapus. Tindakan ini tidak dapat dibatalkan.',
    );
    if (!confirmed || !mounted) return;
    final provider = context.read<UserProvider>();
    final success = await provider.deleteFamilyMember(member.userId!);
    if (!mounted) return;
    if (!success) {
      _showError(provider.errorMessage ?? 'Anggota gagal dihapus.');
      return;
    }
    await context.read<TreeProvider>().refreshCurrentTree();
    if (mounted) context.pop(true);
  }

  Future<bool> _confirm({
    required String title,
    required String message,
  }) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(dialogContext).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Ya, Hapus'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
}
