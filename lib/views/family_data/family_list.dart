import 'package:family_tree_app/components/member_avatar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  late List<FamilyGroup> familyGroups;
  Map<int, bool> expandedGroups = {};

  @override
  void initState() {
    super.initState();
    _initializeFamilyGroups();
  }

  void _initializeFamilyGroups() {
    familyGroups = [
      FamilyGroup(
        name: 'Keluarga Utama',
        memberCount: 20,
        members: [
          FamilyMember(
            name: 'Topan Namas',
            relation: 'Kepala Keluarga',
            emoji: '👨',
          ),
          FamilyMember(
            name: 'Sinta Suke',
            relation: 'Ibu Rumah Tangga',
            emoji: '👩',
          ),
          FamilyMember(
            name: 'Tomas Alla Edisound',
            relation: 'Anak Ke 1',
            emoji: '👨',
          ),
          FamilyMember(name: 'Nana Donal', relation: 'Anak Ke 2', emoji: '👩'),
        ],
      ),
      FamilyGroup(
        name: 'Keluarga Ibu',
        memberCount: 20,
        members: [
          FamilyMember(
            name: 'Ahmad Salim',
            relation: 'Kepala Keluarga',
            emoji: '👨',
          ),
          FamilyMember(name: 'Siti Nurhaliza', relation: 'Istri', emoji: '👩'),
          FamilyMember(
            name: 'Budi Santoso',
            relation: 'Anak Ke 1',
            emoji: '👨',
          ),
        ],
      ),
      FamilyGroup(
        name: 'Keluarga Ayah',
        memberCount: 20,
        members: [
          FamilyMember(
            name: 'Muhammad Hasan',
            relation: 'Kepala Keluarga',
            emoji: '👨',
          ),
          FamilyMember(name: 'Fatimah Zahra', relation: 'Istri', emoji: '👩'),
          FamilyMember(
            name: 'Umar Faruq',
            relation: 'Anak Pertama',
            emoji: '👨',
          ),
        ],
      ),
      FamilyGroup(
        name: 'Keluarga Kakak Pertama',
        memberCount: 20,
        members: [
          FamilyMember(
            name: 'Ibrahim Khalil',
            relation: 'Kepala Keluarga',
            emoji: '👨',
          ),
          FamilyMember(name: 'Aisha Maulida', relation: 'Istri', emoji: '👩'),
          FamilyMember(
            name: 'Zainab Nurul',
            relation: 'Anak Ke 1',
            emoji: '👩',
          ),
          FamilyMember(
            name: 'Hassan Firdaus',
            relation: 'Anak Ke 2',
            emoji: '👨',
          ),
        ],
      ),
    ];

    // Initialize all groups as collapsed
    for (int i = 0; i < familyGroups.length; i++) {
      expandedGroups[i] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'List Keluarga',
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: familyGroups.length,
        itemBuilder: (context, index) {
          final familyGroup = familyGroups[index];
          final isExpanded = expandedGroups[index] ?? false;

          return _buildFamilyGroupCard(
            index: index,
            familyGroup: familyGroup,
            isExpanded: isExpanded,
            onToggle: () {
              setState(() {
                expandedGroups[index] = !isExpanded;
              });
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.goNamed('addFamilyMember');
        },
        backgroundColor: const Color(0xFF4CAF50),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildFamilyGroupCard({
    required int index,
    required FamilyGroup familyGroup,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          // Family Group Header
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar dengan emoji keluarga
                  MemberAvatar(emoji: '👨‍👩‍👧‍👦', size: 50),
                  const SizedBox(width: 12),
                  // Family Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          familyGroup.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Jumlah Anggota: ${familyGroup.memberCount}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Expand Arrow
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                ],
              ),
            ),
          ),
          // Family Members List
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200]!)),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: familyGroup.members.length,
                itemBuilder: (context, memberIndex) {
                  final member = familyGroup.members[memberIndex];
                  return _buildMemberTile(member, memberIndex);
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMemberTile(FamilyMember member, int index) {
    return InkWell(
      onTap: () {
        context.pushNamed('memberInfo');
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Member Avatar dengan support foto
            MemberAvatar(
              photoUrl: member.photoUrl,
              emoji: member.emoji,
              size: 40,
              borderRadius: 6,
            ),
            const SizedBox(width: 12),
            // Member Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.relation,
                    style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
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
  final String emoji; // Emoji placeholder sementara
  final String? photoUrl; // URL foto

  FamilyMember({
    required this.name,
    required this.relation,
    this.emoji = '👤',
    this.photoUrl,
  });
}
