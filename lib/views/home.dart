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
        backgroundColor: Color(0xFF559260),
        elevation: 0,
        title: Text(
          'Silsilah Keluarga',
          style: TextStyle(color: Config.white, fontSize: 20, fontWeight: Config.semiBold),
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
                  ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Login Ulang')),
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
                      decoration: const BoxDecoration(borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
                      clipBehavior: Clip.antiAlias,
                      child: Image.asset('assets/images/family_logo.png', fit: BoxFit.cover),
                    ),
                    Positioned(bottom: -25, left: 20, right: 20, child: _buildSearchBar()),
                  ],
                ),
                const SizedBox(height: 50),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang, ${user.fullName ?? 'Keluarga'}',
                        style: TextStyle(fontSize: 22, fontWeight: Config.semiBold, color: Config.textHead),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kelola dan lihat informasi silsilah keluarga Anda di sini.',
                        style: TextStyle(fontSize: 14, color: Config.textSecondary),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _buildOutlinedButton(
                              text: 'Tambah Keluarga/Anak Baru',
                              onPressed: () => _showAddMemberOptions(user.userId),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: user.userId == null
                              ? null
                              : () => context.pushNamed('memberInfo', pathParameters: {'memberId': user.userId.toString()}),
                          icon: const Icon(Icons.manage_accounts_outlined),
                          label: const Text('Edit atau Hapus Pasangan Saya'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Config.primary,
                            side: BorderSide(color: Config.primary, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      FamilyInfoCard(user: user),
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

  Future<void> _showAddMemberOptions(int? memberId) async {
    if (memberId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Data diri belum lengkap. Silakan muat ulang.')));
      return;
    }

    final choice = await showModalBottomSheet<_AddMemberChoice>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Siapa yang ingin ditambahkan?',
                style: TextStyle(color: Config.textHead, fontSize: 20, fontWeight: Config.semiBold),
              ),
              const SizedBox(height: 6),
              Text('Pilih salah satu sesuai hubungan keluarga.', style: TextStyle(color: Config.textSecondary)),
              const SizedBox(height: 16),
              _buildChoiceTile(
                icon: Icons.favorite_outline,
                title: 'Tambah Pasangan',
                subtitle: 'Tambahkan data suami atau istri.',
                onTap: () => Navigator.of(sheetContext).pop(_AddMemberChoice.spouse),
              ),
              const SizedBox(height: 10),
              _buildChoiceTile(
                icon: Icons.child_care,
                title: 'Tambah Anak',
                subtitle: 'Pilih pasangan asal anak dan buat NIT otomatis.',
                onTap: () => Navigator.of(sheetContext).pop(_AddMemberChoice.child),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted || choice == null) return;
    if (choice == _AddMemberChoice.spouse) {
      await context.pushNamed('addFamily', queryParameters: {'memberId': memberId.toString()});
      return;
    }
    await context.pushNamed('addFamilyMember', queryParameters: {'parentId': memberId.toString()});
  }

  Widget _buildChoiceTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Config.primary.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Config.primary.withValues(alpha: 0.14),
          child: Icon(icon, color: Config.primaryDark),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Config.textHead.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        readOnly: true,
        onTap: () => context.goNamed('familySearch'),
        decoration: InputDecoration(
          hintText: 'Cari anggota keluarga...',
          hintStyle: TextStyle(color: Config.textSecondary.withValues(alpha: 0.7), fontSize: 14),
          suffixIcon: Icon(Icons.search, color: Config.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
      ),
    );
  }

  Widget _buildOutlinedButton({required String text, required VoidCallback onPressed}) {
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
        style: TextStyle(fontSize: 14, fontWeight: Config.semiBold),
      ),
    );
  }
}

enum _AddMemberChoice { spouse, child }
