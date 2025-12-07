import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';

class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  final ScrollController _scrollController = ScrollController();

  // Breadcrumb untuk navigasi folder
  final List<dynamic> _breadcrumbs = [];

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

  // --- LOGIKA NAVIGASI ---
  void _navigateToChild(dynamic item) {
    setState(() {
      _breadcrumbs.add(item);
    });
  }

  void _navigateBackTo(int index) {
    setState(() {
      int targetLength = index + 1;
      if (_breadcrumbs.length > targetLength) {
        _breadcrumbs.removeRange(targetLength, _breadcrumbs.length);
      }
    });
  }

  void _navigateToHome() {
    setState(() {
      _breadcrumbs.clear();
    });
  }

  Future<bool> _onWillPop() async {
    if (_breadcrumbs.isNotEmpty) {
      setState(() {
        _breadcrumbs.removeLast();
      });
      return false;
    }
    return true;
  }

  String _getShortName(dynamic item) {
    String fullName = "";
    if (item is FamilyUnit) fullName = item.headName;
    if (item is ChildMember) fullName = item.name;

    List<String> parts = fullName.split(' ');
    if (parts.length > 2) return "${parts[0]} ${parts[1]}...";
    return fullName;
  }

  // --- LOGIKA FAB (TOMBOL TAMBAH) ---
  void _handleFabPressed() {
    if (_breadcrumbs.isEmpty) {
      // 1. Jika di Root -> Tambah Keluarga Baru
      context.pushNamed('addFamily');
    } else {
      // 2. Jika di dalam Folder -> Tambah Anggota untuk Parent saat ini
      final currentParent = _breadcrumbs.last;
      int? parentId;
      String parentName = "";

      if (currentParent is FamilyUnit) {
        // Mengambil ID dan Nama dari FamilyUnit
        // Pastikan model FamilyUnit memiliki properti id/headId yang valid
        parentId = currentParent.headId;
        parentName = currentParent.headName;
      } else if (currentParent is ChildMember) {
        // Mengambil ID dan Nama dari ChildMember
        // Pastikan model ChildMember memiliki properti id yang valid
        parentId = currentParent.id;
        parentName = currentParent.name;
      }

      // Navigasi dengan membawa ID Parent
      // Jika parentId null (misal karena data error), berikan fallback atau handle error
      if (parentId != null) {
        context.pushNamed(
          'addFamilyMember',
          extra: {'parentId': parentId, 'parentName': parentName},
        );
      } else {
        // Tampilkan pesan error jika ID tidak ditemukan
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Gagal mengambil ID orang tua")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Config.background,
        appBar: AppBar(
          backgroundColor: Config.white,
          elevation: 0,
          leading: _breadcrumbs.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.arrow_back, color: Config.textHead),
                  onPressed: () => setState(() => _breadcrumbs.removeLast()),
                )
              : null,
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
            IconButton(
              icon: Icon(Icons.refresh, color: Config.textSecondary),
              onPressed: () =>
                  context.read<UserProvider>().fetchData(isRefresh: true),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Consumer<UserProvider>(
          builder: (context, provider, child) {
            if (provider.state == ViewState.loading &&
                provider.familyUnits.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            // Tentukan Data List berdasarkan Breadcrumb
            List<dynamic> currentList = [];
            if (_breadcrumbs.isEmpty) {
              currentList = provider.familyUnits;
            } else {
              final lastItem = _breadcrumbs.last;
              if (lastItem is FamilyUnit) currentList = lastItem.children;
              if (lastItem is ChildMember) {
                currentList = lastItem.children;
              }
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // === BREADCRUMB ===
                Container(
                  width: double.infinity,
                  color: Config.white,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: BreadCrumb(
                    items: [
                      BreadCrumbItem(
                        content: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // GANTI ICON FOLDER JADI ICON HOME ATAU KELUARGA
                            Icon(
                              Icons.other_houses_outlined,
                              size: 20,
                              color: _breadcrumbs.isEmpty
                                  ? Config.primary
                                  : Config.textSecondary,
                            ),
                          ],
                        ),
                        onTap: _breadcrumbs.isEmpty ? null : _navigateToHome,
                      ),
                      ...List.generate(_breadcrumbs.length, (index) {
                        final item = _breadcrumbs[index];
                        final isLast = index == _breadcrumbs.length - 1;
                        return BreadCrumbItem(
                          content: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // TAMBAHKAN ICON ORANG SEBELUM NAMA
                              if (!isLast)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4.0),
                                  child: Icon(
                                    Icons.person,
                                    size: 16,
                                    color: Config.textSecondary,
                                  ),
                                ),
                              Text(
                                _getShortName(item),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isLast
                                      ? Config.semiBold
                                      : Config.regular,
                                  color: isLast
                                      ? Config.primary
                                      : Config.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          onTap: isLast ? null : () => _navigateBackTo(index),
                        );
                      }),
                    ],
                    divider: Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: Config.textSecondary,
                    ),
                  ),
                ),

                // === LIST ===
                Expanded(
                  child: currentList.isEmpty
                      ? Center(
                          child: Text(
                            "Tidak ada data",
                            style: TextStyle(color: Config.textSecondary),
                          ),
                        )
                      : ListView.builder(
                          controller: _breadcrumbs.isEmpty
                              ? _scrollController
                              : null,
                          padding: const EdgeInsets.all(16),
                          itemCount: currentList.length,
                          itemBuilder: (context, index) =>
                              _buildListItem(currentList[index]),
                        ),
                ),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _handleFabPressed,
          backgroundColor: Config.primary,
          icon: const Icon(Icons.add, color: Config.white),
          // Label berubah dinamis agar user paham
          label: Text(
            _breadcrumbs.isEmpty ? "Buat Keluarga" : "Tambah Anggota",
            style: const TextStyle(
              color: Config.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildListItem(dynamic item) {
    String name = "";
    String spouse = "";
    bool isFolder = false;
    String? photoUrl;
    String emoji = "";

    if (item is FamilyUnit) {
      name = item.headName;
      spouse = item.spouseName ?? "";
      isFolder = item.children.isNotEmpty;
      emoji = "👨‍👩‍👧‍👦"; // Emoji keluarga untuk Family Unit
    } else if (item is ChildMember) {
      name = item.name;
      spouse = item.spouseName ?? "";
      isFolder = (item.children.isNotEmpty);
      photoUrl = item.photoUrl;
      emoji = item.emoji;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Config.textHead.withOpacity(0.05)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isFolder) {
            _navigateToChild(item); // Masuk Folder (Explore)
          } else {
            // Lihat Detail
            // context.pushNamed('memberInfo', extra: item);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: isFolder
                      ? Config.primary.withOpacity(0.1)
                      : Config.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: photoUrl != null
                    ? MemberAvatar(
                        photoUrl: photoUrl,
                        size: 45,
                        borderRadius: 10,
                      )
                    : Container(
                        width: 45,
                        height: 45,
                        alignment: Alignment.center,
                        child: Text(
                          emoji.isNotEmpty ? emoji : "👤",
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spouse.isNotEmpty ? "$name & $spouse" : name,
                      style: TextStyle(
                        fontWeight: Config.semiBold,
                        fontSize: 15,
                        color: Config.textHead,
                      ),
                    ),
                    if (isFolder)
                      Text(
                        "Klik untuk melihat turunan",
                        style: TextStyle(
                          fontSize: 12,
                          color: Config.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Config.textSecondary.withOpacity(0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
