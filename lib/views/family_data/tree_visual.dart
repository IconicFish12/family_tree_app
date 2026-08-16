import 'package:family_tree_app/components/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:graphview/GraphView.dart';
import 'package:family_tree_app/config/config.dart';

class TreeVisualPage extends StatefulWidget {
  const TreeVisualPage({super.key});

  @override
  State<TreeVisualPage> createState() => _TreeVisualPageState();
}

class _TreeVisualPageState extends State<TreeVisualPage> {
  final Graph graph = Graph();
  late BuchheimWalkerConfiguration builder;

  @override
  void initState() {
    super.initState();
    // Generasi 1
    final nodeSuherman = Node.Id("Bpk Hj. Suherman");
    final nodeSuliani = Node.Id("Ibu Hj. Suliani");

    // Generasi 2 (Anak Suherman & Suliani)
    final nodeAndre = Node.Id("Bpk Hj. Andre");
    final nodeAsep = Node.Id("Bpk Hj. Asep");
    final nodeBudi = Node.Id("Bpk Hj. Budi");

    // Generasi 3 (Anak Asep)
    final nodeSiti = Node.Id("Ibu Siti Astrini");
    final nodeAli = Node.Id("Ibnu Ali Mulawarman");
    final nodeRaka = Node.Id("Raka Sudrajat");

    final marriageNodeSuherman = Node.Id("Pernikahan Suherman-Suliani");

    graph.addEdge(marriageNodeSuherman, nodeSuherman);
    graph.addEdge(marriageNodeSuherman, nodeSuliani);
    graph.addEdge(marriageNodeSuherman, nodeAndre);
    graph.addEdge(marriageNodeSuherman, nodeAsep);
    graph.addEdge(marriageNodeSuherman, nodeBudi);
    graph.addEdge(nodeAsep, nodeSiti);
    graph.addEdge(nodeAsep, nodeAli);
    graph.addEdge(nodeAsep, nodeRaka);

    builder = BuchheimWalkerConfiguration()
      ..siblingSeparation =
          (50) // Jarak antar saudara
      ..levelSeparation =
          (80) // Jarak antar generasi
      ..subtreeSeparation =
          (50) // Jarak antar sub-pohon
      ..orientation = (BuchheimWalkerConfiguration.ORIENTATION_TOP_BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 0,
        leading: CustomBackButton(
          color: Config.textHead,
          onPressed: () => context.pop(),
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
          preferredSize: const Size.fromHeight(50.0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12.0),
            alignment: Alignment.center,
            child: Text(
              "Pohon Keluarga Bapak Hj. Suherman",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: Config.medium,
                color: Config.textSecondary,
              ),
            ),
          ),
        ),
      ),
      body:
          InteractiveViewer(
            minScale: 0.1,
            maxScale: 2.0,
            child: GraphView.builder(
              graph: graph,
              algorithm: BuchheimWalkerAlgorithm(
                builder,
                TreeEdgeRenderer(builder),
              ),
              paint: Paint()
                ..color = Config.textSecondary.withOpacity(0.5)
                ..strokeWidth = 2
                ..style = PaintingStyle.stroke,
              builder: (Node node) {
                String nodeId = node.key!.value as String;
                if (nodeId.startsWith("Pernikahan")) {
                  return Container();
                }
                return _buildNodeWidget(nodeId);
              },
            ),
          ),
    );
  }

  Widget _buildNodeWidget(String name) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Config.textHead.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Config.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Icon(
              Icons.person,
              size: 50,
              color: Config.textSecondary.withOpacity(0.5),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            decoration: const BoxDecoration(
              color: Config.primary,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.0),
                bottomRight: Radius.circular(12.0),
              ),
            ),
            child: Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Config.white,
                  fontWeight: Config.semiBold,
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
