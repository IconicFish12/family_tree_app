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

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

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
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: '/family',
          routes: [
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
                  path: '/add-family-member',
                  name: 'addFamilyMember',
                  builder: (context, state) => const AddFamilyMemberPage(),
                ),
                GoRoute(
                  path: '/edit-family-member',
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
          ],
        ),
        GoRoute(
          path: '/user',
          routes: [
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
      restorationScopeId: 'app',
      routerConfig: router,
    );
  }
}
