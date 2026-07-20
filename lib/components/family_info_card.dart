import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FamilyInfoCard extends StatelessWidget {
  final UserData user;

  const FamilyInfoCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Ambil data user dari UserProvider untuk menghitung jumlah anggota
    final allUsers = context.watch<UserProvider>().allUsers;
    final rootId = user.familyTreeId?.split('.').first ?? '';
    
    // Hitung jumlah anggota keluarga di bawah root ID yang sama
    final familyCount = allUsers.where((u) {
      if (u.familyTreeId == null) return false;
      return u.familyTreeId == rootId || u.familyTreeId!.startsWith('$rootId.');
    }).length;

    // Temukan nama kepala silsilah (root)
    String familyHeadName = 'Utama';
    try {
      final rootUser = allUsers.firstWhere((u) => u.familyTreeId == rootId);
      familyHeadName = rootUser.fullName ?? 'Utama';
    } catch (_) {}

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.pushNamed('treeVisual'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 130,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/family_logo.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                color: Config.primary,
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Keluarga Utama',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: Config.semiBold,
                        color: Config.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      allUsers.isNotEmpty ? '$familyCount Anggota' : 'Loading...',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.regular,
                        color: Config.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Keluarga Besar $familyHeadName',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.regular,
                        color: Config.white.withValues(alpha: 0.92),
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
}

