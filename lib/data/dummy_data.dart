// Dummy Data untuk Testing
// File ini berisi data-data dummy yang dapat diakses di seluruh aplikasi

class DummyData {
  // Dummy Family Data (untuk EditFamilyPage)
  static final Map<String, dynamic> dummyFamilyData = {
    'id': 'family-001',
    'headName': 'Roisah',
    'spouseName': 'Iskandar',
    'location': 'Bedi Babadan Ponorogo',
    'headPhoto': 'https://via.placeholder.com/150?text=Roisah',
    'spousePhoto': 'https://via.placeholder.com/150?text=Iskandar',
    'children': [
      {
        'id': 'child-001',
        'name': 'Moh. Harjo',
        'spouse': 'S. Yasin',
        'photo': 'https://via.placeholder.com/150?text=Harjo',
      },
      {
        'id': 'child-002',
        'name': 'Abu Thoyib',
        'spouse': 'Tasmiyah',
        'photo': 'https://via.placeholder.com/150?text=Thoyib',
      },
      {
        'id': 'child-003',
        'name': 'Syihabur Romli',
        'spouse': 'Marhamah',
        'photo': 'https://via.placeholder.com/150?text=Romli',
      },
    ],
  };

  // Dummy Family Member Data (untuk UpdateFamilyMemberPage)
  static final Map<String, dynamic> dummyMemberData = {
    'id': 'member-001',
    'name': 'Moh. Harjo',
    'nik': '3209181234567890',
    'gender': 'Laki-Laki',
    'relation': 'Anak',
    'dateRange': '15',
    'month': 'Januari',
    'year': 1980,
    'notes': 'Ayah adalah seorang yang hebat tiada tara, selalu berjuang.',
    'photoUrl': 'https://via.placeholder.com/150?text=Harjo',
  };

  // Dummy Add Family Data (untuk preview di AddFamilyPage)
  static final Map<String, dynamic> dummyNewFamilyData = {
    'headName': 'Ahmad Sujadmimko',
    'spouseName': 'Siti Aminah',
    'location': 'Surabaya',
    'headPhoto': 'https://via.placeholder.com/150?text=Ahmad',
    'spousePhoto': 'https://via.placeholder.com/150?text=Siti',
    'children': [
      {
        'id': 'child-004',
        'name': 'Budi Sujadmiko',
        'spouse': 'Rina',
        'photo': 'https://via.placeholder.com/150?text=Budi',
      },
      {
        'id': 'child-005',
        'name': 'Ani Sujadmiko',
        'spouse': 'Joko',
        'photo': 'https://via.placeholder.com/150?text=Ani',
      },
    ],
  };

  // Dummy Add Family Member Data (untuk preview di AddFamilyMemberPage)
  static final Map<String, dynamic> dummyNewMemberData = {
    'name': 'Tomas Alfa Edisound',
    'nik': '3209189876543210',
    'gender': 'Laki-Laki',
    'relation': 'Anak',
    'dateRange': '30',
    'month': 'Desember',
    'year': 2012,
    'notes': 'Calon generasi penerus keluarga yang cerdas dan berbudi luhur.',
    'photoUrl': 'https://via.placeholder.com/150?text=Tomas',
  };

  // List dari semua families (untuk FamilyListPage)
  static final List<Map<String, dynamic>> dummyFamiliesList = [
    {
      'nit': '1.',
      'headName': 'Roisah',
      'spouseName': 'Iskandar',
      'location': 'Bedi Babadan Ponorogo',
      'headPhoto': 'https://via.placeholder.com/150?text=Roisah',
      'children': [
        {
          'nit': '1.1',
          'id': 'child-001',
          'name': 'Moh. Harjo',
          'spouse': 'S. Yasin',
          'photo': 'https://via.placeholder.com/150?text=Harjo',
        },
        {
          'nit': '1.2',
          'id': 'child-002',
          'name': 'Abu Thoyib',
          'spouse': 'Tasmiyah',
          'photo': 'https://via.placeholder.com/150?text=Thoyib',
        },
        {
          'nit': '1.3',
          'id': 'child-003',
          'name': 'Syihabur Romli',
          'spouse': 'Marhamah',
          'photo': 'https://via.placeholder.com/150?text=Romli',
        },
      ],
    },
    {
      'nit': '2.',
      'headName': 'Ahmad Sujadmimko',
      'spouseName': 'Siti Aminah',
      'location': 'Surabaya',
      'headPhoto': 'https://via.placeholder.com/150?text=Ahmad',
      'children': [
        {
          'nit': '2.1',
          'id': 'child-004',
          'name': 'Budi Sujadmiko',
          'spouse': 'Rina',
          'photo': 'https://via.placeholder.com/150?text=Budi',
        },
        {
          'nit': '2.2',
          'id': 'child-005',
          'name': 'Ani Sujadmiko',
          'spouse': 'Joko',
          'photo': 'https://via.placeholder.com/150?text=Ani',
        },
      ],
    },
  ];

  // Family Members untuk detail keluarga (FamilyInfoPage)
  static final List<Map<String, String>> dummyFamilyMembers = [
    {
      'id': 'child-001',
      'name': 'Tomas Alfa Edisound',
      'role': 'Anak Ke 1',
      'photo': 'https://via.placeholder.com/150?text=Tomas',
    },
    {
      'id': 'child-002',
      'name': 'Nana Donal',
      'role': 'Anak Ke 2',
      'photo': 'https://via.placeholder.com/150?text=Nana',
    },
    {
      'id': 'child-003',
      'name': 'Sinta Suke Jr.',
      'role': 'Anak Ke 3',
      'photo': 'https://via.placeholder.com/150?text=Sinta',
    },
  ];

  // Member detail (MemberInfoPage)
  static final Map<String, dynamic> dummyMemberDetail = {
    'id': 'member-001',
    'name': 'Topan Namas',
    'role': 'Ayah',
    'gender': 'Laki-Laki',
    'nik': '3209189012345678',
    'birthDate': '30 - Desember - 1980',
    'notes': 'Ayah adalah seorang yang hebat tiada tara, selalu berjuang.',
    'photoUrl': 'https://via.placeholder.com/150?text=Topan',
    'relations': [
      {
        'id': 'member-002',
        'name': 'Sinta Suke',
        'role': 'Ibu Rumah Tangga',
        'photo': 'https://via.placeholder.com/150?text=Sinta',
      },
      {
        'id': 'child-001',
        'name': 'Tomas Alfa Edisound',
        'role': 'Anak Ke 1',
        'photo': 'https://via.placeholder.com/150?text=Tomas',
      },
    ],
  };

  // List semua anggota keluarga yang tersedia untuk dipilih
  static final List<Map<String, dynamic>> dummyAvailableChildren = [
    {
      'id': 'child-001',
      'name': 'Moh. Harjo',
      'photo': 'https://via.placeholder.com/150?text=Harjo',
    },
    {
      'id': 'child-002',
      'name': 'Abu Thoyib',
      'photo': 'https://via.placeholder.com/150?text=Thoyib',
    },
    {
      'id': 'child-003',
      'name': 'Syihabur Romli',
      'photo': 'https://via.placeholder.com/150?text=Romli',
    },
    {
      'id': 'child-004',
      'name': 'Budi Sujadmiko',
      'photo': 'https://via.placeholder.com/150?text=Budi',
    },
    {
      'id': 'child-005',
      'name': 'Ani Sujadmiko',
      'photo': 'https://via.placeholder.com/150?text=Ani',
    },
  ];
}
