class ChildMember {
  final String nit;
  final String name;
  final String? spouseName;
  final String location;
  final String? photoUrl;
  final String emoji;
  final List<ChildMember>? children; // Anak dari anak ini

  ChildMember({
    required this.nit,
    required this.name,
    this.spouseName,
    required this.location,
    this.photoUrl,
    this.emoji = '👤',
    this.children, // Tambahkan di constructor
  });
}

class FamilyUnit {
  final String nit;
  final String headName;
  final String? spouseName;
  final String location;
  final List<ChildMember> children;

  FamilyUnit({
    required this.nit,
    required this.headName,
    this.spouseName,
    required this.location,
    required this.children,
  });
}