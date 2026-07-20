import 'package:family_tree_app/config/app_environment.dart';
import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/core/app_lifecycle_handler.dart';
import 'package:family_tree_app/core/session_storage.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/tree_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:family_tree_app/data/repository/auth_repository.dart';
import 'package:family_tree_app/data/repository/user_repository.dart';
import 'package:family_tree_app/views/auth/login.dart';
import 'package:family_tree_app/views/family_data/family_info.dart';
import 'package:family_tree_app/views/family_data/member_info.dart';
import 'package:family_tree_app/views/family_data/search_family.dart';
import 'package:family_tree_app/views/family_data/tree_visual.dart';
import 'package:family_tree_app/views/family_data/forms/add_family.dart';
import 'package:family_tree_app/views/family_data/forms/add_family_member.dart';
import 'package:family_tree_app/views/family_data/forms/edit_family_member.dart';
import 'package:family_tree_app/views/home.dart';
import 'package:family_tree_app/views/profile/profile.dart';
import 'package:family_tree_app/views/profile/profile_edit.dart';
import 'package:family_tree_app/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _navigateToPage(index, context),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: 'Beranda',
            backgroundColor: Colors.grey[100],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.groups_outlined),
            activeIcon: const Icon(Icons.groups),
            label: 'Keluarga',
            backgroundColor: Colors.grey[100],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            activeIcon: const Icon(Icons.account_circle),
            label: 'Profil',
            backgroundColor: Colors.grey[100],
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) {
      return 0;
    }
    if (location.startsWith('/family') ||
        location.startsWith('/member') ||
        location.startsWith('/edit-family-member') ||
        location.startsWith('/add-family') ||
        location.startsWith('/tree-visual')) {
      return 1;
    }
    if (location.startsWith('/profile')) {
      return 2;
    }
    return 0;
  }

  void _navigateToPage(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('home');
        break;
      case 1:
        context.goNamed('familySearch');
        break;
      case 2:
        context.goNamed('profile');
        break;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final Config _config = Config();
  final AuthProvider _authProvider = AuthProvider(AuthRepository(), SessionStorage());
  final UserProvider _userProvider = UserProvider(UserRepositoryImpl());
  final TreeProvider _treeProvider = TreeProvider(UserRepositoryImpl());

  late final GoRouter _router = GoRouter(
    initialLocation: '/',
    refreshListenable: _authProvider,
    redirect: (context, state) {
      final status = _authProvider.status;
      final location = state.matchedLocation;
      final isAtSplash = location == '/';
      final isAtLogin = location == '/login';

      if (status == AuthStatus.initializing) {
        return isAtSplash ? null : '/';
      }

      if (_authProvider.isAuthenticated) {
        if (isAtSplash || isAtLogin) {
          return '/home';
        }
        return null;
      }

      if (isAtSplash) {
        return '/login';
      }

      return isAtLogin ? null : '/login';
    },
    routes: [
      GoRoute(path: '/', name: 'splashScreen', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', name: 'login', builder: (context, state) => const LoginPage()),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          GoRoute(path: '/home', name: 'home', builder: (context, state) => const HomePage()),
          GoRoute(path: '/family-list', name: 'familyList', builder: (context, state) => const SearchFamilyPage()),
          GoRoute(path: '/family-search', name: 'familySearch', builder: (context, state) => const SearchFamilyPage()),
          GoRoute(path: '/add-family', name: 'addFamily', builder: (context, state) => const AddFamilyPage()),
          GoRoute(
            path: '/family-info',
            name: 'familyInfo',
            builder: (context, state) {
              final args = state.extra as Map<String, dynamic>;
              return FamilyInfoPage(parentId: args['parentId'] as int?, initialHeadName: args['headName'] as String?);
            },
          ),
          GoRoute(
            path: '/member-info',
            name: 'memberInfo',
            builder: (context, state) {
              final member = state.extra as ChildMember;
              return MemberInfoPage(member: member);
            },
            routes: [
              GoRoute(
                path: 'add',
                name: 'addFamilyMember',
                builder: (context, state) {
                  final extra = state.extra;
                  int? parentId;
                  String? parentName;

                  if (extra is int) {
                    parentId = extra;
                  } else if (extra is Map) {
                    parentId = extra['parentId'] as int?;
                    parentName = extra['parentName'] as String?;
                  }

                  return AddFamilyMemberPage(parentId: parentId, parentName: parentName);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/edit-family-member',
            name: 'editFamilyMember',
            builder: (context, state) {
              final member = state.extra as ChildMember;
              return EditFamilyMemberPage(member: member);
            },
          ),
          GoRoute(path: '/tree-visual', name: 'treeVisual', builder: (context, state) => const TreeVisualPage()),
          GoRoute(path: '/profile', name: 'profile', builder: (context, state) => const ProfilePage()),
          GoRoute(path: '/profile-edit', name: 'profileEdit', builder: (context, state) => const ProfileEditPage()),
        ],
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),
        ChangeNotifierProvider<UserProvider>.value(value: _userProvider),
        ChangeNotifierProvider<TreeProvider>.value(value: _treeProvider),
      ],
      child: Builder(
        builder: (context) {
          return AppLifecycleHandler(
            onResume: () {
              if (context.read<AuthProvider>().isAuthenticated) {
                context.read<UserProvider>().silentRefresh();
              }
            },
            child: MaterialApp.router(
              title: AppEnvironment.appName,
              debugShowCheckedModeBanner: false,
              theme: _config.lightTheme,
              restorationScopeId: 'app',
              routerConfig: _router,
            ),
          );
        },
      ),
    );
  }
}
