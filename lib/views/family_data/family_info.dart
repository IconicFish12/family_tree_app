import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
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

  void _openMemberInfo(int? memberId) {
    if (memberId == null) return;

    context.pushNamed(
      'memberInfo',
      pathParameters: {'memberId': memberId.toString()},
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final allUsers = userProvider.allUsers;

    UserData? headUser;
    if (widget.parentId != null) {
      try {
        headUser = allUsers.firstWhere(
          (user) => user.userId == widget.parentId,
        );
      } catch (_) {
        // Data kepala keluarga belum tersedia pada daftar yang dimuat.
      }
    }

    final headName =
        headUser?.fullName ?? widget.initialHeadName ?? 'Loading...';
    UserData? spouseUser;
    final childrenList = <ChildMember>[];

    if (headUser?.familyTreeId != null) {
      final familyTreeId = headUser!.familyTreeId!;
      final headUserId = headUser.userId;

      try {
        spouseUser = allUsers.firstWhere(
          (user) =>
              user.familyTreeId == familyTreeId &&
              user.parentId == null &&
              user.userId != headUserId,
        );
      } catch (_) {
        // Kepala keluarga belum memiliki pasangan pada daftar yang dimuat.
      }

      final familyMembers = allUsers.where((user) {
        final memberTreeId = user.familyTreeId;
        return memberTreeId != null &&
            memberTreeId.startsWith('$familyTreeId.') &&
            user.userId != headUserId;
      });

      childrenList.addAll(
        familyMembers.map(
          (user) => ChildMember(
            id: user.userId,
            nit: user.familyTreeId ?? '',
            name: user.fullName ?? 'Unknown',
            location: user.address ?? '',
            birthYear: user.birthYear ?? '',
            emoji: '👤',
            photoUrl: user.avatar is String ? user.avatar as String : null,
          ),
        ),
      );
    }

    final spouseName = spouseUser?.fullName;

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
          'Keluarga $headName',
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCardItem(
                  name: headName,
                  subtitle: 'Kepala Keluarga',
                  photoUrl: headUser?.avatar is String
                      ? headUser!.avatar as String
                      : null,
                  onTap: () => _openMemberInfo(headUser?.userId),
                ),
                if (spouseName != null)
                  _buildCardItem(
                    name: spouseName,
                    subtitle: 'Pasangan',
                    photoUrl: spouseUser?.avatar is String
                        ? spouseUser!.avatar as String
                        : null,
                    onTap: () => _openMemberInfo(spouseUser?.userId),
                  ),
                ...List.generate(childrenList.length, (index) {
                  final child = childrenList[index];
                  return _buildCardItem(
                    name: child.name,
                    subtitle: 'Anak Ke ${index + 1}',
                    photoUrl: child.photoUrl,
                    onTap: () => _openMemberInfo(child.id),
                  );
                }),
                if (childrenList.isEmpty && spouseName == null)
                  Padding(
                    padding: const EdgeInsets.all(30),
                    child: Center(
                      child: Text(
                        'Belum ada data anggota keluarga tambahan.',
                        style: TextStyle(color: Config.textSecondary),
                      ),
                    ),
                  ),
                const SizedBox(height: 80),
              ],
            ),
          ),
          if (_isMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleMenu,
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),
          if (_isMenuOpen)
            Positioned(
              right: 16,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (widget.parentId != null && spouseUser == null) ...[
                    _buildMenuOption(
                      label: 'Tambah Pasangan',
                      onTap: () {
                        _toggleMenu();
                        context.pushNamed(
                          'addFamily',
                          queryParameters: {
                            'memberId': widget.parentId.toString(),
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (widget.parentId != null) ...[
                    _buildMenuOption(
                      label: 'Tambah Anggota Keluarga',
                      onTap: () {
                        _toggleMenu();
                        context.pushNamed(
                          'addFamilyMember',
                          queryParameters: {
                            'parentId': widget.parentId.toString(),
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Config.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.chevron_right, color: Config.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardItem({
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
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: [
              Container(
                width: 95,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  image: fullPhotoUrl != null
                      ? DecorationImage(
                          image: NetworkImage(fullPhotoUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: fullPhotoUrl == null
                    ? Icon(Icons.person, size: 44, color: Colors.grey.shade500)
                    : null,
              ),
              Expanded(
                child: Container(
                  height: double.infinity,
                  color: Config.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
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
