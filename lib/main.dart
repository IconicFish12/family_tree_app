import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/views/auth/login.dart';
import 'package:family_tree_app/views/family_data/family_info.dart';
import 'package:family_tree_app/views/family_data/family_list.dart';
import 'package:family_tree_app/views/family_data/forms/add_family_member.dart';
import 'package:family_tree_app/views/family_data/forms/update_family_member.dart';
import 'package:family_tree_app/views/family_data/member_info.dart';
import 'package:family_tree_app/views/family_data/search_family.dart';
import 'package:family_tree_app/views/family_data/tree_visual.dart';
import 'package:family_tree_app/views/home.dart';
import 'package:family_tree_app/views/profile/profile.dart';
import 'package:family_tree_app/views/profile/profile_edit.dart';
import 'package:family_tree_app/views/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    int selectedIndex = _getSelectedIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          _navigateToPage(index, context);
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: 'Beranda',
            backgroundColor: Colors.grey[100],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.search),
            label: 'Pencarian',
            backgroundColor: Colors.grey[100],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.people),
            label: 'Keluarga',
            backgroundColor: Colors.grey[100],
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.settings),
            label: 'Pengaturan',
            backgroundColor: Colors.grey[100],
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/home')) {
      return 0;
    } else if (location.startsWith('/family-search')) {
      return 1;
    } else if (location.startsWith('/family-list') ||
        location.startsWith('/member-info') ||
        location.startsWith('/family-info') ||
        location.startsWith('/tree-visual')) {
      return 2;
    } else if (location.startsWith('/profile')) {
      return 3;
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
        context.goNamed('familyList');
        break;
      case 3:
        context.goNamed('profile');
        break;
    }
  }
}

// Helper function untuk cek apakah bisa pop/back
bool canGoBack(BuildContext context) {
  return Navigator.of(context).canPop();
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final config = Config();

    final router = GoRouter(
      restorationScopeId: 'router',
      routerNeglect: true,
      routes: [
        GoRoute(
          path: '/',
          name: 'splashScreen',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return MainNavigationShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomePage(),
            ),
            GoRoute(
              path: '/family-list',
              name: 'familyList',
              builder: (context, state) => const FamilyListPage(),
            ),
            GoRoute(
              path: '/family-info',
              name: 'familyInfo',
              builder: (context, state) => const FamilyInfoPage(),
            ),
            GoRoute(
              path: '/member-info',
              name: 'memberInfo',
              builder: (context, state) => const MemberInfoPage(),
              routes: [
                GoRoute(
                  path: 'add-family-member',
                  name: 'addFamilyMember',
                  builder: (context, state) => const AddFamilyMemberPage(),
                ),
                GoRoute(
                  path: 'edit-family-member',
                  name: 'editFamilyMember',
                  builder: (context, state) => const UpdateFamilyMemberPage(),
                ),
              ],
            ),
            GoRoute(
              path: '/family-search',
              name: 'familySearch',
              builder: (context, state) => const SearchFamilyPage(),
            ),
            GoRoute(
              path: '/tree-visual',
              name: 'treeVisual',
              builder: (context, state) => const TreeVisualPage(),
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
            GoRoute(
              path: '/profile-edit',
              name: 'profileEdit',
              builder: (context, state) => const ProfileEditPage(),
            ),
          ],
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: config.lightTheme,
      restorationScopeId: 'app',
      routerConfig: router,
    );
    // return MaterialApp(
    //   title: 'Flutter Demo',
    //   debugShowCheckedModeBanner: false,
    //   theme: config.lightTheme,
    //   home: const TreeVisualPage(),
    // );
  }
}
