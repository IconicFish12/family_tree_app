import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyInfoCard extends StatelessWidget {
  final UserData user;

  const FamilyInfoCard({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
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
          onTap: () => context.pushNamed('treeVisual'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 120,
                width: double.infinity,
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/family_logo.png'),
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
                      'Keluarga Saya',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: Config.semiBold,
                        color: Config.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID Pohon: ${user.familyTreeId ?? "-"}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.regular,
                        color: Config.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.fullName ?? 'Tanpa Nama',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.regular,
                        color: Config.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Ketuk kartu ini untuk membuka bagan keluarga.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.white.withValues(alpha: 0.88),
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
