import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SearchFamilyPage extends StatefulWidget {
  const SearchFamilyPage({super.key});

  @override
  State<SearchFamilyPage> createState() => _SearchFamilyPageState();
}

class _SearchFamilyPageState extends State<SearchFamilyPage> {
  late TextEditingController _searchController;
  List<FamilyMember> filteredMembers = [];
  List<FamilyMember> allMembers = [];

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
    _initializeMembers();
    _searchController.addListener(_filterMembers);
  }

  void _initializeMembers() {
    allMembers = [
      FamilyMember(
        name: 'Topan Namas',
        nik: '1030291239393',
        dateRange: '30 - Desember - 1923',
        year: 1923,
        month: 'Desember',
        image: '👨',
      ),
      FamilyMember(
        name: 'Nona Mudae',
        nik: '1030291239393',
        dateRange: '30 - Desember - 1923',
        year: 1923,
        month: 'Desember',
        image: '👩',
      ),
      FamilyMember(
        name: 'Silam Noa',
        nik: '1030291239393',
        dateRange: '30 - Desember - 1923',
        year: 1923,
        month: 'Desember',
        image: '👨',
      ),
      FamilyMember(
        name: 'Ahmad Salim',
        nik: '1030291239394',
        dateRange: '15 - Januari - 1950',
        year: 1950,
        month: 'Januari',
        image: '👨',
      ),
      FamilyMember(
        name: 'Siti Nurhaliza',
        nik: '1030291239395',
        dateRange: '20 - Februari - 1960',
        year: 1960,
        month: 'Februari',
        image: '👩',
      ),
      FamilyMember(
        name: 'Budi Santoso',
        nik: '1030291239396',
        dateRange: '10 - Maret - 1980',
        year: 1980,
        month: 'Maret',
        image: '👨',
      ),
    ];
    filteredMembers = allMembers;
  }

  void _filterMembers() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      filteredMembers = allMembers.where((member) {
        // Text filter
        final textMatch =
            query.isEmpty ||
            member.name.toLowerCase().contains(query) ||
            member.nik.contains(query);

        // Year filter
        final yearMatch = selectedYear == null || member.year == selectedYear;

        // Month filter
        final monthMatch =
            selectedMonth == null || member.month == selectedMonth;

        return textMatch && yearMatch && monthMatch;
      }).toList();
    });
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      selectedYear = null;
      selectedMonth = null;
      filteredMembers = allMembers;
    });
  }

  void _showFilterBottomSheet() {
    // Variabel sementara untuk menampung perubahan di dalam bottom sheet
    int? tempYear = selectedYear;
    String? tempMonth = selectedMonth;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      // Gunakan StatefulBuilder untuk membuat state lokal di dalam sheet
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter sheetSetState) {
          return Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
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
                      // Tombol close tidak menerapkan perubahan
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Year Filter
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
                      // Gunakan variabel tempYear
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
                      onChanged: (value) {
                        // Gunakan sheetSetState untuk update UI di dalam sheet
                        sheetSetState(() {
                          tempYear = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Month Filter
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
                      // Gunakan variabel tempMonth
                      value: tempMonth,
                      hint: const Text('Pilih Bulan'),
                      isExpanded: true,
                      underline: const SizedBox(),
                      items: months
                          .map(
                            (month) => DropdownMenuItem(
                              value: month,
                              child: Text(month),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        // Gunakan sheetSetState untuk update UI di dalam sheet
                        sheetSetState(() {
                          tempMonth = value;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Reset filter utama
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
                          // Terapkan filter dari temp ke state utama
                          setState(() {
                            selectedYear = tempYear;
                            selectedMonth = tempMonth;
                            _filterMembers(); // Panggil filter setelah state utama di-set
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
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar with Filter
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
                          decoration: InputDecoration(
                            hintText:
                                'Cari berdasarkan nama, nik atau hal lainnya.',
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
                // Active Filters Display
                if (selectedYear != null || selectedMonth != null)
                  Wrap(
                    spacing: 8,
                    children: [
                      if (selectedYear != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Config.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Tahun: $selectedYear',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedYear = null;
                                    _filterMembers();
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (selectedMonth != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Config.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Bulan: $selectedMonth',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(width: 6),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    selectedMonth = null;
                                    _filterMembers();
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                const SizedBox(height: 12),
                // Filter Summary
                if (selectedYear != null ||
                    selectedMonth != null ||
                    _searchController.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Config.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Config.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info, size: 18, color: Config.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ditemukan ${filteredMembers.length} anggota${_buildFilterSummary()}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Config.textHead,
                              fontWeight: Config.medium,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          // Search Results
          Expanded(
            child: filteredMembers.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: filteredMembers.length,
                    itemBuilder: (context, index) {
                      final member = filteredMembers[index];
                      return _buildMemberCard(member);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _buildFilterSummary() {
    List<String> criteria = [];
    if (_searchController.text.isNotEmpty) {
      criteria.add('nama/NIK "${_searchController.text}"');
    }
    if (selectedYear != null) {
      criteria.add('tahun $selectedYear');
    }
    if (selectedMonth != null) {
      criteria.add('bulan $selectedMonth');
    }

    if (criteria.isEmpty) {
      return '';
    }
    return ' dengan kriteria: ${criteria.join(', ')}';
  }

  Widget _buildMemberCard(FamilyMember member) {
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
          context.goNamed('memberInfo');
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar dengan support foto URL
              MemberAvatar(
                photoUrl: member.photoUrl,
                emoji: member.image,
                size: 50,
              ),
              const SizedBox(width: 12),
              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: Config.semiBold,
                        color: Config.textHead,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      member.nik,
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.dateRange,
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              // Arrow Icon
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

class FamilyMember {
  final String name;
  final String nik;
  final String dateRange;
  final String image; // Emoji placeholder sementara
  final int year;
  final String month;
  final String? photoUrl; // Akan diisi dengan URL foto nantinya

  FamilyMember({
    required this.name,
    required this.nik,
    required this.dateRange,
    required this.image,
    required this.year,
    required this.month,
    this.photoUrl,
  });
}
