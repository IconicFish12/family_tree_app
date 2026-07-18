import 'package:family_tree_app/components/member_avatar.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/provider/family_list_navigation_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_breadcrumb/flutter_breadcrumb.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class FamilyListPage extends StatefulWidget {
  const FamilyListPage({super.key});

  @override
  State<FamilyListPage> createState() => _FamilyListPageState();
}

class _FamilyListPageState extends State<FamilyListPage> {
  final ScrollController _scrollController = ScrollController();
  final FamilyListNavigationProvider _navigationProvider =
      FamilyListNavigationProvider();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().fetchData(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _navigationProvider.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<UserProvider>().fetchData(isRefresh: false);
    }
  }

  String _getShortName(Object item) {
    var fullName = '';
    if (item is FamilyUnit) fullName = item.headName;
    if (item is ChildMember) fullName = item.name;

    final parts = fullName.split(' ');
    if (parts.length > 2) return '${parts[0]} ${parts[1]}...';
    return fullName;
  }

  void _handleFabPressed(FamilyListNavigationProvider navigation) {
    if (navigation.isAtRoot) {
      context.pushNamed('treeVisual');
      return;
    }

    final parentId = navigation.resolveCurrentParentId();
    final parentName = navigation.resolveCurrentParentName();

    if (parentId != null) {
      context.pushNamed(
        'addFamilyMember',
        extra: {'parentId': parentId, 'parentName': parentName},
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Gagal mengambil ID orang tua. Tidak bisa menambah anggota di sini.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<FamilyListNavigationProvider>.value(
      value: _navigationProvider,
      child: Consumer2<UserProvider, FamilyListNavigationProvider>(
        builder: (context, userProvider, navigation, child) {
          final breadcrumbs = navigation.breadcrumbs;

          return PopScope(
            canPop: navigation.isAtRoot,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && !navigation.isAtRoot) {
                navigation.navigateBack();
              }
            },
            child: Scaffold(
              backgroundColor: Config.background,
              appBar: AppBar(
                backgroundColor: Config.white,
                elevation: 0,
                leading: !navigation.isAtRoot
                    ? IconButton(
                        icon: Icon(Icons.arrow_back, color: Config.textHead),
                        onPressed: navigation.navigateBack,
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
              body: _buildBody(userProvider, navigation, breadcrumbs),
              floatingActionButton: FloatingActionButton.extended(
                onPressed: () => _handleFabPressed(navigation),
                backgroundColor: navigation.isAtRoot
                    ? Config.accent
                    : Config.primary,
                icon: Icon(
                  navigation.isAtRoot ? Icons.account_tree : Icons.person_add,
                  color: Config.white,
                ),
                label: Text(
                  navigation.isAtRoot ? 'Visualisasi Tree' : 'Tambah Anggota',
                  style: const TextStyle(
                    color: Config.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody(
    UserProvider provider,
    FamilyListNavigationProvider navigation,
    List<Object> breadcrumbs,
  ) {
    if (provider.state == ViewState.loading && provider.familyUnits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final currentList = navigation.resolveCurrentList(provider.familyUnits);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Config.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: BreadCrumb(
            items: [
              BreadCrumbItem(
                content: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.other_houses_outlined,
                      size: 20,
                      color: navigation.isAtRoot
                          ? Config.primary
                          : Config.textSecondary,
                    ),
                  ],
                ),
                onTap: navigation.isAtRoot ? null : navigation.navigateHome,
              ),
              ...List.generate(breadcrumbs.length, (index) {
                final item = breadcrumbs[index];
                final isLast = index == breadcrumbs.length - 1;
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
                          color: isLast ? Config.primary : Config.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  onTap: isLast ? null : () => navigation.navigateBackTo(index),
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
            onRefresh: () => context.read<UserProvider>().fetchData(
              isRefresh: true,
            ),
            color: Config.primary,
            child: currentList.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.5,
                        child: Center(
                          child: Text(
                            'Tidak ada data\nTarik ke bawah untuk refresh',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Config.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    controller: navigation.isAtRoot ? _scrollController : null,
                    padding: const EdgeInsets.all(16),
                    itemCount: currentList.length,
                    itemBuilder: (context, index) => _buildListItem(
                      currentList[index],
                      navigation,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(
    dynamic item,
    FamilyListNavigationProvider navigation,
  ) {
    var name = '';
    var spouse = '';
    var isFolder = false;
    String? photoUrl;
    var emoji = '';

    if (item is FamilyUnit) {
      name = item.headName;
      spouse = item.spouseName ?? '';
      isFolder = item.children.isNotEmpty;
      emoji = 'Keluarga';
      photoUrl = item.avatar;
    } else if (item is ChildMember) {
      name = item.name;
      spouse = item.spouseName ?? '';
      isFolder = item.children.isNotEmpty;
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
            emoji: emoji.isNotEmpty ? emoji : 'Anggota',
            size: 44,
            borderRadius: 8,
          ),
        ),
        title: Text(
          spouse.isNotEmpty ? '$name & $spouse' : name,
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
                  'Lihat Turunan Keluarga $name',
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
              emoji: 'Anggota',
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
                onPressed: () => navigation.navigateTo(item as Object),
                icon: Icon(
                  Icons.arrow_forward_ios,
                  size: 18,
                  color: Config.textSecondary,
                ),
                tooltip: 'Buka Folder',
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
