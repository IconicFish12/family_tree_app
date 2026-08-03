import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/models/marriage_role_policy.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';

class TreeVisualPage extends StatefulWidget {
  const TreeVisualPage({super.key});

  @override
  State<TreeVisualPage> createState() => _TreeVisualPageState();
}

class _TreeVisualPageState extends State<TreeVisualPage> {
  TreeProvider? _treeProvider;
  bool _didRequestInitialLoad = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _treeProvider ??= context.read<TreeProvider>();
    if (!_didRequestInitialLoad) {
      _didRequestInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TreeProvider>().initialize();
      });
    }
  }

  void _restorePreviousTreeOrClose() {
    final restored = context.read<TreeProvider>().restorePreviousTree();
    if (!restored) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TreeProvider>();
    final currentRoot = provider.currentRoot;
    final title = currentRoot?.fullName ?? 'Pohon Keluarga';

    return PopScope(
      canPop: !provider.canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && provider.canGoBack) {
          _restorePreviousTreeOrClose();
        }
      },
      child: Scaffold(
        backgroundColor: Config.background,
        appBar: AppBar(
          backgroundColor: Color(0xFF559260),
          elevation: 0,
          leading: CustomBackButton(
            color: Config.white,
            onPressed: _restorePreviousTreeOrClose,
          ),
          title: Text(
            'Pohon Keluarga',
            style: TextStyle(
              color: Config.white,
              fontWeight: Config.semiBold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(92),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: Config.semiBold,
                      color: Config.white,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Maksimal sampai 3 tingkat. ZOOM OUT atau REFRESH ketika tidak melihat bagan nya',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Config.white),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(child: _buildBody(provider)),
      ),
    );
  }

  Widget _buildBody(TreeProvider provider) {
    if (provider.state == TreeViewState.loading ||
        provider.state == TreeViewState.initial) {
      return Center(
        key: const ValueKey('tree-loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Config.primary),
            const SizedBox(height: 16),
            Text(
              'Memuat bagan silsilah keluarga...',
              style: TextStyle(color: Config.textSecondary),
            ),
          ],
        ),
      );
    }

    if (provider.state == TreeViewState.error) {
      return Center(
        key: const ValueKey('tree-error'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.account_tree_outlined,
                size: 56,
                color: Config.textSecondary.withValues(alpha: 0.7),
              ),
              const SizedBox(height: 16),
              Text(
                'Bagan keluarga belum bisa dimuat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: Config.semiBold,
                  color: Config.textHead,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? 'Terjadi kesalahan saat memuat bagan.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Config.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: provider.refreshCurrentTree,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final currentRoot = provider.currentRoot;
    if (currentRoot == null) {
      return Center(
        key: const ValueKey('tree-empty'),
        child: Text(
          'Data silsilah belum tersedia.',
          style: TextStyle(color: Config.textSecondary),
        ),
      );
    }

    final graphData = _buildGraphData(provider, currentRoot);
    final algorithm = BuchheimWalkerAlgorithm(
      graphData.configuration,
      TreeEdgeRenderer(graphData.configuration),
    );

    return Column(
      key: ValueKey('tree-${currentRoot.userId}-${currentRoot.familyTreeId}'),
      children: [
        if (provider.canGoBack)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _restorePreviousTreeOrClose,
                icon: const Icon(Icons.arrow_back),
                label: const Text('Generasi keluarga sebelumnya'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Config.primary,
                  side: const BorderSide(color: Config.primary),
                ),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
            child: InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(240),
              constrained: false,
              minScale: 0.2,
              maxScale: 2.2,
              child: ExcludeSemantics(
                child: GraphView(
                  key: ValueKey(
                    'graph-${currentRoot.userId}-${currentRoot.familyTreeId}',
                  ),
                  graph: graphData.graph,
                  algorithm: algorithm,
                  animated: false,
                  builder: (graphNode) {
                    final nodeData = graphData.nodes[graphNode.key?.value];
                    if (nodeData == null) {
                      return const SizedBox.shrink();
                    }
                    return _buildGraphNode(provider, nodeData);
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  _TreeGraphData _buildGraphData(TreeProvider provider, FamilyTreeNode root) {
    final graph = Graph()..isTree = true;
    final nodes = <String, _TreeGraphNodeData>{};
    final configuration = BuchheimWalkerConfiguration()
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM
      ..siblingSeparation = 48
      ..levelSeparation = 90
      ..subtreeSeparation = 72
      ..useCurvedConnections = false;

    void ensureFamilyNode(FamilyTreeNode node, {required bool isCurrentRoot}) {
      final familyId = _familyNodeId(node);
      nodes[familyId] ??= _TreeGraphNodeData.family(
        id: familyId,
        familyNode: node,
        isCurrentRoot: isCurrentRoot,
        canOpenSubtree: provider.canOpenSubtree(node),
      );

      if (!graph.contains(node: Node.Id(familyId))) {
        graph.addNode(Node.Id(familyId));
      }

      if (provider.relativeLevel(node) >= TreeProvider.visibleLevels) {
        return;
      }

      for (final marriage in node.marriages.where((item) => item.hasChildren)) {
        final branchId = _branchNodeId(node, marriage);
        nodes[branchId] ??= _TreeGraphNodeData.marriageBranch(
          id: branchId,
          familyNode: node,
          marriage: marriage,
        );

        graph.addEdge(
          Node.Id(familyId),
          Node.Id(branchId),
          paint: Paint()
            ..color = const Color(0xFFE1B44A)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke,
        );

        for (final child in marriage.children) {
          ensureFamilyNode(child, isCurrentRoot: false);
          graph.addEdge(
            Node.Id(branchId),
            Node.Id(_familyNodeId(child)),
            paint: Paint()
              ..color = Config.primaryDark
              ..strokeWidth = 1.8
              ..style = PaintingStyle.stroke,
          );
        }
      }

      if (node.adoptedChildren.isNotEmpty) {
        final branchId = _adoptionBranchNodeId(node);
        nodes[branchId] ??= _TreeGraphNodeData.adoptionBranch(
          id: branchId,
          familyNode: node,
        );

        graph.addEdge(
          Node.Id(familyId),
          Node.Id(branchId),
          paint: Paint()
            ..color = Config.primary.withValues(alpha: 0.75)
            ..strokeWidth = 1.8
            ..style = PaintingStyle.stroke,
        );

        for (final child in node.adoptedChildren) {
          ensureFamilyNode(child, isCurrentRoot: false);
          graph.addEdge(
            Node.Id(branchId),
            Node.Id(_familyNodeId(child)),
            paint: Paint()
              ..color = Config.primaryDark
              ..strokeWidth = 1.8
              ..style = PaintingStyle.stroke,
          );
        }
      }
    }

    ensureFamilyNode(root, isCurrentRoot: true);
    return _TreeGraphData(
      graph: graph,
      nodes: nodes,
      configuration: configuration,
    );
  }

  Widget _buildGraphNode(TreeProvider provider, _TreeGraphNodeData nodeData) {
    switch (nodeData.type) {
      case _TreeGraphNodeType.family:
        final node = nodeData.familyNode!;
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Config.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: nodeData.isCurrentRoot
                  ? Config.primary.withValues(alpha: 0.24)
                  : Config.textSecondary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Config.textHead.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPersonCard(
                    badge: nodeData.isCurrentRoot
                        ? 'Root Keluarga'
                        : node.relationshipType?.label ?? 'Anggota Keluarga',
                    title: node.fullName,
                    meta: [
                      'NIT: ${node.nit?.trim().isNotEmpty == true ? node.nit : '-'}',
                      (node.gender?.label ?? 'Jenis kelamin: Belum diketahui'),
                      if (node.birthYear != null && node.birthYear!.isNotEmpty)
                        'Lahir ${node.birthYear}',
                      if (node.address != null && node.address!.isNotEmpty)
                        node.address!,
                    ],
                    avatarUrl: Config.getFullImageUrl(
                      node.avatarUrl ?? node.avatar,
                    ),
                    footer: _buildMemberFooter(provider, node, nodeData),
                    role: nodeData.isCurrentRoot
                        ? _PersonCardRole.root
                        : _PersonCardRole.member,
                    statusBadges: _memberStatusBadges(node),
                  ),
                  for (final marriage in node.marriages) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 102, 10, 0),
                      child: Container(
                        width: 24,
                        height: 2,
                        color: const Color(0xFFE1B44A),
                      ),
                    ),
                    _buildPersonCard(
                      badge: 'Pasangan ${marriage.marriageOrder}',
                      title:
                          marriage.spouse?.fullName ??
                          'Pasangan belum diketahui',
                      meta: [
                        'NIT: ${marriage.spouse?.nit?.trim().isNotEmpty == true ? marriage.spouse!.nit : '-'}',
                        'Jenis kelamin: ${marriage.spouse?.gender?.label ?? 'Belum diketahui'}',
                        if (marriage.spouse?.birthYear != null &&
                            marriage.spouse!.birthYear!.isNotEmpty)
                          'Lahir ${marriage.spouse!.birthYear}',
                        if (marriage.spouse?.address != null &&
                            marriage.spouse!.address!.isNotEmpty)
                          marriage.spouse!.address!,
                      ],
                      avatarUrl: Config.getFullImageUrl(
                        marriage.spouse?.avatarUrl ?? marriage.spouse?.avatar,
                      ),
                      footer: Container(),
                      role: _PersonCardRole.spouse,
                      statusBadges: _spouseStatusBadges(marriage),
                      width: 210,
                    ),
                  ],
                ],
              ),
              if (!nodeData.canOpenSubtree && node.marriages.length > 1) ...[
                const SizedBox(height: 10),
                _buildLegendText(
                  'Setiap pasangan disusun sejajar. Cabang anak di bawah label pasangan masing-masing.',
                ),
              ],
            ],
          ),
        );
      case _TreeGraphNodeType.marriageBranch:
        final marriage = nodeData.marriage!;
        final spouseName = marriage.spouse?.fullName ?? 'pasangan ini';
        final childCount = marriage.children.length;
        return Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF7E5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE1B44A)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE1B44A).withValues(alpha: 0.14),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEDBE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Cabang Pasangan ${marriage.marriageOrder}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A6200),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pernikahan $spouseName',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF7B5800),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                childCount == 1
                    ? 'berisi 1 anak'
                    : 'berisi $childCount anak',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: Color(0xFF9B7A28),
                ),
              ),
            ],
          ),
        );
      case _TreeGraphNodeType.adoptionBranch:
        final parent = nodeData.familyNode!;
        final childCount = parent.adoptedChildren.length;
        return Container(
          constraints: const BoxConstraints(minWidth: 180, maxWidth: 210),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Config.secondarySoft,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Config.primary.withValues(alpha: 0.55)),
            boxShadow: [
              BoxShadow(
                color: Config.primary.withValues(alpha: 0.10),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Config.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Cabang Anak Adopsi',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Config.primaryDark,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Adopsi langsung dari ${parent.fullName}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Config.primaryDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                childCount == 1
                    ? 'Cabang ini berisi 1 anak'
                    : 'Cabang ini berisi $childCount anak',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: Config.textSecondary),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMemberFooter(
    TreeProvider provider,
    FamilyTreeNode node,
    _TreeGraphNodeData nodeData,
  ) {
    if (nodeData.canOpenSubtree) {
      return _buildOpenButton(() => provider.openSubtree(node));
    }

    return Container();
  }

  List<_PersonStatusBadge> _memberStatusBadges(FamilyTreeNode node) {
    final badges = <_PersonStatusBadge>[];
    final policy = MarriageRolePolicy.fromMarriages(node.marriages);

    switch (policy.state) {
      case MarriageRolePolicyState.conflicting:
        badges.add(const _PersonStatusBadge.conflict());
        break;
      case MarriageRolePolicyState.legacyUnclassified:
        badges.add(const _PersonStatusBadge.unclassified());
        break;
      case MarriageRolePolicyState.lockedHusband:
      case MarriageRolePolicyState.lockedWife:
        badges.add(_PersonStatusBadge.role(policy.lockedRole!.label));
        if (node.marriages.any(
          (marriage) =>
              marriage.isRoleClassified &&
              marriage.familyHeadPosition == FamilyHeadPosition.member,
        )) {
          badges.add(const _PersonStatusBadge.familyHead());
        }
        break;
      case MarriageRolePolicyState.unset:
        break;
    }

    return badges;
  }

  List<_PersonStatusBadge> _spouseStatusBadges(FamilyTreeMarriage marriage) {
    final badges = <_PersonStatusBadge>[];
    final policy = MarriageRolePolicy.fromMarriages([marriage]);

    switch (policy.state) {
      case MarriageRolePolicyState.conflicting:
        badges.add(const _PersonStatusBadge.conflict());
        break;
      case MarriageRolePolicyState.legacyUnclassified:
        badges.add(const _PersonStatusBadge.unclassified());
        break;
      case MarriageRolePolicyState.lockedHusband:
      case MarriageRolePolicyState.lockedWife:
        badges.add(_PersonStatusBadge.role(marriage.spouseRole!.label));
        if (marriage.familyHeadPosition == FamilyHeadPosition.spouse) {
          badges.add(const _PersonStatusBadge.familyHead());
        }
        break;
      case MarriageRolePolicyState.unset:
        break;
    }

    return badges;
  }

  Widget _buildPersonCard({
    required String badge,
    required String title,
    required List<String> meta,
    required String? avatarUrl,
    required Widget footer,
    required _PersonCardRole role,
    List<_PersonStatusBadge> statusBadges = const [],
    double width = 230,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _borderColor(role),
          width: role == _PersonCardRole.root ? 1.5 : 1.1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _badgeBackgroundColor(role),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11.5,
                  color: _badgeTextColor(role),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          if (statusBadges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 6,
              children: statusBadges
                  .map(
                    (status) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: status.backgroundColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        status.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: status.textColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _avatarBackgroundColor(role),
            ),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(
                        _avatarIcon(role),
                        size: 34,
                        color: _badgeTextColor(role),
                      ),
                    )
                  : Icon(
                      _avatarIcon(role),
                      size: 34,
                      color: _badgeTextColor(role),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: Config.semiBold,
              color: Config.textHead,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...meta.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  item,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Config.textSecondary,
                    height: 1.35,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          footer,
        ],
      ),
    );
  }

  Widget _buildLegendText(String text) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Config.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            color: Config.textSecondary,
            fontWeight: Config.medium,
          ),
        ),
      ),
    );
  }

  Widget _buildOpenButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.account_tree_outlined, size: 18),
        label: const Text('Lihat turunan'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10),
          backgroundColor: Config.primaryDark,
          foregroundColor: Config.white,
        ),
      ),
    );
  }

  String _familyNodeId(FamilyTreeNode node) {
    return 'family:${node.userId ?? node.relationId ?? node.familyTreeId}';
  }

  String _branchNodeId(FamilyTreeNode node, FamilyTreeMarriage marriage) {
    return 'branch:${node.userId ?? node.relationId ?? node.familyTreeId}:${marriage.marriageId}:${marriage.marriageOrder}';
  }

  String _adoptionBranchNodeId(FamilyTreeNode node) {
    return 'adoption:${node.userId ?? node.relationId ?? node.familyTreeId}';
  }

  Color _borderColor(_PersonCardRole role) {
    switch (role) {
      case _PersonCardRole.root:
        return Config.primary.withValues(alpha: 0.30);
      case _PersonCardRole.member:
        return Config.textSecondary.withValues(alpha: 0.16);
      case _PersonCardRole.spouse:
        return const Color(0xFFE1B44A);
    }
  }

  Color _badgeBackgroundColor(_PersonCardRole role) {
    switch (role) {
      case _PersonCardRole.root:
        return Config.accent.withValues(alpha: 0.16);
      case _PersonCardRole.member:
        return Config.background;
      case _PersonCardRole.spouse:
        return const Color(0xFFFFF4DA);
    }
  }

  Color _badgeTextColor(_PersonCardRole role) {
    switch (role) {
      case _PersonCardRole.root:
        return Config.primaryDark;
      case _PersonCardRole.member:
        return Config.primary;
      case _PersonCardRole.spouse:
        return const Color(0xFF8A6200);
    }
  }

  Color _avatarBackgroundColor(_PersonCardRole role) {
    switch (role) {
      case _PersonCardRole.root:
        return Config.accent.withValues(alpha: 0.12);
      case _PersonCardRole.member:
        return Config.background;
      case _PersonCardRole.spouse:
        return const Color(0xFFFFF7E5);
    }
  }

  IconData _avatarIcon(_PersonCardRole role) {
    switch (role) {
      case _PersonCardRole.root:
      case _PersonCardRole.member:
        return Icons.person;
      case _PersonCardRole.spouse:
        return Icons.favorite_outline;
    }
  }
}

