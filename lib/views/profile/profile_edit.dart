import 'package:flutter/material.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  // Controller untuk text fields
  final _namaController = TextEditingController(text: "Topan Namas");
  final _ttlController = TextEditingController(text: "30 - Desember - 2012");
  final _alamatController = TextEditingController();
  final _deskripsiController = TextEditingController(
    text: "Ayah adalah seorang yang hebat tiada tara, selalu berjuang.",
  );

  // Nilai terpilih untuk dropdown
  String? _hubunganKeluarga;
  String? _jenisKelamin = "Laki - Laki";

  @override
  void dispose() {
    _namaController.dispose();
    _ttlController.dispose();
    _alamatController.dispose();
    _deskripsiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Edit Profile",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Bagian Foto Profil
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Tombol Ganti Foto
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildUploadButton(
                        text: "Galeri",
                        icon: Icons.photo_library_outlined,
                        onPressed: () {
                          // Aksi pilih dari galeri
                        },
                      ),
                      const SizedBox(width: 12),
                      _buildUploadButton(
                        text: "Kamera",
                        icon: Icons.camera_alt_outlined,
                        onPressed: () {
                          // Aksi ambil foto dari kamera
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Form Input
            _buildTextField(
              controller: _namaController,
              label: "Nama Lengkap",
              hint: "Masukan nama lengkap",
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: "Hubungan Keluarga",
              hint: "Pilih hubungan keluarga",
              value: _hubunganKeluarga,
              items: ["Ayah", "Ibu", "Anak", "Suami", "Istri"],
              onChanged: (val) {
                setState(() => _hubunganKeluarga = val);
              },
            ),
            const SizedBox(height: 16),
            _buildDropdownField(
              label: "Jenis Kelamin",
              hint: "Pilih jenis kelamin",
              value: _jenisKelamin,
              items: ["Laki - Laki", "Perempuan"],
              onChanged: (val) {
                setState(() => _jenisKelamin = val);
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _ttlController,
              label: "Tempat, Tanggal Lahir",
              hint: "Contoh: Jakarta, 17 Agustus 1945",
              icon: Icons.calendar_month_outlined,
              onTap: () {
                // Aksi untuk memunculkan date picker
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _alamatController,
              label: "Alamat Tempat Tinggal",
              hint: "Masukan alamat lengkap",
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _deskripsiController,
              label: "Deskripsi Pribadi",
              hint: "Tambahkan deskripsi singkat",
              maxLines: 4,
            ),
            const SizedBox(height: 32),

            // 3. Tombol Update
            ElevatedButton(
              onPressed: () {
                // Aksi untuk update profile
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
                "Update",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Helper Widget untuk Tombol Upload ---
  Widget _buildUploadButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(text),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: const Color(0xFF4CAF50), // Warna hijau
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }

  // --- Helper Widget untuk Text Field ---
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: onTap != null,
          onTap: onTap,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            suffixIcon: icon != null
                ? Icon(icon, color: Colors.grey[600])
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            // Border yang modern (putih tanpa garis)
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none, // Tidak ada border
            ),
            // Border saat error (opsional)
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
            // Border saat aktif (opsional)
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF4CAF50),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Widget untuk Dropdown Field ---
  Widget _buildDropdownField({
    required String label,
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: Colors.grey[400])),
          items: items.map((String item) {
            return DropdownMenuItem<String>(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
              borderSide: const BorderSide(
                color: Color(0xFF4CAF50),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
