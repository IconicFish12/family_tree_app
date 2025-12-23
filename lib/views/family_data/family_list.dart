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

  String _getShortName(dynamic item) {
    String fullName = "";
    if (item is FamilyUnit) fullName = item.headName;
    if (item is ChildMember) fullName = item.name;

    List<String> parts = fullName.split(' ');
    if (parts.length > 2) return "${parts[0]} ${parts[1]}...";
    return fullName;
  }

  void _handleFabPressed() {
    if (_breadcrumbs.isEmpty) {
      context.pushNamed('treeVisual');
      return;
    }

    final currentParent = _breadcrumbs.last;
    int? parentId;
    String parentName = "";

    if (currentParent is FamilyUnit) {
      parentId = currentParent.headId;
      parentName = currentParent.headName;
    } else if (currentParent is ChildMember) {
      parentId = currentParent.id;
      parentName = currentParent.name;
    }

    if (parentId != null) {
      context.pushNamed(
        'addFamilyMember',
        extra: {'parentId': parentId, 'parentName': parentName},
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Gagal mengambil ID orang tua. Tidak bisa menambah anggota di sini.",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _breadcrumbs.isEmpty,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _breadcrumbs.isNotEmpty) {
          setState(() => _breadcrumbs.removeLast());
        }
      },
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

            List<dynamic> currentList = [];
            if (_breadcrumbs.isEmpty) {
              currentList = provider.familyUnits;
            } else {
              final lastItem = _breadcrumbs.last;
              if (lastItem is FamilyUnit) currentList = lastItem.children;
              if (lastItem is ChildMember) currentList = lastItem.children;
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () =>
                        context.read<UserProvider>().fetchData(isRefresh: true),
                    color: Config.primary,
                    child: currentList.isEmpty
                        ? ListView(
                            // ListView diperlukan agar RefreshIndicator bisa bekerja
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.5,
                                child: Center(
                                  child: Text(
                                    "Tidak ada data\nTarik ke bawah untuk refresh",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Config.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            controller: _breadcrumbs.isEmpty
                                ? _scrollController
                                : null,
                            padding: const EdgeInsets.all(16),
                            itemCount: currentList.length,
                            itemBuilder: (context, index) =>
                                _buildListItem(currentList[index]),
                          ),
                  ),
                ),
              ],
            );
          },
        ),

        // --- UPDATE FAB SESUAI PERMINTAAN ---
        floatingActionButton: FloatingActionButton.extended(
          onPressed: _handleFabPressed,
          backgroundColor: _breadcrumbs.isEmpty
              ? Config.accent
              : Config.primary, // Beda warna biar jelas
          icon: Icon(
            _breadcrumbs.isEmpty ? Icons.account_tree : Icons.person_add,
            color: Config.white,
          ),
          label: Text(
            _breadcrumbs.isEmpty ? "Visualisasi Tree" : "Tambah Anggota",
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
      emoji = "👨‍👩‍👧‍👦";
      photoUrl = item.avatar;
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
        side: BorderSide(color: Config.textHead.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: isFolder
                ? Config.primary.withValues(alpha: 0.1)
                : Config.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: MemberAvatar(
            photoUrl: Config.getFullImageUrl(photoUrl),
            emoji: emoji.isNotEmpty ? emoji : "👤",
            size: 44,
            borderRadius: 8,
          ),
        ),
        title: Text(
          spouse.isNotEmpty ? "$name & $spouse" : name,
          style: TextStyle(
            fontWeight: Config.semiBold,
            fontSize: 15,
            color: Config.textHead,
          ),
        ),
        subtitle: isFolder
            ? Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  "Lihat Turunan Keluarga $name",
                  style: TextStyle(
                    fontSize: 12,
                    color: Config.primary,
                    overflow: TextOverflow.fade,
                  ),
                ),
              )
            : null,
        onTap: () {
          ChildMember memberData;
          if (item is FamilyUnit) {
            memberData = ChildMember(
              id: item.headId,
              nit: item.nit,
              name: item.headName,
              spouseName: item.spouseName,
              location: item.location,
              children: item.children,
              photoUrl: item.avatar,
              birthYear: item.birthYear,
              emoji: "👨",
            );
          } else if (item is ChildMember) {
            memberData = item;
          } else {
            return;
          }
          context.pushNamed('memberInfo', extra: memberData);
        },
        trailing: isFolder
            ? IconButton(
                onPressed: () => _navigateToChild(item),
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Config.textSecondary,
                ),
                tooltip: "Buka Folder",
              )
            : Icon(
                Icons.info_outline,
                size: 20,
                color: Config.textSecondary.withValues(alpha: 0.5),
              ),
      ),
    );
  }
}
