import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ChildMember {
  final String nit; // Nomor Induk (misal "1.1")
  final String name;
  final String? spouseName; // Pasangan dari anak
  final String location;
  final String? photoUrl;
  final String emoji;

  ChildMember({
    required this.nit,
    required this.name,
    this.spouseName,
    required this.location,
    this.photoUrl,
    this.emoji = '👤',
  });
}

class FamilyUnit {
  final String nit; // Nomor Induk (misal "1.")
  final String headName; // Nama Kepala (misal "ROISAH")
  final String? spouseName; // Pasangan Kepala (misal "ISKANDAR")
  final String location;
  final List<ChildMember> children; // Daftar anak (baris 1.1, 1.2, ...)

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
  Map<String, bool> expandedUnits = {}; // Pakai NIT sebagai key

  @override
  void initState() {
    super.initState();
    _initializeFamilyData();
  }

  // Inisialisasi data dummy berdasarkan image_d18642.png
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
          ),
          ChildMember(
            nit: '1.2',
            name: 'Abu Thoyib',
            spouseName: 'Tasmiyah',
            location: 'Jarakan Banyuudono Ponorogo',
          ),
          ChildMember(
            nit: '1.3',
            name: 'Syihabur Romli',
            spouseName: 'Marhamah',
            location: 'Bedi Babadan Ponorogo',
          ),
          ChildMember(
            nit: '1.4',
            name: 'Jazin Nafsi',
            spouseName: 'Hasan Puro',
            location: 'Kebon Kadipaten Babadan Ponorogo',
          ),
          ChildMember(
            nit: '1.5',
            name: 'Sulatun',
            spouseName: 'H. Qosim',
            location: 'Bedi Babadan Ponorogo',
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
          ),
          ChildMember(
            nit: '1.8',
            name: 'Sringatun',
            spouseName: 'H. Usman',
            location: 'Karangtengah Garu Baron Nganjuk',
          ),
          ChildMember(
            nit: '1.9',
            name: 'Suci',
            spouseName: 'Mangun Suyoto',
            location: 'Plosorejo Garu Baron Nganjuk',
          ),
        ],
      ),
      // Tambah data dummy lain
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
          ),
          ChildMember(
            nit: '2.2',
            name: 'Ani Sujadmiko',
            spouseName: 'Joko',
            location: 'Jakarta',
          ),
        ],
      ),
    ];

    // Initialize all units as collapsed
    for (var unit in familyUnits) {
      expandedUnits[unit.nit] = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background, // Sesuai Config
      appBar: AppBar(
        backgroundColor: Config.background, // Sesuai Config
        elevation: 0,
        title: Text(
          'List Keluarga',
          style: TextStyle(
            color: Config.textHead, // Sesuai Config
            fontSize: 20,
            fontWeight: Config.semiBold, // Sesuai Config
          ),
        ),
        leading: CustomBackButton(
          color: Config.textHead, // Sesuai Config
          onPressed: () {
            context.pop();
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => context.pushNamed('profile'),
            icon: Icon(
              Icons.account_circle_outlined,
              color: Config.textSecondary, // Sesuai Config
              size: 28,
            ),
            tooltip: "Profile",
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          context.goNamed('addFamilyMember');
        },
        backgroundColor: Config.primary, // Sesuai Config
        child: const Icon(Icons.add, color: Config.white), // Sesuai Config
      ),
    );
  }

  /// Widget untuk Card Unit Keluarga (Kepala Keluarga + Pasangan)
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
            color: Config.textHead.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header (Kepala Keluarga)
          // Hapus InkWell pembungkus luar
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // === BAGIAN YANG BISA DI-KLIK UNTUK NAVIGASI ===
                Expanded(
                  child: InkWell(
                    // Aksi navigasi baru
                    onTap: () {
                      // Navigasi ke FamilyInfoPage
                      // (Asumsi nama route-nya 'familyInfo')
                      context.pushNamed('familyInfo');
                    },
                    child: Row(
                      children: [
                        MemberAvatar(
                          emoji: '👨‍👩‍👧‍👦',
                          size: 50,
                          borderRadius: 12, // Dibuat lebih kotak
                        ),
                        const SizedBox(width: 12),
                        // Info Keluarga
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                // Menggabungkan nama & pasangan
                                "${unit.nit} ${unit.headName}" +
                                    (unit.spouseName != null
                                        ? " & ${unit.spouseName}"
                                        : ""),
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
                // === BAGIAN YANG BISA DI-KLIK UNTUK TOGGLE ===
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Config.textSecondary,
                  ),
                  // Aksi toggle
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
                ), // Garis pemisah
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: unit.children.length,
                itemBuilder: (context, memberIndex) {
                  final member = unit.children[memberIndex];
                  return _buildChildMemberTile(member);
                },
              ),
            ),
        ],
      ),
    );
  }

  /// Widget untuk Tile Anak (di dalam card)
  Widget _buildChildMemberTile(ChildMember member) {
    return InkWell(
      onTap: () {
        context.pushNamed('memberInfo'); // Navigasi ke detail anak
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                    "${member.nit} ${member.name}", // Tampilkan NIT + Nama
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: Config.medium,
                      color: Config.textHead,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Tampilkan Pasangan jika ada
                  if (member.spouseName != null)
                    Text(
                      "Pasangan: ${member.spouseName}",
                      style: TextStyle(
                        fontSize: 13,
                        color: Config.textSecondary,
                      ),
                    ),
                  // Tampilkan Lokasi
                  Text(
                    member.location,
                    style: TextStyle(
                      fontSize: 13,
                      color: Config.textSecondary.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Config.textSecondary.withOpacity(0.5),
            ),
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
