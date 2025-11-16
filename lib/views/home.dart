import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/config.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.background,
        elevation: 0,
        title: Text(
          'Silsilah Keluarga',
          style: TextStyle(
            color: Config.textHead,
            fontSize: 20,
            fontWeight: Config.semiBold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('profile'),
            icon: Icon(
              Icons.account_circle_outlined,
              color: Config.textSecondary,
              size: 28,
            ),
            tooltip: "Profile",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 180,
                  child: Image.asset(
                    'assets/images/family_logo.png',
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  bottom: -25,
                  left: 20,
                  right: 20,
                  child: _buildSearchBar(),
                ),
              ],
            ),
            const SizedBox(height: 45),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, Deva!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: Config.semiBold,
                      color: Config.textHead,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildFamilyInfoCard(
                    context: context,
                    title: 'Keluarga Utama',
                    memberCount: '15 Anggota',
                    description: 'Keluarga Besar Sujadmiko',
                    imageUrl: 'assets/images/family_logo.png',
                    onTap: () => context.goNamed('familyList'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildOutlinedButton(
                          text: 'Tambah Anggota Baru',
                          onPressed: () => context.pushNamed('addFamilyMember'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildElevatedButton(
                          text: 'Lihat List Keluarga',
                          onPressed: () => context.pushNamed('familyList'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET HELPER ---

  /// Widget untuk Search Bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Config.textHead.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Cari berdasarkan nama, nik atau hal lainnya..',
          hintStyle: TextStyle(
            color: Config.textSecondary.withValues(alpha: 0.7),
            fontSize: 14,
          ),
          suffixIcon: Icon(Icons.search, color: Config.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 15,
            horizontal: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildFamilyInfoCard({
    required BuildContext context,
    required String title,
    required String memberCount,
    required String description,
    required String imageUrl,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Config.textHead.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Gambar
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imageUrl),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(color: Colors.black.withValues(alpha: 0.2)),
              ),
              Container(
                width: double.infinity,
                color: Config.primary,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: Config.semiBold,
                        color: Config.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      memberCount,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.regular,
                        color: Config.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.regular,
                        color: Config.white.withValues(alpha: 0.9),
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

  /// Widget untuk OutlinedButton
  Widget _buildOutlinedButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Config.primary,
        side: BorderSide(color: Config.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, fontWeight: Config.semiBold),
      ),
    );
  }

  /// Widget untuk ElevatedButton
  Widget _buildElevatedButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Config.primary,
        foregroundColor: Config.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Config.white,
          fontSize: 14,
          fontWeight: Config.semiBold,
        ),
      ),
    );
  }
}
