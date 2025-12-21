import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/views/profile/profile_edit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _buildAppBar(context),
      
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Data profil tidak ditemukan"),
                  ElevatedButton(
                    onPressed: () => context.go('/login'),
                    child: const Text("Login Ulang"),
                  ),
                ],
              ),
            );
          }
          return _buildBody(context, user); 
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: const Text(
        "Profile",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.black87),
          tooltip: "Edit Profile",
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileEditPage()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody(BuildContext context, dynamic user) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildInfoSection(user),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () {
              // context.read<AuthProvider>().logout();

              context.go('/login'); 
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 2,
            ),
            child: const Text(
              "Logout",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(dynamic user) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: user.avatar != null
                ? NetworkImage("${Config.imageUrl}/${user.avatar.toString()}")
                : null,
            child: user.avatar == null
                ? Icon(Icons.person, size: 60, color: Colors.grey[600])
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName ?? "Tanpa Nama",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "ID Keluarga: ${user.familyTreeId}",
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(dynamic user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: "Nama Lengkap",
                value: user.fullName ?? "-",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                title: "Tahun Lahir",
                value: user.birthYear?.toString() ?? "-", 
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(title: "Alamat", value: user.address ?? "-"),
        const SizedBox(height: 12),

        _buildInfoCard(
          title: "Terdaftar Sejak",
          value: user.createdAt.toLocal().toString().split(' ')[0] 
        ),
      ],
    );
  }

  Widget _buildInfoCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(
              0.1,
            ),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
