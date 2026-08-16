import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class SearchFamilyPage extends StatefulWidget {
  const SearchFamilyPage({super.key});

  @override
  State<SearchFamilyPage> createState() => _SearchFamilyPageState();
}

class _SearchFamilyPageState extends State<SearchFamilyPage> {
  late TextEditingController _searchController;

  // Filter variables
  int? selectedYear;
  String? selectedMonth;

  final List<String> months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchData(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<UserData> _filterMembers(List<UserData> allUsers) {
    final query = _searchController.text.toLowerCase();

    return allUsers.where((user) {
      final name = user.fullName?.toLowerCase() ?? '';
      final treeId = user.familyTreeId?.toLowerCase() ?? '';

      final textMatch =
          query.isEmpty || name.contains(query) || treeId.contains(query);

      bool yearMatch = true;
      if (selectedYear != null) {
        if (user.birthYear != null) {
          final birthYearInt = int.tryParse(user.birthYear!);
          yearMatch = birthYearInt == selectedYear;
        } else {
          yearMatch = false;
        }
      }

      final monthMatch = selectedMonth == null;

      return textMatch && yearMatch && monthMatch;
    }).toList();
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      selectedYear = null;
      selectedMonth = null;
    });
  }

  void _showFilterBottomSheet() {
    int? tempYear = selectedYear;
    String? tempMonth = selectedMonth;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter sheetSetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filter',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: Config.semiBold,
                        color: Config.textHead,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Tahun Kelahiran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<int>(
                      value: tempYear,
                      hint: const Text('Pilih Tahun'),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: [
                        for (int year = 2024; year >= 1920; year--)
                          DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          ),
                      ],
                      onChanged: (value) =>
                          sheetSetState(() => tempYear = value),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Bulan Kelahiran',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButton<String>(
                      value: tempMonth,
                      hint: const Text('Pilih Bulan'),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: months
                          .map(
                            (m) => DropdownMenuItem(value: m, child: Text(m)),
                          )
                          .toList(),
                      onChanged: (value) =>
                          sheetSetState(() => tempMonth = value),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _resetFilters();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: BorderSide(color: Config.primary),
                          foregroundColor: Config.primary,
                        ),
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedYear = tempYear;
                            selectedMonth = tempMonth;
                          });
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Config.primary,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Config.white,
                        ),
                        child: const Text(
                          'Terapkan',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.white,
        elevation: 0,
        title: Text(
          'Pencarian',
          style: TextStyle(
            color: Config.textHead,
            fontSize: 20,
            fontWeight: Config.semiBold,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Config.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: 'Cari berdasarkan nama, nik...',
                            hintStyle: TextStyle(
                              color: Config.textSecondary,
                              fontSize: 12,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Config.textSecondary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _showFilterBottomSheet,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Config.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.all(12),
                        child: Icon(Icons.tune, color: Config.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (selectedYear != null || selectedMonth != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (selectedYear != null)
                        _buildActiveFilterChip(
                          'Tahun: $selectedYear',
                          () => setState(() => selectedYear = null),
                        ),
                      if (selectedMonth != null)
                        _buildActiveFilterChip(
                          'Bulan: $selectedMonth',
                          () => setState(() => selectedMonth = null),
                        ),
                    ],
                  ),
              ],
            ),
          ),
          Expanded(
            child: Consumer<UserProvider>(
              builder: (context, provider, child) {
                if (provider.state == ViewState.loading &&
                    provider.familyUnits.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.state == ViewState.error) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(provider.errorMessage ?? "Terjadi kesalahan"),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => provider.fetchData(isRefresh: true),
                          child: const Text("Coba Lagi"),
                        ),
                      ],
                    ),
                  );
                }
                
                final allUsers = provider.allUsers;
                final filtered = _filterMembers(allUsers);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 60,
                          color: Config.textSecondary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada hasil pencarian',
                          style: TextStyle(
                            fontSize: 16,
                            color: Config.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final member = filtered[index];
                    return _buildMemberCard(member);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onDeleted) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Config.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: onDeleted,
            child: const Icon(Icons.close, size: 14, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberCard(UserData member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Config.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          // Convert UserData to ChildMember for navigation
          final childMember = ChildMember(
            id: member.userId,
            nit: member.familyTreeId ?? "-",
            name: member.fullName ?? "No Name",
            spouseName: null, 
            location: member.address ?? "-",
            emoji: '👤',
            children: [], 
            photoUrl: member.avatar?.toString(),
          );

          context.pushNamed('memberInfo', extra: childMember);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MemberAvatar(
                photoUrl: member.avatar?.toString(),
                emoji: '👤',
                size: 50,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName ?? 'Tanpa Nama',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.semiBold,
                        color: Config.textHead,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.familyTreeId ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.birthYear ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 18,
                color: Config.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
