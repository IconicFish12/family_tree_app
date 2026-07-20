import 'package:family_tree_app/components/family_info_card.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

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
        backgroundColor: Config.primary,
        elevation: 0,
        title: Text(
          'Silsilah Keluarga',
          style: TextStyle(
            color: Config.white,
            fontSize: 20,
            fontWeight: Config.semiBold,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Data user tidak ditemukan.'),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text('Login Ulang'),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      height: 220,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(24),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset(
                        'assets/images/family_logo.png',
                        width: double.infinity,
                        height: 220,
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
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang, ${user.fullName ?? 'Keluarga'}!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Config.textHead,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelola dan lihat informasi silsilah keluarga Anda di sini.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Config.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 24),
                      FamilyInfoCard(user: user),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: _buildOutlinedButton(
                          text: 'Tambah Anggota Baru',
                          onPressed: () => context.pushNamed(
                            'addFamilyMember',
                            extra: user.userId,
                          ),
                        ),
                      ),
                      const SizedBox(height: 35),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        readOnly: true,
        onTap: () => context.goNamed('familySearch'),
        decoration: InputDecoration(
          hintText: 'Cari berdasarkan nama, nik atau hal lainnya..',
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          suffixIcon: Icon(Icons.search, color: Config.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Config.primary,
        backgroundColor: Config.primary.withValues(alpha: 0.05),
        side: BorderSide(color: Config.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }
}
