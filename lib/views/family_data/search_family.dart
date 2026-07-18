import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/config/config.dart';
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
    await context.read<UserProvider>().fetchData(
      isRefresh: true,
      keyword: '',
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
          'Daftar Keluarga',
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
          Container(
            width: double.infinity,
            color: Config.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cari nama anggota keluarga yang ingin dilihat.',
                  style: TextStyle(
                    color: Config.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          hintText: 'Masukkan nama anggota keluarga',
                          prefixIcon: Icon(
                            Icons.search,
                            color: Config.textSecondary,
                          ),
                          filled: true,
                          fillColor: Config.background,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _search,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                        ),
                        child: const Text('Cari'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _resetSearch,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tampilkan Semua Keluarga'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Config.primary,
                    side: const BorderSide(color: Config.primary),
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

                if (provider.directoryMembers.isEmpty) {
                  return _buildPlaceholder(
                    icon: Icons.groups_outlined,
                    title: 'Data keluarga belum ditemukan',
                    message:
                        provider.keyword.isEmpty
                            ? 'Belum ada anggota keluarga yang bisa ditampilkan.'
                            : 'Coba gunakan kata kunci lain yang lebih sederhana.',
                    actionLabel: provider.keyword.isEmpty
                        ? 'Muat Ulang'
                        : 'Tampilkan Semua',
                    onPressed: provider.keyword.isEmpty ? _search : _resetSearch,
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
                    padding: const EdgeInsets.all(16),
                    itemCount: provider.directoryMembers.length + 1,
                    itemBuilder: (context, index) {
                      if (index == provider.directoryMembers.length) {
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
                          padding: const EdgeInsets.symmetric(
                            vertical: 18,
                            horizontal: 8,
                          ),
                          child: Center(
                            child: Text(
                              provider.directoryMembers.length < provider.perPage
                                  ? 'Semua anggota keluarga sudah tampil.'
                                  : 'Tidak ada data tambahan lagi.',
                              style: TextStyle(color: Config.textSecondary),
                            ),
                          ),
                        );
                      }

                      final member = provider.directoryMembers[index];
                      return _buildMemberCard(member);
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
            ElevatedButton(
              onPressed: onPressed,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberCard(dynamic member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: Config.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          final childMember = ChildMember(
            id: member.userId,
            nit: member.nit.isNotEmpty ? member.nit : member.familyTreeId,
            name: member.fullName,
            spouseName: null,
            location: member.address ?? '-',
            emoji: '👤',
            children: const [],
            photoUrl: Config.getFullImageUrl(member.avatarUrl ?? member.avatar),
            birthYear: member.birthYear,
          );

          context.pushNamed('memberInfo', extra: childMember);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              MemberAvatar(
                photoUrl: Config.getFullImageUrl(member.avatarUrl ?? member.avatar),
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
                    const SizedBox(height: 2),
                    Text(
                      'Tingkat keluarga: ${member.level}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Config.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tahun lahir: ${member.birthYear ?? '-'}',
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
