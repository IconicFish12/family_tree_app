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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileHeader(user),
          const SizedBox(height: 24),
          _buildInfoSection(user),
          const SizedBox(height: 14),
          _buildKeyValueCard(label: 'NIT', value: user.nit?.trim().isNotEmpty == true ? user.nit! : '-'),
          const SizedBox(height: 14),
          _buildNoteCard(
            title: 'Tempat Tinggal',
            content: user.address?.trim().isNotEmpty == true ? user.address! : 'Belum ada data tempat tinggal.',
          ),
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
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade300,
              image: photoUrl == null ? null : DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover),
            ),
            child: photoUrl == null ? Icon(Icons.person, size: 54, color: Colors.grey.shade500) : null,
          ),
          const SizedBox(height: 12),
          Text(
            user.fullName ?? 'Tanpa Nama',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Text(
            user.parentId == null ? 'Kepala Keluarga' : 'Anggota Keluarga',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Config.primary),
          ),
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
              child: _buildSmallInfoCard(
                title: 'Nama Lengkap',
                value: user.fullName?.trim().isNotEmpty == true ? user.fullName! : '-',
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildSmallInfoCard(
                title: 'Tahun Lahir',
                value: user.birthYear?.trim().isNotEmpty == true ? user.birthYear! : '-',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallInfoCard({required String title, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Config.textHead),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyValueCard({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Config.textHead),
          ),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Config.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({required String title, required String content}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Config.textHead),
          ),
          const SizedBox(height: 6),
          Text(content, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, height: 1.4)),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Config.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))],
    );
  }
}
