import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
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
          leading: CustomBackButton(color: Config.white, onPressed: _restorePreviousTreeOrClose),
          title: Text(
            'Pohon Keluarga',
            style: TextStyle(color: Config.white, fontWeight: Config.semiBold, fontSize: 20),
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
                    style: TextStyle(fontSize: 16, fontWeight: Config.semiBold, color: Config.white),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tampilan maksimal 3 tingkat. Pasangan berada sejajar dengan anggota keluarga. Cabang anak dipisahkan per pasangan agar lebih mudah dibaca.',
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
    if (provider.state == TreeViewState.loading || provider.state == TreeViewState.initial) {
      return Center(
        key: const ValueKey('tree-loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Config.primary),
            const SizedBox(height: 16),
            Text('Memuat bagan silsilah keluarga...', style: TextStyle(color: Config.textSecondary)),
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
              Icon(Icons.account_tree_outlined, size: 56, color: Config.textSecondary.withValues(alpha: 0.7)),
              const SizedBox(height: 16),
              Text(
                'Bagan keluarga belum bisa dimuat',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: Config.semiBold, color: Config.textHead),
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
        child: Text('Data silsilah belum tersedia.', style: TextStyle(color: Config.textSecondary)),
      );
    }

    final graphData = _buildGraphData(provider, currentRoot);
    final algorithm = BuchheimWalkerAlgorithm(graphData.configuration, TreeEdgeRenderer(graphData.configuration));

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
                label: const Text('Kembali ke cabang sebelumnya'),
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
                  key: ValueKey('graph-${currentRoot.userId}-${currentRoot.familyTreeId}'),
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
        nodes[branchId] ??= _TreeGraphNodeData.branch(id: branchId, familyNode: node, marriage: marriage);

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
    }

    ensureFamilyNode(root, isCurrentRoot: true);
    return _TreeGraphData(graph: graph, nodes: nodes, configuration: configuration);
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
              BoxShadow(color: Config.textHead.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4)),
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
                    badge: nodeData.isCurrentRoot ? 'Akar Keluarga' : 'Anggota Keluarga',
                    title: node.fullName,
                    subtitle: node.familyTreeId.isEmpty ? '-' : node.familyTreeId,
                    meta: [
                      if (node.birthYear != null && node.birthYear!.isNotEmpty) 'Lahir ${node.birthYear}',
                      if (node.address != null && node.address!.isNotEmpty) node.address!,
                    ],
                    avatarUrl: Config.getFullImageUrl(node.avatarUrl ?? node.avatar),
                    footer: _buildMemberFooter(provider, node, nodeData),
                    role: nodeData.isCurrentRoot ? _PersonCardRole.root : _PersonCardRole.member,
                  ),
                  for (final marriage in node.marriages) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 102, 10, 0),
                      child: Container(width: 24, height: 2, color: const Color(0xFFE1B44A)),
                    ),
                    _buildPersonCard(
                      badge: 'Pasangan ${marriage.marriageOrder}',
                      title: marriage.spouse?.fullName ?? 'Pasangan belum diketahui',
                      subtitle: marriage.spouse?.familyTreeId.isNotEmpty == true
                          ? marriage.spouse!.familyTreeId
                          : 'Cabang pasangan',
                      meta: [
                        if (marriage.spouse?.birthYear != null && marriage.spouse!.birthYear!.isNotEmpty)
                          'Lahir ${marriage.spouse!.birthYear}',
                        if (marriage.spouse?.address != null && marriage.spouse!.address!.isNotEmpty)
                          marriage.spouse!.address!,
                      ],
                      avatarUrl: Config.getFullImageUrl(marriage.spouse?.avatarUrl ?? marriage.spouse?.avatar),
                      footer: _buildFooterText(
                        marriage.children.isEmpty
                            ? 'Belum ada anak pada pasangan ini.'
                            : 'Anak pasangan ini berada di cabang bawah.',
                      ),
                      role: _PersonCardRole.spouse,
                      width: 210,
                    ),
                  ],
                ],
              ),
              if (!nodeData.canOpenSubtree && node.marriages.length > 1) ...[
                const SizedBox(height: 10),
                _buildLegendText('Setiap pasangan disusun sejajar. Cabang anak di bawah label pasangan masing-masing.'),
              ],
            ],
          ),
        );
      case _TreeGraphNodeType.branch:
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
              BoxShadow(color: const Color(0xFFE1B44A).withValues(alpha: 0.14), blurRadius: 8, offset: const Offset(0, 3)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFFFFEDBE), borderRadius: BorderRadius.circular(999)),
                child: Text(
                  'Cabang Pasangan ${marriage.marriageOrder}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: Color(0xFF8A6200)),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Anak dari $spouseName',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF7B5800)),
              ),
              const SizedBox(height: 4),
              Text(
                childCount == 1 ? 'Cabang ini berisi 1 anak' : 'Cabang ini berisi $childCount anak',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: Color(0xFF9B7A28)),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildMemberFooter(TreeProvider provider, FamilyTreeNode node, _TreeGraphNodeData nodeData) {
    if (nodeData.canOpenSubtree) {
      return _buildOpenButton(() => provider.openSubtree(node));
    }

    if (node.marriages.isEmpty) {
      return _buildFooterText('Belum ada pasangan atau turunan lagi.');
    }

    return _buildFooterText('Pasangan berada di samping. Turunan keluarga ditampilkan di cabang bawah.');
  }

  Widget _buildPersonCard({
    required String badge,
    required String title,
    required String subtitle,
    required List<String> meta,
    required String? avatarUrl,
    required Widget footer,
    required _PersonCardRole role,
    double width = 230,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _borderColor(role), width: role == _PersonCardRole.root ? 1.5 : 1.1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: _badgeBackgroundColor(role), borderRadius: BorderRadius.circular(999)),
              child: Text(
                badge,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: _badgeTextColor(role), fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(shape: BoxShape.circle, color: _avatarBackgroundColor(role)),
            child: ClipOval(
              child: avatarUrl != null && avatarUrl.isNotEmpty
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Icon(_avatarIcon(role), size: 34, color: _badgeTextColor(role)),
                    )
                  : Icon(_avatarIcon(role), size: 34, color: _badgeTextColor(role)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, fontWeight: Config.semiBold, color: Config.textHead),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: _badgeTextColor(role), fontWeight: Config.medium),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...meta.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  item,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: Config.textSecondary, height: 1.35),
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
        decoration: BoxDecoration(color: Config.background, borderRadius: BorderRadius.circular(12)),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11.5, color: Config.textSecondary, fontWeight: Config.medium),
        ),
      ),
    );
  }

  Widget _buildFooterText(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(color: Config.background, borderRadius: BorderRadius.circular(10)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 12, color: Config.textSecondary, fontWeight: Config.medium),
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
    return 'family:${node.userId ?? node.familyTreeId}';
  }

  String _branchNodeId(FamilyTreeNode node, FamilyTreeMarriage marriage) {
    return 'branch:${node.userId ?? node.familyTreeId}:${marriage.marriageId}:${marriage.marriageOrder}';
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

enum _TreeGraphNodeType { family, branch }

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

  const _TreeGraphNodeData.branch({required this.id, required this.familyNode, required this.marriage})
    : type = _TreeGraphNodeType.branch,
      isCurrentRoot = false,
      canOpenSubtree = false;
}

class _TreeGraphData {
  final Graph graph;
  final Map<String, _TreeGraphNodeData> nodes;
  final BuchheimWalkerConfiguration configuration;

  const _TreeGraphData({required this.graph, required this.nodes, required this.configuration});
}
