import 'package:family_tree_app/components/ui.dart';
import 'package:family_tree_app/data/models/helper_member.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MemberInfoPage extends StatelessWidget {
  final ChildMember member; // Menerima data member

  const MemberInfoPage({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: _buildAppBar(context),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: CustomBackButton(
        onPressed: () {
          context.pop();
        },
      ),
      title: const Text(
        "Detail Anggota",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.black87, size: 24),
          onPressed: () {
            context.pushNamed('editFamilyMember', extra: member); // Pass member to edit
          },
          tooltip: 'Edit Anggota',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 24),
          _buildInfoSection(),
          const SizedBox(height: 24),
          // _buildHubunganSection(), // Bisa diaktifkan jika data relasi lengkap
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: member.photoUrl != null 
                ? NetworkImage(member.photoUrl!) 
                : null,
            child: member.photoUrl == null
                ? Text(member.emoji, style: const TextStyle(fontSize: 40))
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            member.name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            member.nit, // Menampilkan ID/NIT
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF4AB97A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildInfoCard(
          title: "Nama Lengkap",
          value: member.name,
        ),
        const SizedBox(height: 12),
        _buildInfoCard(
          title: "Lokasi / Alamat",
          value: member.location.toString(),
        ),
        const SizedBox(height: 12),
        if (member.spouseName != null)
          _buildInfoCard(
            title: "Pasangan",
            value: member.spouseName!,
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
            color: Colors.grey.withOpacity(0.1),
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