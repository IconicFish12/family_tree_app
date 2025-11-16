import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/components/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:family_tree_app/config/config.dart';

class FamilyInfoPage extends StatefulWidget {
  const FamilyInfoPage({super.key});

  @override
  State<FamilyInfoPage> createState() => _FamilyInfoPageState();
}

class _FamilyInfoPageState extends State<FamilyInfoPage> {

  // --- DATA DUMMY (Akan dipecah) ---
  final Map<String, String> kepalaKeluarga = {
    "name": "Topan Namas",
    "role": "Kepala Keluarga",
  };
  final Map<String, String> pasangan = {
    "name": "Sinta Suke",
    "role": "Ibu Rumah Tangga",
  };
  final List<Map<String, String>> anakAnak = [
    {"name": "Tomas Alfa Edisound", "role": "Anak Ke 1"},
    {"name": "Nana Donal", "role": "Anak Ke 2"},
    // Tambahkan anak lain di sini...
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- Latar Belakang dari Config ---
      backgroundColor: Config.background,
      // --- AppBar dari Config ---
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 1.0,
        leading: CustomBackButton(
          color: Config.textHead,
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(
          "Keluarga Utama",
          style: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        // Hapus ikon aksi yang tidak perlu
        actions: [],
      ),
      // --- BODY BARU (Bukan hanya ListView) ---
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. KARTU INFORMASI UTAMA KELUARGA ===
            _buildFamilyHeaderCard(kepalaKeluarga, pasangan),
            const SizedBox(height: 24),

            // === 2. JUDUL UNTUK DAFTAR ANAK ===
            Text(
              'Anak-Anak (${anakAnak.length})',
              style: TextStyle(
                color: Config.textHead,
                fontSize: 18,
                fontWeight: Config.semiBold,
              ),
            ),
            const SizedBox(height: 12),

            // === 3. DAFTAR ANAK ===
            // Menggunakan Column karena sudah di dalam SingleChildScrollView
            Column(
              children: anakAnak.map((member) {
                return _buildMemberCard(
                  name: member['name']!,
                  role: member['role']!,
                  onTap: () {
                    // Aksi saat card anggota (anak) di-tap
                    context.pushNamed('memberInfo');
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      // --- Floating Action Button dari Config ---
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('treeVisual'),
        backgroundColor: Config.primary,
        tooltip: 'Lihat Pohon Keluarga',
        child: const Icon(Icons.account_tree_outlined, color: Config.white),
      ),
    );
  }

  // --- WIDGET BARU: Kartu Info Utama Keluarga ---
  Widget _buildFamilyHeaderCard(
    Map<String, String> head,
    Map<String, String> spouse,
  ) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Config.textHead.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMemberTile(
            name: head['name']!,
            role: head['role']!,
            emoji: '👨', // Ganti dengan foto jika ada
            onTap: () => context.pushNamed('memberInfo'), // Ke info Kepala
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Config.background, height: 1),
          ),
          _buildMemberTile(
            name: spouse['name']!,
            role: spouse['role']!,
            emoji: '👩', // Ganti dengan foto jika ada
            onTap: () => context.pushNamed('memberInfo'), // Ke info Pasangan
          ),
        ],
      ),
    );
  }

  // --- WIDGET REFAKTOR: Card Anggota (Anak) ---
  Widget _buildMemberCard({
    required String name,
    required String role,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Config.textHead.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: _buildMemberTile(
        name: name,
        role: role,
        emoji: '👤',
        onTap: onTap,
      ),
    );
  }

  // --- WIDGET HELPER: Tile Anggota (Bisa dipakai di Card Header & Anak) ---
  Widget _buildMemberTile({
    required String name,
    required String role,
    required String emoji,
    VoidCallback? onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12.0),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // --- Avatar (Menggunakan Komponen) ---
            MemberAvatar(emoji: emoji, size: 60, borderRadius: 8.0),
            const SizedBox(width: 16),
            // --- Info Teks (Menggunakan Config) ---
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontWeight: Config.semiBold,
                      fontSize: 16,
                      color: Config.textHead,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: TextStyle(fontSize: 14, color: Config.textSecondary),
                  ),
                ],
              ),
            ),
            // --- Ikon Panah (Menggunakan Config) ---
            Icon(
              Icons.chevron_right,
              color: Config.textSecondary.withOpacity(0.5),
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}