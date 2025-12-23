import 'package:family_tree_app/components/family_info_card.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
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
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Data user tidak ditemukan"),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text("Login Ulang"),
                  ),
                ],
              ),
            );
          }

          // Convert Data to UserData
          final userData = UserData(
            userId: user.userId,
            familyTreeId: user.familyTreeId,
            fullName: user.fullName,
            address: user.address,
            birthYear: user.birthYear?.toString(),
            avatar: user.avatar,
          );

          return SingleChildScrollView(
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
                    Container(
                      height: 180,
                      color: Colors.black.withValues(alpha: 0.2),
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
                        "Selamat Datang, ${user.fullName}!",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: Config.semiBold,
                          color: Config.textHead,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FamilyInfoCard(user: userData),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOutlinedButton(
                              text: 'Tambah Anggota Baru',
                              onPressed: () => context.pushNamed(
                                'addFamilyMember',
                                extra: user.userId, // Pass userId as parentId
                              ),
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
          );
        },
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
