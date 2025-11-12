import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

class TreeVisualPage extends StatefulWidget {
  const TreeVisualPage({super.key});

  @override
  State<TreeVisualPage> createState() => _TreeVisualPageState();
}

class _TreeVisualPageState extends State<TreeVisualPage> {
  final Graph graph = Graph();
  late BuchheimWalkerConfiguration builder;
  final graphController = GraphViewController();

  @override
  void initState() {
    super.initState();

    // --- MEMBUAT NODE (ANGGOTA KELUARGA) ---
    // (Data ini meniru struktur dari screenshot figma Anda)

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

    // --- MENGHUBUNGKAN NODE (GARIS KELUARGA) ---
    graph.addEdge(nodeSuherman, nodeAndre);
    graph.addEdge(nodeSuherman, nodeAsep);
    graph.addEdge(nodeSuherman, nodeBudi);
    // (di graphview, edge hanya bisa 1-ke-1, jadi kita hubungkan dari satu parent)
    // (Untuk pasangan suami istri, kita bisa buat node 'pernikahan' atau
    //  kita asumsikan 'Suherman' sebagai node 'root' keluarga)

    // Kita buat node 'Pasangan' Suherman & Suliani sebagai 'root'
    // (Ini cara lain, tapi untuk simpel, kita ikuti alur figma)
    graph.addEdge(nodeSuherman, nodeSuliani); // Anggap ini sebagai 'pasangan'

    // Hubungan Generasi 3
    graph.addEdge(nodeAsep, nodeSiti);
    graph.addEdge(nodeAsep, nodeAli);
    graph.addEdge(nodeAsep, nodeRaka);

    // --- KONFIGURASI LAYOUT ---
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
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Pohon Keluarga",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Judul di dalam body
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: const Text(
              "Pohon Keluarga\nBapak Hj. Suherman",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          // Visualisasi Pohon
          Expanded(
            // === PENINGKATAN: InteractiveViewer ===
            // Ini memungkinkan pengguna untuk zoom dan geser
            child: InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(100.0),
              minScale: 0.1,
              maxScale: 2.0,
              child: GraphView.builder(
                graph: graph,
                algorithm: BuchheimWalkerAlgorithm(
                  builder,
                  TreeEdgeRenderer(builder),
                ),
                paint: Paint()
                  ..color = Colors
                      .grey
                      .shade400 // Warna garis
                  ..strokeWidth = 2
                  ..style = PaintingStyle.stroke,
                builder: (Node node) {
                  // Ini adalah widget untuk setiap node
                  String nodeId = node.key!.value as String;
                  return _buildNodeWidget(nodeId);
                },
                centerGraph: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- PENINGKATAN: Widget Node Kustom ---
  // Ini adalah widget yang menggantikan kotak abu-abu jelek dari Figma
  Widget _buildNodeWidget(String name) {
    return Container(
      width: 150, // Lebar kartu
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // 1. Placeholder Foto
          Container(
            width: double.infinity,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12.0),
                topRight: Radius.circular(12.0),
              ),
            ),
            child: Icon(Icons.person, size: 50, color: Colors.grey[600]),
          ),
          // 2. Nama
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            // Warna hijau dari desain figma
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50), // Mirip Colors.green
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12.0),
                bottomRight: Radius.circular(12.0),
              ),
            ),
            child: Center(
              child: Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
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