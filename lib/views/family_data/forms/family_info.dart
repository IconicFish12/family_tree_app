import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:family_tree_app/config/config.dart';

class FamilyInfoPage extends StatelessWidget {
  // Data yang diterima dari navigasi
  final String headName;
  final String? spouseName;
  final List<ChildMember> children;
  final int? parentId; // ID Database (untuk tambah anak)

  const FamilyInfoPage({
    super.key,
    required this.headName,
    this.spouseName,
    this.children = const [],
    this.parentId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 0,
        leading: CustomBackButton(
          color: Config.textHead,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.goNamed('familyList'); // Ubah ke goNamed agar aman
            }
          },
        ),
        title: Text(
          "Keluarga Saya",
          style: TextStyle(
            color: Config.textHead,
            fontWeight: Config.semiBold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === 1. KARTU INFORMASI UTAMA KELUARGA ===
            _buildFamilyHeaderCard(context),
            const SizedBox(height: 24),

            // === 2. JUDUL UNTUK DAFTAR ANAK ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Anak-Anak (${children.length})',
                  style: TextStyle(
                    color: Config.textHead,
                    fontSize: 18,
                    fontWeight: Config.semiBold,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // PASSING parentId ke form tambah anggota
                    context.pushNamed('addFamilyMember', extra: parentId);
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Config.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // === 3. DAFTAR ANAK ===
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Text(
                    "Belum ada data anak.",
                    style: TextStyle(color: Config.textSecondary),
                  ),
                ),
              )
            else
              Column(
                children: children.map((member) {
                  return _buildMemberCard(context: context, member: member);
                }).toList(),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.pushNamed('treeVisual'),
        backgroundColor: Config.primary,
        tooltip: 'Lihat Pohon Keluarga',
        child: const Icon(Icons.account_tree_outlined, color: Config.white),
      ),
    );
  }

  Widget _buildFamilyHeaderCard(BuildContext context) {
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
            context: context,
            name: headName,
            role: "Kepala Keluarga",
            emoji: '👨',
            // Kita belum punya detail object untuk kepala keluarga di sini
            // Bisa ditambahkan nanti jika perlu
            onTap: () {},
          ),
          if (spouseName != null) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Divider(color: Config.background, height: 1),
            ),
            _buildMemberTile(
              context: context,
              name: spouseName!,
              role: "Pasangan",
              emoji: '👩',
              onTap: () {},
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMemberCard({
    required BuildContext context,
    required ChildMember member,
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
        context: context,
        name: member.name,
        role: "Anak", // Bisa disesuaikan logicnya
        emoji: member.emoji,
        onTap: () {
          // Passing object member ke halaman detail
          context.pushNamed('memberInfo', extra: member);
        },
      ),
    );
  }

  Widget _buildMemberTile({
    required BuildContext context,
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
            MemberAvatar(emoji: emoji, size: 60, borderRadius: 8.0),
            const SizedBox(width: 16),
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
