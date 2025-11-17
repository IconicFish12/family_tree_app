import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChildMember {
  final String nit;
  final String name;
  final String? spouseName;
  final String location;
  final String? photoUrl;
  final String emoji;
  final List<ChildMember>? children; // Anak dari anak ini

  ChildMember({
    required this.nit,
    required this.name,
    this.spouseName,
    required this.location,
    this.photoUrl,
    this.emoji = '👤',
    this.children, // Tambahkan di constructor
  });
}

class FamilyUnit {
  final String nit;
  final String headName;
  final String? spouseName;
  final String location;
  final List<ChildMember> children;

  FamilyUnit({
    required this.nit,
    required this.headName,
    this.spouseName,
    required this.location,
    required this.children,
  });
}

class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}


class _FamilyListPageState extends State<FamilyListPage> {
  late List<FamilyUnit> familyUnits;
  // State untuk expand/collapse
  Map<String, bool> expandedUnits = {};
  Map<String, bool> expandedChildren = {};
  bool _areAllExpanded = false;

  @override
  void initState() {
    super.initState();
    _initializeFamilyData();
  }

  // Inisialisasi data dummy yang lebih banyak dan nested
  void _initializeFamilyData() {
    familyUnits = [
      FamilyUnit(
        nit: '1.',
        headName: 'ROISAH',
        spouseName: 'ISKANDAR',
        location: 'Bedi Babadan Ponorogo',
        children: [
          ChildMember(
            nit: '1.1',
            name: 'Moh. Harjo',
            spouseName: 'S. Yasin', 
            location: 'Ngunut Babadan Ponorogo',
            children: [
              ChildMember(
                nit: '1.1.1',
                name: 'Anak Harjo 1',
                spouseName: 'Pasangan Anak Harjo',
                location: 'Ponorogo',
                children: [],
              ),
              ChildMember(
                nit: '1.1.2',
                name: 'Anak Harjo 2',
                spouseName: null,
                location: 'Ponorogo',
              ),
            ],
          ),
          ChildMember(
            nit: '1.2',
            name: 'Abu Thoyib',
            spouseName: 'Tasmiyah',
            location: 'Jarakan Banyuudono Ponorogo',
            children: [
              ChildMember(
                nit: '1.2.1',
                name: 'Anak Thoyib 1',
                spouseName: null,
                location: 'Jarakan',
              ),
            ],
          ),
          ChildMember(
            nit: '1.3',
            name: 'Syihabur Romli',
            spouseName: 'Marhamah', 
            location: 'Bedi Babadan Ponorogo',
            children: [], 
          ),
          ChildMember(
            nit: '1.6',
            name: 'Husnun/Mahfud',
            spouseName: null,
            location: '-',
          ),
          ChildMember(
            nit: '1.7',
            name: 'Hisnatun',
            spouseName: 'Bajuri',
            location: 'Prayungan Paju Ponorogo',
            children: [],
          ),
        ],
      ),
      // Data dummy lain
      FamilyUnit(
        nit: '2.',
        headName: 'AHMAD SUJADMIMKO',
        spouseName: 'SITI AMINAH',
        location: 'Surabaya',
        children: [
          ChildMember(
            nit: '2.1',
            name: 'Budi Sujadmiko',
            spouseName: 'Rina', 
            location: 'Surabaya',
            children: [
              ChildMember(
                nit: '2.1.1',
                name: 'Cahyo',
                spouseName: null,
                location: 'Surabaya',
              ),
            ],
          ),
          ChildMember(
            nit: '2.2',
            name: 'Ani Sujadmiko',
            spouseName: 'Joko',
            location: 'Jakarta',
            children: [],
          ),
        ],
      ),
      FamilyUnit(
        nit: '3.',
        headName: 'Kakek Jono',
        spouseName: 'Nenek Mar',
        location: 'Desa Lama',
        children: [
          ChildMember(
            nit: '3.1',
            name: 'Anak Kakek 1',
            spouseName: null,
            location: 'Desa Lama',
          ),
        ],
      ),
    ];

    // Initialize all units and children as collapsed
    _initializeExpandedState(false);
  }

  // Helper untuk inisialisasi/reset state expand
  void _initializeExpandedState(bool isExpanded) {
    expandedUnits = {};
    expandedChildren = {};
    for (var unit in familyUnits) {
      expandedUnits[unit.nit] = isExpanded;
      _initializeChildrenState(unit.children, isExpanded);
    }
  }

  // Helper rekursif untuk set state anak
  void _initializeChildrenState(List<ChildMember>? children, bool isExpanded) {
    if (children == null) return;
    for (var child in children) {
      expandedChildren[child.nit] = isExpanded;
      _initializeChildrenState(child.children, isExpanded);
    }
  }

  // Fungsi untuk tombol "Expand/Collapse All"
  void _toggleAllDropdowns() {
    setState(() {
      _areAllExpanded = !_areAllExpanded;
      _initializeExpandedState(_areAllExpanded);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 0,
        leading: CustomBackButton(),
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
          // === PERUBAHAN 1: Tombol Toggle All ===
          IconButton(
            onPressed: _toggleAllDropdowns,
            icon: Icon(
              _areAllExpanded
                  ? Icons
                        .unfold_less // Ikon jika semua terbuka
                  : Icons.unfold_more, // Ikon jika semua tertutup
              color: Config.textSecondary,
              size: 28,
            ),
            tooltip: _areAllExpanded ? "Tutup Semua" : "Buka Semua",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: familyUnits.length,
        itemBuilder: (context, index) {
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

  /// Widget untuk Card Unit Keluarga (Level 1)
  Widget _buildFamilyUnitCard({
    required FamilyUnit unit,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Config.textHead.withOpacity(0.08), // Perbaikan alpha
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
                // Tombol expand/collapse
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
          // Daftar Anak (Jika di-expand)
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Config.background, width: 2),
                ),
              ),
              child: Column(
                children: unit.children.map((member) {
                  // Panggil build tile rekursif
                  return _buildChildMemberTile(member: member, level: 1);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // --- PERUBAHAN 2: Widget Tile Anak yang Rekursif ---
  /// Widget untuk Tile Anak (Level 2+)
  Widget _buildChildMemberTile({
    required ChildMember member,
    required int level,
  }) {
    final bool isExpandable = member.spouseName != null;
    final bool isExpanded = expandedChildren[member.nit] ?? false;
    final double indentation = 20.0 * level;

    return Column(
      children: [
        InkWell(
          onTap: () {
            if (member.children != null && member.children!.isNotEmpty) {
              context.pushNamed('familyInfo');
            }
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
                // Avatar Anak
                MemberAvatar(
                  photoUrl: member.photoUrl,
                  emoji: member.emoji,
                  size: 40,
                  borderRadius: 8,
                ),
                const SizedBox(width: 12),
                // Info Anak
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
        else if (isExpanded &&
            isExpandable &&
            (member.children == null || member.children!.isEmpty))
          Padding(
            padding: EdgeInsets.only(
              left: 16 + indentation + 20,
              right: 16,
              bottom: 12,
            ),
            child: Text(
              "Belum ada data anak.",
              style: TextStyle(
                color: Config.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
      ],
    );
  }
}

class FamilyGroup {
  final String name;
  final int memberCount;
  final List<FamilyMember> members;

  FamilyGroup({
    required this.name,
    required this.memberCount,
    required this.members,
  });
}

class FamilyMember {
  final String name;
  final String relation;
  final String emoji;
  final String? photoUrl;

  FamilyMember({
    required this.name,
    required this.relation,
    this.emoji = '👤',
    this.photoUrl,
  });
}