enum _PersonCardRole { root, member, spouse }

enum _TreeGraphNodeType { family, marriageBranch, adoptionBranch }

class _TreeGraphNodeData {
  final String id;
  final _TreeGraphNodeType type;
  final FamilyTreeNode? familyNode;
  final FamilyTreeMarriage? marriage;
  final bool isCurrentRoot;
  final bool canOpenSubtree;

  const _TreeGraphNodeData.family({
    required this.id,
    required this.familyNode,
    required this.isCurrentRoot,
    required this.canOpenSubtree,
  }) : type = _TreeGraphNodeType.family,
       marriage = null;

  const _TreeGraphNodeData.marriageBranch({
    required this.id,
    required this.familyNode,
    required this.marriage,
  }) : type = _TreeGraphNodeType.marriageBranch,
       isCurrentRoot = false,
       canOpenSubtree = false;

  const _TreeGraphNodeData.adoptionBranch({
    required this.id,
    required this.familyNode,
  }) : type = _TreeGraphNodeType.adoptionBranch,
       marriage = null,
       isCurrentRoot = false,
       canOpenSubtree = false;
}

class _PersonStatusBadge {
  final String label;
  final Color backgroundColor;
  final Color textColor;

  const _PersonStatusBadge._({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  factory _PersonStatusBadge.role(String label) {
    return _PersonStatusBadge._(
      label: label,
      backgroundColor: Config.background,
      textColor: Config.primaryDark,
    );
  }

  const _PersonStatusBadge.familyHead()
    : this._(
        label: 'Kepala Keluarga',
        backgroundColor: Config.secondarySoft,
        textColor: Config.primaryDark,
      );

  const _PersonStatusBadge.unclassified()
    : this._(
        label: 'Belum diklasifikasikan',
        backgroundColor: const Color(0xFFFFF4DA),
        textColor: const Color(0xFF8A6200),
      );

  const _PersonStatusBadge.conflict()
    : this._(
        label: 'Konflik peran',
        backgroundColor: const Color(0xFFFFE5E5),
        textColor: const Color(0xFFB42318),
      );
}

class _TreeGraphData {
  final Graph graph;
  final Map<String, _TreeGraphNodeData> nodes;
  final BuchheimWalkerConfiguration configuration;

  const _TreeGraphData({
    required this.graph,
    required this.nodes,
    required this.configuration,
  });
}
