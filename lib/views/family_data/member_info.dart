import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/components/family_edit_dialog.dart';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/core/family_permission_service.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/member_detail_provider.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MemberInfoPage extends StatefulWidget {
  final int memberId;

  const MemberInfoPage({super.key, required this.memberId});

  @override
  State<MemberInfoPage> createState() => _MemberInfoPageState();
}

class _MemberInfoPageState extends State<MemberInfoPage> {
  static const FamilyPermissionService _permissionService = FamilyPermissionService();

  late final MemberDetailProvider _detailProvider;

  @override
  void initState() {
    super.initState();
    _detailProvider = MemberDetailProvider(UserRepositoryImpl());
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
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
    if (detail.state == MemberDetailState.initial || detail.state == MemberDetailState.loading) {
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
              Text(detail.errorMessage ?? 'Detail anggota belum dapat dimuat.', textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(onPressed: _reload, icon: const Icon(Icons.refresh), label: const Text('Muat Ulang')),
            ],
          ),
        ),
      );
    }

    final member = detail.member!;
    final actor = context.watch<AuthProvider>().currentUser;
    final isSelf = actor?.userId == member.userId;
    final canManage = _permissionService.canManageMember(actorNit: actor?.nit, targetNit: member.nit);
    final canDelete = _permissionService.canDeleteFamilyMember(actorNit: actor?.nit, targetNit: member.nit);

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
          if (canManage) _buildManagementActions(member, isSelf: isSelf) else _buildReadOnlyNotice(),
          const SizedBox(height: 24),
          _buildMarriageSection(detail, canManage: canManage),
          const SizedBox(height: 24),
          _buildDescendantSection(detail),
          if (canDelete) ...[const SizedBox(height: 24), _buildDeleteMemberButton(detail)],
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserData member) {
    final avatar = member.avatar is String ? Config.getFullImageUrl(member.avatar as String) : null;
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
                style: const TextStyle(color: Config.primaryDark, fontWeight: FontWeight.w600),
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
        color: hasFamily ? Config.primary.withValues(alpha: 0.10) : Colors.grey.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hasFamily ? Config.primary.withValues(alpha: 0.30) : Colors.grey.withValues(alpha: 0.30)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(hasFamily ? Icons.favorite : Icons.favorite_border, color: hasFamily ? Config.primary : Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFamily ? 'Sudah berkeluarga' : 'Belum berkeluarga',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (spouseNames.isNotEmpty) ...[const SizedBox(height: 4), Text('Pasangan: ${spouseNames.join(', ')}')],
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
            _buildInfoRow('Tahun Lahir', member.birthYear ?? '-'),
            const Divider(height: 24),
            _buildInfoRow('Alamat', member.address ?? '-'),
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
          child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }

  Widget _buildManagementActions(UserData member, {required bool isSelf}) {
    final memberId = member.userId!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kelola Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                final changed = await context.pushNamed<bool>('addFamilyMember', queryParameters: {'parentId': '$memberId'});
                if (changed == true && mounted) await _reload();
              },
              icon: const Icon(Icons.child_care),
              label: const Text('Tambah Anak'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                final changed = await context.pushNamed<bool>('addFamily', queryParameters: {'memberId': '$memberId'});
                if (changed == true && mounted) await _reload();
              },
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

  Widget _buildReadOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12)),
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

  Widget _buildMarriageSection(MemberDetailProvider detail, {required bool canManage}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Pasangan (${detail.marriages.length})', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (detail.marriages.isEmpty)
          _buildEmptyCard('Belum ada data pasangan.')
        else
          ...detail.marriages.map((marriage) => _buildMarriageCard(detail, marriage, canManage: canManage)),
      ],
    );
  }

  Widget _buildMarriageCard(MemberDetailProvider detail, FamilyTreeMarriage marriage, {required bool canManage}) {
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
            if (spouse?.birthYear?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Text('Tahun lahir: ${spouse!.birthYear}'),
            ],
            if (spouse?.address?.isNotEmpty == true) ...[const SizedBox(height: 4), Text('Alamat: ${spouse!.address}')],
            if (canManage) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showEditMarriageDialog(detail.member!, marriage),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit Pasangan'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDeleteMarriage(detail.member!, marriage),
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Hapus'),
                    style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDescendantSection(MemberDetailProvider detail) {
    final children = detail.directChildren;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Anak dan Cucu (${children.length} anak)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        if (children.isEmpty)
          _buildEmptyCard('Belum ada data anak.')
        else
          ...children.map((child) => _buildChildCard(detail, child)),
      ],
    );
  }

  Widget _buildChildCard(MemberDetailProvider detail, FamilyTreeNode child) {
    final childId = child.userId;
    final childDetail = childId == null ? null : detail.detailForChild(childId);
    final grandchildren = childId == null ? const <FamilyTreeNode>[] : detail.grandchildrenForChild(childId);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: childId == null
            ? null
            : () async {
                final changed = await context.pushNamed<bool>('memberInfo', pathParameters: {'memberId': '$childId'});
                if (changed == true && mounted) await _reload();
              },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  MemberAvatar(photoUrl: Config.getFullImageUrl(child.avatarUrl ?? child.avatar), size: 48),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('NIT ${childDetail?.nit ?? child.nit ?? '-'}', style: TextStyle(color: Config.textSecondary)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                grandchildren.isEmpty
                    ? 'Belum ada cucu dari cabang ini.'
                    : 'Cucu: ${grandchildren.map((item) => item.fullName).join(', ')}',
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Text(text, textAlign: TextAlign.center),
    );
  }

  Widget _buildDeleteMemberButton(MemberDetailProvider detail) {
    final hasStructure = detail.marriages.isNotEmpty || detail.directChildren.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: hasStructure ? null : () => _confirmDeleteMember(detail.member!),
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

  Future<void> _showEditMarriageDialog(UserData member, FamilyTreeMarriage marriage) async {
    final spouse = marriage.spouse;
    final changed = await showFamilyEditDialog(
      context: context,
      mode: FamilyEditMode.spouse,
      initialData: UserData(fullName: spouse?.fullName, address: spouse?.address, birthYear: spouse?.birthYear),
      memberId: member.userId!,
      marriageId: marriage.marriageId,
    );
    if (changed == true && mounted) {
      await context.read<TreeProvider>().refreshCurrentTree();
      await _reload();
    }
  }

  Future<void> _confirmDeleteMarriage(UserData member, FamilyTreeMarriage marriage) async {
    if (marriage.children.isNotEmpty) {
      _showError('Pernikahan masih mempunyai anak. Pindahkan atau hapus anak terlebih dahulu.');
      return;
    }
    final confirmed = await _confirm(
      title: 'Hapus pasangan?',
      message: 'Data pasangan ${marriage.spouse?.fullName ?? ''} akan dihapus dari silsilah.',
    );
    if (!confirmed || !mounted) return;
    final provider = context.read<UserProvider>();
    final success = await provider.deleteMarriage(marriageId: marriage.marriageId, memberId: member.userId!);
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
      message: 'Data ${member.fullName ?? 'anggota ini'} akan dihapus. Tindakan ini tidak dapat dibatalkan.',
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

  Future<bool> _confirm({required String title, required String message}) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.red));
  }
}
