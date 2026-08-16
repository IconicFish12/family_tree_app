import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/family_contract.dart';
import 'package:family_tree_app/data/models/family_directory.dart';
import 'package:family_tree_app/data/models/family_tree_node.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
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
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 120) {
      context.read<UserProvider>().loadMore();
    }
  }

  Future<void> _search() {
    return context.read<UserProvider>().fetchData(
      isRefresh: true,
      keyword: _searchController.text,
    );
  }

  Future<void> _resetSearch() {
    _searchController.clear();
    return context.read<UserProvider>().fetchData(isRefresh: true, keyword: '');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Color(0xFF559260),
        elevation: 0,
        title: Text(
          'Daftar Keluarga',
          style: TextStyle(
            color: Config.white,
            fontSize: 20,
            fontWeight: Config.semiBold,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('treeVisual'),
        backgroundColor: Config.primary,
        label: Text(
          "Lihat pohon keluarga",
          style: TextStyle(
            color: Config.white,
            fontSize: 14,
            fontWeight: Config.semiBold,
          ),
        ),
        icon: Icon(Icons.account_tree, color: Config.white),
      ),
      body: Column(
        children: [
          _buildSearchPanel(),
          Expanded(
            child: Consumer2<UserProvider, AuthProvider>(
              builder: (context, provider, authProvider, child) {
                final authenticatedId =
                    authProvider.currentUser?.userId ??
                    provider.authenticatedMemberId;
                final visibleMembers = provider.directoryMembers
                    .where((member) => member.userId != authenticatedId)
                    .toList();

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
                if (provider.directoryMembers.isEmpty) {
                  return _buildPlaceholder(
                    icon: Icons.groups_outlined,
                    title: 'Data keluarga belum ditemukan',
                    message: provider.keyword.isEmpty
                        ? 'Belum ada anggota keluarga yang bisa ditampilkan.'
                        : 'Coba gunakan kata kunci lain yang lebih sederhana.',
                    actionLabel: provider.keyword.isEmpty
                        ? 'Muat Ulang'
                        : 'Tampilkan Semua',
                    onPressed: provider.keyword.isEmpty
                        ? _search
                        : _resetSearch,
                  );
                }
                if (visibleMembers.isEmpty) {
                  return _buildPlaceholder(
                    icon: Icons.groups_outlined,
                    title: 'Belum ada anggota lain untuk ditampilkan',
                    message:
                        'Data diri Anda tidak ditampilkan di daftar agar tidak membingungkan.',
                    actionLabel: 'Muat Ulang',
                    onPressed: _search,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchData(
                    isRefresh: true,
                    keyword: provider.keyword,
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: visibleMembers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == visibleMembers.length) {
                        return _buildListFooter(provider);
                      }
                      return _buildMemberCard(
                        member: visibleMembers[index],
                        provider: provider,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchPanel() {
    return Container(
      width: double.infinity,
      color: Config.white,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: 'Masukkan nama anggota keluarga',
              prefixIcon: Icon(Icons.search, color: Config.textSecondary),
              filled: true,
              fillColor: Config.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListFooter(UserProvider provider) {
    if (provider.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (provider.canLoadMore) {
      return const SizedBox(height: 24);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Center(
        child: Text(
          'Semua anggota keluarga sudah tampil.',
          style: TextStyle(color: Config.textSecondary),
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

  Widget _buildMemberCard({
    required FamilyDirectoryMember member,
    required UserProvider provider,
  }) {
    final memberId = member.userId;
    final marriages = memberId == null
        ? null
        : provider.marriagesForMember(memberId);
    final isLoading =
        memberId != null && provider.isLoadingMarriagesForMember(memberId);
    final error = memberId == null
        ? null
        : provider.marriageErrorForMember(memberId);

    if (memberId != null && marriages == null && !isLoading && error == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<UserProvider>().getMarriagesForMember(memberId);
        }
      });
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Config.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: memberId == null
            ? null
            : () => context.pushNamed(
                'memberInfo',
                pathParameters: {'memberId': memberId.toString()},
              ),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MemberAvatar(
                photoUrl: Config.getAvatarUrl(
                  avatar: member.avatar,
                  avatarUrl: member.avatarUrl,
                ),
                emoji: '👤',
                size: 54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.fullName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: Config.semiBold,
                        color: Config.textHead,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'NIT: ${member.nit.isEmpty ? '-' : member.nit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                    Text(
                      'Tahun lahir: ${member.birthYear ?? '-'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                    Text(
                      'Gender: ${member.gender?.label ?? 'Belum diisi'}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildFamilyStatus(
                      marriages: marriages,
                      isLoading: isLoading,
                      error: error,
                      onRetry: memberId == null
                          ? null
                          : () => provider.getMarriagesForMember(
                              memberId,
                              forceRefresh: true,
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

  Widget _buildFamilyStatus({
    required List<FamilyTreeMarriage>? marriages,
    required bool isLoading,
    required String? error,
    required VoidCallback? onRetry,
  }) {
    if (isLoading || (marriages == null && error == null)) {
      return Text(
        'Memuat status keluarga...',
        style: TextStyle(fontSize: 12, color: Config.textSecondary),
      );
    }
    if (error != null) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Data pernikahan gagal dimuat.',
              style: TextStyle(fontSize: 12, color: Colors.orange[800]),
            ),
          ),
          if (onRetry != null)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Coba lagi'),
            ),
        ],
      );
    }

    final spouseNames = marriages!
        .map((marriage) => marriage.spouse?.fullName)
        .whereType<String>()
        .where((name) => name.trim().isNotEmpty)
        .toList();
    final hasUnclassifiedMarriage = marriages.any(
      (marriage) => !marriage.isRoleClassified,
    );
    if (spouseNames.isEmpty) {
      return Text(
        'Belum berkeluarga',
        style: TextStyle(fontSize: 12, color: Config.textSecondary),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sudah berkeluarga',
          style: TextStyle(
            fontSize: 12,
            fontWeight: Config.semiBold,
            color: Config.primary,
          ),
        ),
        Text(
          'Pasangan: ${spouseNames.join(', ')}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12, color: Config.textSecondary),
        ),
        if (hasUnclassifiedMarriage)
          Text(
            'Status pasangan lama belum diklasifikasikan',
            style: TextStyle(fontSize: 12, color: Colors.orange[800]),
          ),
      ],
    );
  }
}
