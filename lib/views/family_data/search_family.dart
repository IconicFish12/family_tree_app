import 'package:family_tree_app/config/config.dart';
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
  late final TextEditingController _searchController;
  late final ScrollController _scrollController;

  String _sortOrder = 'none'; // 'none', 'asc', 'desc'
  int? _selectedLevel;
  bool _isFabMenuOpen = false;

  void _toggleFabMenu() {
    setState(() {
      _isFabMenuOpen = !_isFabMenuOpen;
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _scrollController = ScrollController()..addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UserProvider>().fetchData(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  void _handleScroll() {
    final provider = context.read<UserProvider>();
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      provider.loadMore();
    }
  }

  Future<void> _search() async {
    await context.read<UserProvider>().fetchData(
      isRefresh: true,
      keyword: _searchController.text,
    );
  }

  Future<void> _resetSearch() async {
    _searchController.clear();
    setState(() {
      _sortOrder = 'none';
      _selectedLevel = null;
    });
    await context.read<UserProvider>().fetchData(isRefresh: true, keyword: '');
  }

  void _openFilterBottomSheet() {
    final provider = context.read<UserProvider>();
    final Set<int> levelSet = {};

    for (final m in provider.directoryMembers) {
      if (m.level > 0) levelSet.add(m.level);
    }
    for (final u in provider.allUsers) {
      if (u.familyTreeId != null && u.familyTreeId!.isNotEmpty) {
        final depth = u.familyTreeId!.split('.').length;
        if (depth > 0) levelSet.add(depth);
      }
    }

    List<int> availableLevels = levelSet.toList()..sort();
    if (availableLevels.isEmpty) {
      availableLevels = List.generate(8, (i) => i + 1);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Config.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filter & Pengurutan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: Config.semiBold,
                            color: Config.textHead,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Urutkan Nama',
                      style: TextStyle(
                        fontWeight: Config.semiBold,
                        color: Config.textHead,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Default'),
                          selected: _sortOrder == 'none',
                          onSelected: (sel) {
                            if (sel) {
                              setSheetState(() => _sortOrder = 'none');
                              setState(() => _sortOrder = 'none');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Nama (A - Z)'),
                          selected: _sortOrder == 'asc',
                          onSelected: (sel) {
                            if (sel) {
                              setSheetState(() => _sortOrder = 'asc');
                              setState(() => _sortOrder = 'asc');
                            }
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Nama (Z - A)'),
                          selected: _sortOrder == 'desc',
                          onSelected: (sel) {
                            if (sel) {
                              setSheetState(() => _sortOrder = 'desc');
                              setState(() => _sortOrder = 'desc');
                            }
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Filter Tingkat Generasi',
                      style: TextStyle(
                        fontWeight: Config.semiBold,
                        color: Config.textHead,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Semua'),
                          selected: _selectedLevel == null,
                          onSelected: (sel) {
                            if (sel) {
                              setSheetState(() => _selectedLevel = null);
                              setState(() => _selectedLevel = null);
                            }
                          },
                        ),
                        ...availableLevels.map((lvl) {
                          return ChoiceChip(
                            label: Text('Generasi $lvl'),
                            selected: _selectedLevel == lvl,
                            onSelected: (sel) {
                              setSheetState(
                                () => _selectedLevel = sel ? lvl : null,
                              );
                              setState(() => _selectedLevel = sel ? lvl : null);
                            },
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                _sortOrder = 'none';
                                _selectedLevel = null;
                              });
                              setState(() {
                                _sortOrder = 'none';
                                _selectedLevel = null;
                              });
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Reset'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Config.primary,
                              foregroundColor: Config.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Terapkan'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasActiveFilter = _sortOrder != 'none' || _selectedLevel != null;

    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Config.primary,
        elevation: 0,
        title: const Text(
          'List Keluarga',
          style: TextStyle(
            color: Config.white,
            fontSize: 20,
            fontWeight: Config.semiBold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleFabMenu,
        backgroundColor: Config.primary,
        shape: const CircleBorder(),
        child: Icon(
          _isFabMenuOpen ? Icons.close : Icons.add,
          color: Config.white,
          size: 30,
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Config.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          textInputAction: TextInputAction.search,
                          onSubmitted: (_) => _search(),
                          decoration: InputDecoration(
                            hintText:
                                'Cari berdasarkan nama, nit atau hal lainnya..',
                            hintStyle: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: Colors.grey.shade500,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    InkWell(
                      onTap: _openFilterBottomSheet,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: hasActiveFilter
                              ? Config.accent
                              : Config.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              Icons.tune,
                              color: Config.white,
                              size: 24,
                            ),
                            if (hasActiveFilter)
                              Positioned(
                                top: 10,
                                right: 10,
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.yellowAccent,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    if (provider.state == ViewState.loading &&
                        provider.directoryMembers.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (provider.state == ViewState.error &&
                        provider.directoryMembers.isEmpty) {
                      return _buildPlaceholder(
                        icon: Icons.error_outline,
                        title: 'Data keluarga belum bisa dimuat',
                        message:
                            provider.errorMessage ??
                            'Silakan coba lagi beberapa saat lagi.',
                        actionLabel: 'Coba Lagi',
                        onPressed: _search,
                      );
                    }

                    List<dynamic> displayList = List.from(
                      provider.directoryMembers,
                    );

                    if (_selectedLevel != null) {
                      displayList = displayList
                          .where((m) => m.level == _selectedLevel)
                          .toList();
                    }

                    if (_sortOrder == 'asc') {
                      displayList.sort(
                        (a, b) =>
                            (a.fullName ?? '').compareTo(b.fullName ?? ''),
                      );
                    } else if (_sortOrder == 'desc') {
                      displayList.sort(
                        (a, b) =>
                            (b.fullName ?? '').compareTo(a.fullName ?? ''),
                      );
                    }

                    if (displayList.isEmpty) {
                      return _buildPlaceholder(
                        icon: Icons.groups_outlined,
                        title: 'Data keluarga belum ditemukan',
                        message: provider.keyword.isEmpty
                            ? 'Belum ada anggota keluarga yang cocok dengan filter.'
                            : 'Coba gunakan kata kunci lain yang lebih sederhana.',
                        actionLabel:
                            provider.keyword.isEmpty && !hasActiveFilter
                            ? 'Muat Ulang'
                            : 'Tampilkan Semua',
                        onPressed: _resetSearch,
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () => context.read<UserProvider>().fetchData(
                        isRefresh: true,
                        keyword: provider.keyword,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        itemCount: displayList.length + 1,
                        itemBuilder: (context, index) {
                          if (index == displayList.length) {
                            if (provider.isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 20),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );
                            }

                            if (provider.canLoadMore) {
                              return const SizedBox(height: 24);
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                                horizontal: 8,
                              ),
                              child: Center(
                                child: Text(
                                  displayList.length < provider.perPage
                                      ? 'Semua anggota keluarga sudah tampil.'
                                      : 'Tidak ada data tambahan lagi.',
                                  style: TextStyle(color: Config.textSecondary),
                                ),
                              ),
                            );
                          }

                          final member = displayList[index];
                          return _buildMemberCard(context, member);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          // Dimmed Backdrop Overlay
          if (_isFabMenuOpen)
            Positioned.fill(
              child: GestureDetector(
                onTap: _toggleFabMenu,
                child: Container(color: Colors.black.withValues(alpha: 0.5)),
              ),
            ),

          // Speed Dial Menu Buttons
          if (_isFabMenuOpen)
            Positioned(
              right: 16,
              bottom: 80,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildMenuOption(
                    label: 'Tambah Keluarga Baru',
                    onTap: () {
                      _toggleFabMenu();
                      context.pushNamed('addFamily');
                    },
                  ),
                  const SizedBox(height: 10),
                  _buildMenuOption(
                    label: 'Lihat Pohon Keluarga',
                    onTap: () {
                      _toggleFabMenu();
                      context.pushNamed('treeVisual');
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

  Widget _buildPlaceholder({
    required IconData icon,
    required String title,
    required String message,
    required String actionLabel,
    required VoidCallback onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 54, color: Config.textSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: Config.semiBold,
                color: Config.textHead,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Config.textSecondary),
            ),
            const SizedBox(height: 18),
            ElevatedButton(onPressed: onPressed, child: Text(actionLabel)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(BuildContext context, dynamic member) {
    final avatarUrl = Config.getFullImageUrl(member.avatarUrl ?? member.avatar);
    final allUsers = context.watch<UserProvider>().allUsers;
    final treeId =
        (member.familyTreeId != null &&
            member.familyTreeId.toString().isNotEmpty)
        ? member.familyTreeId.toString()
        : (member.nit ?? '').toString();

    int memberCount = 1;
    if (treeId.isNotEmpty && allUsers.isNotEmpty) {
      final calculated = allUsers.where((u) {
        final uTreeId = u.familyTreeId;
        if (uTreeId == null || uTreeId.isEmpty) return false;
        return uTreeId == treeId || uTreeId.startsWith('$treeId.');
      }).length;
      if (calculated > 0) {
        memberCount = calculated;
      }
    }

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
          onTap: () {
            context.pushNamed(
              'familyInfo',
              extra: {'parentId': member.userId, 'headName': member.fullName},
            );
          },
          child: Row(
            children: [
              // Photo / Placeholder Box
              Container(
                width: 95,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Icon(Icons.person, size: 44, color: Colors.grey.shade500)
                    : null,
              ),
              // Green Details Container
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
                              member.fullName,
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
                              'Jumlah Anggota : $memberCount',
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
