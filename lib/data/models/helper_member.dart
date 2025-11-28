class ChildMember {
  final int? id;
  final String nit;
  final String name;
  final String? birthYear;
  final String? spouseName;
  final String? location;
  final String? photoUrl;
  final String emoji;
  final List<ChildMember> children;

  ChildMember({
    this.id,
    required this.nit,
    required this.name,
    this.birthYear,
    this.spouseName,
    required this.location,
    this.photoUrl,
    this.emoji = '👤',
    List<ChildMember>? children,
  }) : children = children ?? []; 
}

class FamilyUnit {
  final int? headId;
  final String nit;
  final String headName;
  final String? birthYear;
  final String? spouseName;
  final String? location;
  final String? avatar;
  final List<ChildMember> children;

  FamilyUnit({
    this.headId,
    required this.nit,
    required this.headName,
    this.birthYear,
    this.avatar,
    this.spouseName,
    this.location,
    required this.children,
  });
}