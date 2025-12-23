import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:provider/provider.dart';

class FamilyInfoPage extends StatelessWidget {
  // Hanya parentId yang krusial untuk fetching data
  final int? parentId;
  // Parameter lain opsional/fallback
  final String? initialHeadName;

  const FamilyInfoPage({
    super.key,
    this.parentId,
    this.initialHeadName,
    // Parameter lain diabaikan karena kita fetch realtime
    String? spouseName,
    List<ChildMember>? children,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Listen ke UserProvider
    final userProvider = context.watch<UserProvider>();
    final allUsers = userProvider.allUsers;

    // 2. Cari data Kepala Keluarga (Head)
    UserData? headUser;
    if (parentId != null) {
      try {
        headUser = allUsers.firstWhere((u) => u.userId == parentId);
      } catch (e) {
        // User not found
      }
    }

    // 3. Cari Data Pasangan & Anak secara Realtime
    String headName = headUser?.fullName ?? initialHeadName ?? "Loading...";
    String? spouseNameStr;
    List<ChildMember> childrenList = [];

    if (headUser != null && headUser.familyTreeId != null) {
      final myFamilyTreeId = headUser.familyTreeId!;

      // Cari Pasangan (Root user dengan familyTreeId sama, tapi userId beda)
      try {
        final spouse = allUsers.firstWhere((u) {
          return u.familyTreeId == myFamilyTreeId &&
              u.parentId == null &&
              u.userId != headUser!.userId;
        });
        spouseNameStr = spouse.fullName;
      } catch (_) {}

      // Cari Anak (FamilyTreeId startsWith myFamilyTreeId. dan userId beda)
      // Note: Logic filter sesuaikan dengan FamilyInfoCard
      final familyMembers = allUsers.where((u) {
        if (u.familyTreeId == null) return false;
        return u.familyTreeId!.startsWith('$myFamilyTreeId.') &&
            u.userId != headUser!.userId;
      }).toList();

      childrenList = familyMembers
          .map(
            (u) => ChildMember(
              id: u.userId,
              nit: u.familyTreeId ?? '',
              name: u.fullName ?? 'Unknown',
              location: u.address ?? '',
              birthYear: u.birthYear ?? '',
              emoji: '👤',
              photoUrl: u.avatar is String ? u.avatar : null,
            ),
          )
          .toList();
    }

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
            _buildFamilyHeaderCard(context, headName, spouseNameStr),
            const SizedBox(height: 24),

            // === 2. JUDUL UNTUK DAFTAR ANAK ===
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Anak-Anak (${childrenList.length})',
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
            if (childrenList.isEmpty)
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
                children: childrenList.map((member) {
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

  Widget _buildFamilyHeaderCard(
    BuildContext context,
    String headName,
    String? spouseName,
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
            context: context,
            name: headName,
            role: "Kepala Keluarga",
            emoji: '👨',
            onTap: () {},
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(color: Config.background, height: 1),
          ),
          if (spouseName != null)
            _buildMemberTile(
              context: context,
              name: spouseName,
              role: "Pasangan",
              emoji: '👩',
              onTap: () {},
            )
          else
            InkWell(
              onTap: () {
                // Navigasi ke tambah anggota khusus untuk pasangan
                // Kita pass parentId (ID user saat ini)
                // Dan di form nanti otomatis set relationType ke 'Pasangan'
                context.pushNamed(
                  'addFamilyMember',
                  extra: {'parentId': parentId, 'isSpouseOnly': true},
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_add_alt_1, color: Config.primary),
                    const SizedBox(width: 8),
                    Text(
                      "Tambah Pasangan",
                      style: TextStyle(
                        color: Config.primary,
                        fontWeight: Config.semiBold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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
