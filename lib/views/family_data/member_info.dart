import 'package:family_tree_app/components/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MemberInfoPage extends StatelessWidget {
  const MemberInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang body utama (abu-abu muda)
      backgroundColor: const Color(0xFFF7F7F7),

      // === AppBar ===
      appBar: _buildAppBar(context),

      // === Body Halaman (Detail Anggota) ===
      body: _buildBody(),
    );
  }

  // --- Widget untuk AppBar ---
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      // Latar belakang AppBar putih
      backgroundColor: Colors.white,
      elevation: 0,
      // Tombol Kembali
      leading: CustomBackButton(
        onPressed: () {
          context.go('/family-info');
        },
      ),
      // Judul Halaman
      title: const Text(
        "Detail Anggota",
        style: TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      // Ikon Aksi (Edit)
      actions: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.black87, size: 24),
          onPressed: () {
            context.goNamed('editFamilyMember');
          },
          tooltip: 'Edit Anggota',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- Widget untuk Body Halaman ---
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Bagian Header Profil
          _buildProfileHeader(),
          const SizedBox(height: 24),

          // 2. Bagian Info Detail
          _buildInfoSection(),
          const SizedBox(height: 24),

          // 3. Bagian Hubungan
          _buildHubunganSection(),
        ],
      ),
    );
  }

  // --- Widget untuk Header Profil ---
  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          // Placeholder Foto
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            child: Icon(Icons.person, size: 60, color: Colors.grey[600]),
            // Anda bisa ganti dengan:
            // backgroundImage: NetworkImage('URL_FOTO'),
          ),
          const SizedBox(height: 12),
          // Nama
          const Text(
            "Topan Namas",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          // Peran/Status
          const Text(
            "Ayah",
            style: TextStyle(
              fontSize: 15,
              color: Color(0xFF4AB97A), // Warna hijau aksen
            ),
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
        // Baris Nama & Tanggal Lahir
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

        // Info Jenis Kelamin
        _buildInfoCard(title: "Jenis Kelamin", value: "Laki - Laki"),
        const SizedBox(height: 12),

        // Info NIK
        _buildInfoCard(title: "NIK", value: "320918xxxx8923323"),
        const SizedBox(height: 12),

        // Info Catatan Singkat
        _buildInfoCard(
          title: "Catatan Singkat",
          value: "Ayah adalah seorang yang hebat tiada tara, selalu berjuang.",
        ),
      ],
    );
  }

  // --- Widget untuk Bagian Hubungan ---
  Widget _buildHubunganSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Judul "Hubungan"
        const Text(
          "Hubungan",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // Card Hubungan 1
        _buildMemberCard(
          name: "Sinta Suke",
          role: "Ibu Rumah Tangga",
          onTap: () {
            // Aksi tap ke detail Sinta Suke
          },
        ),

        // Card Hubungan 2
        _buildMemberCard(
          name: "Tomas Alfa Edisound",
          role: "Anak Ke 1",
          onTap: () {
            // Aksi tap ke detail Tomas
          },
        ),
      ],
    );
  }

  // --- Widget Kustom untuk Card Info (Nama, NIK, dll) ---
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
          // Judul (misal: "Nama Lengkap")
          Text(title, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          const SizedBox(height: 4),
          // Isi (misal: "Topan Namas")
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

  // --- Widget Kustom untuk Card Anggota Keluarga (REUSED) ---
  Widget _buildMemberCard({
    required String name,
    required String role,
    VoidCallback? onTap,
  }) {
    return Card(
      color: Colors.white,
      elevation: 0.5,
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Placeholder Foto
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              const SizedBox(width: 16),
              // Nama dan Peran
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              // Ikon Panah
              Icon(Icons.chevron_right, color: Colors.grey[600], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}
