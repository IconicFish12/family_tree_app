import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/views/profile/profile_edit.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

      // === AppBar ===
      appBar: _buildAppBar(context),

      // === Body Halaman (Detail Profile) ===
      body: _buildBody(context),
    );
  }

  // --- Widget untuk AppBar ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false, // Menyembunyikan tombol back
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
        // Tombol Edit
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.black87),
          tooltip: "Edit Profile",
          onPressed: () {
            // Navigasi ke Halaman Edit Profile
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

  // --- Widget untuk Body Halaman ---
  Widget _buildBody(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Profil
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // 2. Info Detail
          _buildInfoSection(),
          const SizedBox(height: 32),

          // 3. Tombol Logout
          ElevatedButton(
            onPressed: () {
              // Aksi untuk logout
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50), // Warna hijau
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
          const SizedBox(height: 20), // Padding di bawah tombol
        ],
      ),
    );
  }

  // --- Widget untuk Header Profil ---
  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          const Text(
            "Topan Namas",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // Status atau email
          Text(
            "topan.namas@email.com", // Ganti dengan data user
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  // --- Widget untuk Bagian Info Detail ---
  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(
                title: "Nama Lengkap",
                value: "Topan Namas",
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(
                title: "Tanggal Lahir",
                value: "30 - Desember - 2012",
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildInfoCard(title: "Jenis Kelamin", value: "Laki - Laki"),
        const SizedBox(height: 12),
        _buildInfoCard(title: "NIK", value: "320918xxxx8923323"),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: "Catatan Singkat",
          value: "Ayah adalah seorang yang hebat tiada tara, selalu berjuang.",
        ),
      ],
    );
  }

  // --- Widget Kustom untuk Card Info (REUSED) ---
  Widget _buildInfoCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
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
