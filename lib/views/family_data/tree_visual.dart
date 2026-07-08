import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:provider/provider.dart';

class TreeVisualPage extends StatefulWidget {
  final String? initialFamilyTreeId;
  final String? initialTitle;

  const TreeVisualPage({
    super.key,
    this.initialFamilyTreeId,
    this.initialTitle,
  });

  @override
  State<TreeVisualPage> createState() => _TreeVisualPageState();
}

class _TreeVisualPageState extends State<TreeVisualPage> {
  late final BuchheimWalkerConfiguration _builder;
  TreeProvider? _treeProvider;

  @override
  void initState() {
    super.initState();
    _builder = BuchheimWalkerConfiguration()
      ..siblingSeparation = 48
      ..levelSeparation = 90
      ..subtreeSeparation = 56
      ..orientation = BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _treeProvider ??= context.read<TreeProvider>();
    if (_treeProvider?.state == TreeViewState.initial) {
      final authUser = context.read<AuthProvider>().currentUser;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<TreeProvider>().initialize(
          initialFamilyTreeId: widget.initialFamilyTreeId,
          initialTitle: widget.initialTitle,
          fallbackRootFamilyTreeId: authUser?.familyTreeId,
        );
      });
    }
  }

  @override
  void dispose() {
    _treeProvider?.reset();
    super.dispose();
  }

  void _restorePreviousTreeOrClose() {
    final restored = context.read<TreeProvider>().restorePreviousTree();
    if (!restored) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final title =
        context.select<TreeProvider, String?>(
          (provider) => provider.currentTitle,
        ) ??
        "Pohon Keluarga";
    final canGoBack = context.select<TreeProvider, bool>(
      (provider) => provider.canGoBack,
    );

    return PopScope(
      canPop: !canGoBack,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && canGoBack) {
          _restorePreviousTreeOrClose();
        }
      },
      child: Scaffold(
        backgroundColor: Config.background,
        appBar: AppBar(
          backgroundColor: Config.white,
          elevation: 0,
          leading: CustomBackButton(
            color: Config.textHead,
            onPressed: _restorePreviousTreeOrClose,
          ),
          title: Text(
            "Pohon Keluarga",
            style: TextStyle(
              color: Config.textHead,
              fontWeight: Config.semiBold,
              fontSize: 20,
            ),
          ),
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(72),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: Config.semiBold,
                      color: Config.textHead,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Menampilkan maksimal 2 level per tampilan. Ketuk node bercabang untuk melihat turunan berikutnya.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Config.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _buildBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    final provider = context.watch<TreeProvider>();
    final state = provider.state;

    if (state == TreeViewState.loading || state == TreeViewState.initial) {
      return Center(
        key: const ValueKey('tree-loading'),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Config.primary),
            const SizedBox(height: 16),
            Text(
              "Memuat bagan silsilah...",
              style: TextStyle(color: Config.textSecondary),
            ),
          ],
        ),
      );
    }

    if (state == TreeViewState.error) {
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
                "Bagan belum bisa dimuat",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: Config.semiBold,
                  color: Config.textHead,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                provider.errorMessage ?? "Terjadi kesalahan saat memuat bagan.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Config.textSecondary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: provider.refreshCurrentTree,
                icon: const Icon(Icons.refresh),
                label: const Text("Refresh Data"),
              ),
            ],
          ),
        ),
      );
    }

    final tree = provider.currentTree;
    if (tree == null) {
      return Center(
        key: const ValueKey('tree-empty'),
        child: Text(
          "Data silsilah belum tersedia.",
          style: TextStyle(color: Config.textSecondary),
        ),
      );
    }

    final graphData = _buildGraphData(tree);

    return Column(
      key: ValueKey('tree-${tree.familyTreeId}'),
      children: [
        if (provider.canGoBack)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _restorePreviousTreeOrClose,
                icon: const Icon(Icons.arrow_back),
                label: const Text("Kembali ke subtree sebelumnya"),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Config.primary,
                  side: const BorderSide(color: Config.primary),
                ),
              ),
            ),
          ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: GraphView.builder(
              key: ValueKey('graph-${tree.familyTreeId}'),
              graph: graphData.graph,
              algorithm: BuchheimWalkerAlgorithm(
                _builder,
                TreeEdgeRenderer(_builder),
              ),
              autoZoomToFit: true,
              centerGraph: true,
              paint: Paint()
                ..color = Config.textSecondary.withValues(alpha: 0.45)
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                final nodeId = node.key?.value?.toString() ?? '';
                final treeNode = graphData.nodes[nodeId];
                if (treeNode == null) {
                  return const SizedBox.shrink();
                }
                final isRootNode = nodeId == tree.familyTreeId;
                return _buildNodeWidget(treeNode, isRootNode: isRootNode);
              },
            ),
          ),
        ),
      ],
    );
  }

  _TreeGraphData _buildGraphData(FamilyTreeNode root) {
    final graph = Graph()..isTree = true;
    final nodes = <String, FamilyTreeNode>{};
    final graphNodes = <String, Node>{};

    void addNodeIfMissing(FamilyTreeNode node) {
      nodes[node.familyTreeId] = node;
      graphNodes.putIfAbsent(node.familyTreeId, () {
        final graphNode = Node.Id(node.familyTreeId);
        graph.addNode(graphNode);
        return graphNode;
      });
    }

    addNodeIfMissing(root);

    for (final child in root.children) {
      addNodeIfMissing(child);
      graph.addEdge(
        graphNodes[root.familyTreeId]!,
        graphNodes[child.familyTreeId]!,
      );

      for (final grandChild in child.children) {
        addNodeIfMissing(grandChild);
        graph.addEdge(
          graphNodes[child.familyTreeId]!,
          graphNodes[grandChild.familyTreeId]!,
        );
      }
    }

    return _TreeGraphData(graph: graph, nodes: nodes);
  }

  Widget _buildNodeWidget(FamilyTreeNode node, {required bool isRootNode}) {
    final canOpen = node.canOpenSubtree && !isRootNode;
    final spouseNames = node.spouseNames;
    final hasSpouse = spouseNames.isNotEmpty;
    final accentColor = canOpen ? Config.primaryDark : Config.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canOpen
            ? () => context.read<TreeProvider>().openSubtree(node)
            : null,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 190,
          decoration: BoxDecoration(
            color: Config.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: canOpen
                  ? Config.primaryDark.withValues(alpha: 0.15)
                  : Config.textSecondary.withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: Config.textHead.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: isRootNode
                      ? Config.accent.withValues(alpha: 0.15)
                      : Config.background,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      canOpen ? Icons.account_tree_outlined : Icons.person,
                      size: 34,
                      color: accentColor,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      node.fullName,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.semiBold,
                        color: Config.textHead,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      node.familyTreeId.isEmpty ? "-" : node.familyTreeId,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: Config.medium,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasSpouse) _buildMetaText("Pasangan: $spouseNames"),
                    if (node.birthYear != null && node.birthYear!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildMetaText("Lahir: ${node.birthYear}"),
                      ),
                    if (node.address != null && node.address!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: _buildMetaText(node.address!),
                      ),
                    const SizedBox(height: 10),
                    if (canOpen)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Config.primaryDark,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.touch_app_outlined,
                              size: 16,
                              color: Config.white,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Lihat turunan",
                              style: TextStyle(
                                color: Config.white,
                                fontWeight: Config.medium,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Config.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          "Tidak ada turunan",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Config.textSecondary,
                            fontSize: 12,
                            fontWeight: Config.medium,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetaText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11.5,
        color: Config.textSecondary,
        height: 1.35,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _TreeGraphData {
  final Graph graph;
  final Map<String, FamilyTreeNode> nodes;

  const _TreeGraphData({required this.graph, required this.nodes});
}
