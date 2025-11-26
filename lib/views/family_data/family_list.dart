import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}


class _FamilyListPageState extends State<FamilyListPage> {
  // State untuk expand/collapse
  Map<String, bool> expandedUnits = {};
  Map<String, bool> expandedChildren = {};
  bool _areAllExpanded = false;

  @override
  void initState() {
    super.initState();
    // Panggil API saat halaman dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchData();
    });
  }

  // Helper reset/init state expand (disesuaikan dengan data real)
  void _initializeExpandedState(List<FamilyUnit> units, bool isExpanded) {
    expandedUnits.clear(); // Clear dulu biar fresh
    expandedChildren.clear();
    
    for (var unit in units) {
      expandedUnits[unit.nit] = isExpanded;
      _initializeChildrenState(unit.children, isExpanded);
    }
  }

  void _initializeChildrenState(List<ChildMember>? children, bool isExpanded) {
    if (children == null) return;
    for (var child in children) {
      expandedChildren[child.nit] = isExpanded;
      _initializeChildrenState(child.children, isExpanded);
    }
  }

  void _toggleAllDropdowns(List<FamilyUnit> units) {
    setState(() {
      _areAllExpanded = !_areAllExpanded;
      _initializeExpandedState(units, _areAllExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 0,
        // leading: CustomBackButton(), // Uncomment jika ada
        title: Text(
          'List Keluarga',
          style: TextStyle(
            color: Config.textHead,
            fontSize: 20,
            fontWeight: Config.semiBold,
          ),
        ),
        centerTitle: true,
        actions: [
          // Gunakan Consumer selector atau akses provider untuk toggle
          Consumer<UserProvider>(
            builder: (context, provider, _) {
              return IconButton(
                onPressed: () => _toggleAllDropdowns(provider.familyUnits),
                icon: Icon(
                  _areAllExpanded ? Icons.unfold_less : Icons.unfold_more,
                  color: Config.textSecondary,
                  size: 28,
                ),
                tooltip: _areAllExpanded ? "Tutup Semua" : "Buka Semua",
              );
            }
          ),
          const SizedBox(width: 8),
        ],
      ),
      // BUNGKUS BODY DENGAN CONSUMER
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.state == ViewState.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.state == ViewState.error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Error: ${provider.errorMessage}"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => provider.fetchData(),
                    child: const Text("Coba Lagi"),
                  ),
                ],
              ),
            );
          }

          final familyUnits = provider.familyUnits;

          if (familyUnits.isEmpty) {
            return const Center(child: Text("Tidak ada data keluarga"));
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: familyUnits.length,
            itemBuilder: (context, index) {
              final familyUnit = familyUnits[index];
              // Default false jika belum ada di map
              final isExpanded = expandedUnits[familyUnit.nit] ?? false;

              return _buildFamilyUnitCard(
                unit: familyUnit,
                isExpanded: isExpanded,
                onToggle: () {
                  setState(() {
                    expandedUnits[familyUnit.nit] = !isExpanded;
                  });
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.pushNamed('addFamily');
        },
        backgroundColor: Config.primary,
        child: const Icon(Icons.add, color: Config.white),
      ),
    );
  }

  Widget _buildFamilyUnitCard({
    required FamilyUnit unit,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    // ... (KODE WIDGET INI SAMA PERSIS SEPERTI YANG KAMU KIRIM) ...
    // Copy paste widget _buildFamilyUnitCard dari kode lamamu ke sini
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      context.pushNamed('familyInfo');
                    },
                    child: Row(
                      children: [
                        MemberAvatar(
                          emoji: '👨‍👩‍👧‍👦',
                          size: 50,
                          borderRadius: 12,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${unit.nit} ${unit.headName}${unit.spouseName != null ? " & ${unit.spouseName}" : ""}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: Config.semiBold,
                                  color: Config.textHead,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Jumlah Anak: ${unit.children.length}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Config.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Config.textSecondary,
                  ),
                  onPressed: onToggle,
                  tooltip: isExpanded ? 'Tutup' : 'Buka',
                ),
              ],
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Config.background, width: 2),
                ),
              ),
              child: Column(
                children: unit.children.map((member) {
                  return _buildChildMemberTile(member: member, level: 1);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ... (KODE WIDGET TILE ANAK SAMA PERSIS SEPERTI YANG KAMU KIRIM) ...
  // Copy paste widget _buildChildMemberTile dari kode lamamu ke sini
  Widget _buildChildMemberTile({
    required ChildMember member,
    required int level,
  }) {
    final bool isExpandable =
        (member.children != null &&
        member
            .children!
            .isNotEmpty); // Logic sedikit diubah: expandable jika punya anak
    final bool isExpanded = expandedChildren[member.nit] ?? false;
    final double indentation = 20.0 * level;

    return Column(
      children: [
        InkWell(
          onTap: () {
            // Logic navigasi
            context.pushNamed('memberInfo');
          },
          child: Padding(
            padding: EdgeInsets.only(
              left: 16 + indentation,
              right: 16,
              top: 12,
              bottom: 12,
            ),
            child: Row(
              children: [
                MemberAvatar(
                  photoUrl: member.photoUrl,
                  emoji: member.emoji,
                  size: 40,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${member.nit} ${member.name}",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: Config.medium,
                          color: Config.textHead,
                        ),
                      ),
                      const SizedBox(height: 2),
                      if (member.spouseName != null)
                        Text(
                          "Pasangan: ${member.spouseName}",
                          style: TextStyle(
                            fontSize: 13,
                            color: Config.textSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                if (isExpandable)
                  IconButton(
                    icon: Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Config.textSecondary,
                      size: 24,
                    ),
                    onPressed: () {
                      setState(() {
                        expandedChildren[member.nit] = !isExpanded;
                      });
                    },
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Config.textSecondary.withOpacity(0.5),
                  ),
              ],
            ),
          ),
        ),
        // Render anak-anaknya secara rekursif
        if (isExpanded &&
            member.children != null &&
            member.children!.isNotEmpty)
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Config.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              color: Config.primary.withOpacity(0.03),
            ),
            child: Column(
              children: member.children!.map((grandChild) {
                return _buildChildMemberTile(
                  member: grandChild,
                  level: level + 1,
                );
              }).toList(),
            ),
          )
      ],
    );
  }
}
