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
  final ScrollController _scrollController = ScrollController();

  Map<String, bool> expandedUnits = {};
  Map<String, bool> expandedChildren = {};
  bool _areAllExpanded = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchData(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<UserProvider>().fetchData(isRefresh: false);
    }
  }

  void _initializeExpandedState(List<FamilyUnit> units, bool isExpanded) {
    expandedUnits.clear();
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
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          // Handle Initial Loading
          if (provider.state == ViewState.loading &&
              provider.familyUnits.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          // Handle Error Full Page
          if (provider.state == ViewState.error &&
              provider.familyUnits.isEmpty) {
            return Center(child: Text("Error: ${provider.errorMessage}"));
          }

          final familyUnits = provider.familyUnits;

          if (familyUnits.isEmpty) {
            return const Center(
              child: Text("Tidak ada data keluarga (List Kosong)"),
            );
          }

          // Gunakan ListView.builder
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: familyUnits.length + (provider.isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == familyUnits.length) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final familyUnit = familyUnits[index];
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
    print(unit.children);
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
                      if (unit.children.isNotEmpty) {
                        // Jika anak ini punya anak lagi, buka Family Info dia sebagai kepala
                        context.pushNamed(
                          'familyInfo',
                          extra: {
                            'headName': unit.headName,
                            'spouseName': unit.spouseName,
                            'children': unit.children,
                            'parentId': unit.headId,
                          },
                        );
                      } else {
                        context.pushNamed('memberInfo', extra: unit);
                      }
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

  Widget _buildChildMemberTile({
    required ChildMember member,
    required int level,
  }) {
    final bool isExpandable = (member.children.isNotEmpty);
    final bool isExpanded = expandedChildren[member.nit] ?? false;
    final double indentation = 20.0 * level;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (member.children.isNotEmpty) {
              context.pushNamed(
                'familyInfo',
                extra: {
                  'headName': member.name,
                  'spouseName': member.spouseName,
                  'children': member.children,
                  'parentId': member.id,
                },
              );
            } else {
              context.pushNamed('memberInfo', extra: member);
            }
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
        if (isExpanded && member.children.isNotEmpty)
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
              children: member.children.map((grandChild) {
                return _buildChildMemberTile(
                  member: grandChild,
                  level: level + 1,
                );
              }).toList(),
            ),
          ),
        if (isExpanded && member.children.isNotEmpty)
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
              // PROTEKSI LOOPING DI SINI
              children: member.children.map<Widget>((grandChild) {
                return _buildChildMemberTile(
                  member: grandChild,
                  level: level + 1,
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
