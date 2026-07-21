import 'package:family_tree_app/config/config.dart';
import 'package:family_tree_app/data/models/user_data.dart';
import 'package:family_tree_app/data/provider/auth_provider.dart';
import 'package:family_tree_app/data/provider/user_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Config.background,
      appBar: AppBar(
        backgroundColor: Color(0xFF559260),
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.white),
            tooltip: 'Edit Profil',
            onPressed: () => context.pushNamed('profileEdit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final user = authProvider.currentUser;
          if (user == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Data profil tidak ditemukan.'),
                  ElevatedButton(onPressed: () => context.go('/login'), child: const Text('Login Ulang')),
                ],
              ),
            );
          }
          return _buildBody(context, user);
        },
      ),
    );
  }

  Widget _buildBody(BuildContext context, UserData user) {
    final photoUrl = user.avatar is String
        ? Config.getFullImageUrl(user.avatar as String)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildInfoSection(user),
          const SizedBox(height: 24),
          Text(
            'Unduh Data Keluarga',
            style: TextStyle(fontSize: 17, fontWeight: Config.semiBold, color: Config.textHead),
          ),
          const SizedBox(height: 6),
          Text('Simpan daftar keluarga dalam bentuk dokumen Excel.', style: TextStyle(color: Config.textSecondary)),
          const SizedBox(height: 12),
          Consumer<UserProvider>(
            builder: (context, provider, child) {
              return OutlinedButton.icon(
                onPressed: provider.isExporting ? null : () => _downloadExcel(context),
                icon: provider.isExporting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.download_outlined),
                label: Text(provider.isExporting ? 'Menyiapkan dokumen...' : 'Unduh Excel'),
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await context.read<AuthProvider>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
            ),
            child: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserData user) {
    final photoUrl = user.avatar is String ? Config.getFullImageUrl(user.avatar as String) : null;

    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey[300],
            backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
            child: photoUrl == null ? Icon(Icons.person, size: 60, color: Colors.grey[600]) : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName ?? 'Tanpa Nama',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text('NIT: ${user.nit ?? '-'}', style: TextStyle(fontSize: 15, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Future<void> _downloadExcel(BuildContext context) async {
    final provider = context.read<UserProvider>();
    final file = await provider.exportFamily();
    if (!context.mounted) return;

    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.errorMessage ?? 'Dokumen Excel belum dapat diunduh.'), backgroundColor: Colors.red),
      );
      return;
    }

    try {
      final savedPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Simpan data keluarga',
        fileName: file.fileName,
        type: FileType.custom,
        allowedExtensions: const ['xlsx'],
        bytes: file.bytes,
      );
      if (!context.mounted) return;

      if (kIsWeb || savedPath != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dokumen Excel berhasil diunduh.'), backgroundColor: Config.primary));
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dokumen belum dapat disimpan. Silakan coba lagi.'), backgroundColor: Colors.red),
      );
    }
  }

  Widget _buildInfoSection(UserData user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildInfoCard(title: 'Nama Lengkap', value: user.fullName ?? '-'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildInfoCard(title: 'Tahun Lahir', value: user.birthYear?.toString() ?? '-'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Config.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.grey.withValues(alpha: 0.1), spreadRadius: 1, blurRadius: 3, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
