import 'package:family_tree_app/components/ui.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class FamilyInfoPage extends StatefulWidget {
  const FamilyInfoPage({super.key});

  @override
  State<FamilyInfoPage> createState() => _FamilyInfoPageState();
}

class _FamilyInfoPageState extends State<FamilyInfoPage> {
  int _selectedIndex = 2;

  final List<Map<String, String>> familyMembers = [
    {"name": "Topan Namas", "role": "Kepala Keluarga"},
    {"name": "Sinta Suke", "role": "Ibu Rumah Tangga"},
    {"name": "Tomas Alfa Edisound", "role": "Anak Ke 1"},
    {"name": "Nana Donal", "role": "Anak Ke 2"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Latar belakang body utama (abu-abu muda)
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1.0,
        leading: CustomBackButton(
          onPressed: () {
            context.pop();
          },
        ),
        title: const Text(
          "Keluarga Utama",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        // Ikon Aksi (Profil)
        actions: [
          IconButton(
            icon: const Icon(
              Icons.account_circle_outlined,
              color: Colors.black87,
              size: 30,
            ),
            onPressed: () {
            },
          ),
          const SizedBox(width: 8), // Sedikit padding di kanan
        ],
      ),

      body: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        itemCount: familyMembers.length,
        itemBuilder: (context, index) {
          final member = familyMembers[index];
          return _buildMemberCard(
            name: member['name']!,
            role: member['role']!,
            onTap: () {
              // Aksi saat card anggota di-tap
              print("Tapped on ${member['name']}");
            },
          );
        },
      ),

      // === Floating Action Button ===
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aksi untuk tombol tambah
        },
        // Warna hijau tua sesuai desain
        backgroundColor: const Color(0xFF2E7D32), // Mirip Colors.green[800]
        child: const Icon(Icons.add, color: Colors.white),
      ),

      // === Bottom Navigation Bar ===
      bottomNavigationBar: BottomNavigationBar(
        // Tipe 'fixed' agar semua item tampil dan tidak bergeser
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.white,
        // Item yang sedang aktif
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          // Tambahkan logika navigasi di sini
        },
        // Warna item yang aktif (hitam/abu tua)
        selectedItemColor: Colors.black87,
        // Warna item yang tidak aktif (abu-abu)
        unselectedItemColor: Colors.grey[600],
        // Nonaktifkan label agar mirip desain (opsional)
        // showSelectedLabels: false,
        // showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Pencarian',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Keluarga',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Pengaturan',
          ),
        ],
      ),
    );
  }

  // --- Widget Kustom untuk Card Anggota Keluarga ---
  Widget _buildMemberCard({
    required String name,
    required String role,
    VoidCallback? onTap,
  }) {
    return Card(
      // Latar belakang card putih
      color: Colors.white,
      // Bayangan tipis
      elevation: 0.5,
      // Sedikit margin antar card
      margin: const EdgeInsets.only(bottom: 12.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // 1. Placeholder Foto Profil
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  // Warna abu-abu placeholder
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8.0),
                ),
                // child: ClipRRect(
                //   borderRadius: BorderRadius.circular(8.0),
                //   child: Image.network('URL_FOTO', fit: BoxFit.cover),
                // ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Peran
                    Text(
                      role,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),

              Icon(Icons.chevron_right, color: Colors.grey[600], size: 28),
            ],
          ),
        ),
      ),
    );
  }
}