import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:provider/provider.dart';

class FamilyInfoPage extends StatefulWidget {
  final int? parentId;
  final String? initialHeadName;

  const FamilyInfoPage({
    super.key,
    this.parentId,
    this.initialHeadName,
    String? spouseName,
    List<ChildMember>? children,
  });

  @override
  State<FamilyInfoPage> createState() => _FamilyInfoPageState();
}

class _FamilyInfoPageState extends State<FamilyInfoPage> {
  bool _isMenuOpen = false;

  void _toggleMenu() {
    setState(() {
      _isMenuOpen = !_isMenuOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final allUsers = userProvider.allUsers;

    UserData? headUser;
    if (widget.parentId != null) {
      try {
        headUser = allUsers.firstWhere((u) => u.userId == widget.parentId);
      } catch (e) {
        // User not found
      }
    }

    String headName = headUser?.fullName ?? widget.initialHeadName ?? "Loading...";
    UserData? spouseUser;
    String? spouseNameStr;
    List<ChildMember> childrenList = [];

    if (headUser != null && headUser.familyTreeId != null) {
      final myFamilyTreeId = headUser.familyTreeId!;

      try {
        spouseUser = allUsers.firstWhere((u) {
          return u.familyTreeId == myFamilyTreeId &&
              u.parentId == null &&
              u.userId != headUser!.userId;
        });
        spouseNameStr = spouseUser.fullName;
      } catch (_) {}

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
        backgroundColor: Config.primary,
        elevation: 0,
        leading: CustomBackButton(
          color: Config.white,
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.goNamed('familyList');
            }
          },
        ),
        title: Text(
          "Keluarga $headName",
          style: const TextStyle(
            color: Config.white,
            fontWeight: Config.semiBold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleMenu,
        backgroundColor: Config.primary,
        shape: const CircleBorder(),
        child: Icon(
          _isMenuOpen ? Icons.close : Icons.add,
          color: Config.white,
          size: 30,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    context.pushNamed(
                      'addFamilyMember',
                      queryParameters: {
                        if (parentId != null) 'parentId': parentId.toString(),
                      },
                    );
                  },
                ),

                // Card Pasangan (jika ada)
                if (spouseNameStr != null)
                  _buildCardItem(
                    context: context,
                    name: spouseNameStr,
                    subtitle: "Pasangan",
                    photoUrl: spouseUser?.avatar is String ? spouseUser?.avatar : null,
                    onTap: () {
                      if (spouseUser != null) {
                        final spouseMember = ChildMember(
                          id: spouseUser.userId,
                          nit: spouseUser.familyTreeId ?? '',
                          name: spouseUser.fullName ?? spouseNameStr ?? '',
                          role: "Pasangan",
                          location: spouseUser.address ?? '',
                          birthYear: spouseUser.birthYear ?? '',
                          emoji: '👤',
                          photoUrl: spouseUser.avatar is String ? spouseUser.avatar : null,
                        );
                        context.pushNamed('memberInfo', extra: spouseMember);
                      }
                    },
                  ),

                // Card Anak-Anak
                ...List.generate(childrenList.length, (index) {
                  final child = childrenList[index];
                  final childRole = "Anak Ke ${index + 1}";
                  return _buildCardItem(
                    context: context,
                    name: child.name,
                    subtitle: childRole,
                    photoUrl: child.photoUrl,
                    onTap: () {
                      final childWithRole = ChildMember(
                        id: child.id,
                        nit: child.nit,
                        name: child.name,
                        role: childRole,
                        birthYear: child.birthYear,
                        spouseName: child.spouseName,
                        location: child.location,
                        photoUrl: child.photoUrl,
                        emoji: child.emoji,
                      );
                      context.pushNamed('memberInfo', extra: childWithRole);
                    },
                  );
                }),

                if (childrenList.isEmpty && spouseNameStr == null)
                  Padding(
                    padding: const EdgeInsets.all(30.0),
                    child: Center(
                      child: Text(
                        "Belum ada data anggota keluarga tambahan.",
                        style: TextStyle(color: Config.textSecondary),
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),

          // Dimmed Backdrop Overlay
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),

          // Speed Dial Menu Buttons
          if (_isMenuOpen)
            Positioned(
              right: 16,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMenuOption(
                    label: 'Tambah Anggota Keluarga',
                    onTap: () {
                      _toggleMenu();
                      if (widget.parentId != null) {
                        context.pushNamed(
                          'addFamilyMember',
                          extra: {'parentId': widget.parentId, 'parentName': headName},
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMenuOption(
                    label: 'Lihat pohon keluarga',
                    onTap: () {
                      _toggleMenu();
                      context.pushNamed(
                        'treeVisual',
                        extra: {
                          'familyTreeId': headUser?.familyTreeId,
                          'title': headName,
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Config.primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
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
                context.pushNamed(
                  'addFamily',
                  queryParameters: {
                    if (parentId != null) 'memberId': parentId.toString(),
                  },
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
              const SizedBox(width: 12),
              const Icon(
                Icons.chevron_right,
                color: Config.white,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem({
    required BuildContext context,
    required String name,
    required String subtitle,
    String? photoUrl,
    VoidCallback? onTap,
  }) {
    final fullPhotoUrl = photoUrl != null && photoUrl.isNotEmpty
        ? Config.getFullImageUrl(photoUrl)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      height: 90,
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 12.0),
      child: _buildMemberTile(
        context: context,
        name: member.name,
        role: "Anak",
        emoji: member.emoji,
        onTap: () {
          if (member.id != null) {
            context.pushNamed(
              'memberInfo',
              pathParameters: {'memberId': member.id.toString()},
            );
          }
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
                  image: fullPhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(fullPhotoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: fullPhotoUrl == null
                    ? Icon(
                        Icons.person,
                        size: 44,
                        color: Colors.grey.shade500,
                      )
                    : null,
              ),
              // Green Details Container
              Expanded(
                child: Container(
                  height: double.infinity,
                  color: Config.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Config.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 13,
                                color: Config.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right,
                        color: Config.white,
                        size: 24,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
