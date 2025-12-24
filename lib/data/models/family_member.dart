/// Model untuk FamilyMember dengan support foto
class FamilyMember {
  final String id;
  final String name;
  final String nik;
  final String dateRange;
  final String image;
  final int year;
  final String month;
  final String? photoUrl;
  final String? relation;
  final String? status;

  FamilyMember({
    required this.id,
    required this.name,
    required this.nik,
    required this.dateRange,
    required this.image,
    required this.year,
    required this.month,
    this.photoUrl,
    this.relation,
    this.status = 'active',
  });

  /// Copy constructor untuk membuat salinan dengan perubahan
  FamilyMember copyWith({
    String? id,
    String? name,
    String? nik,
    String? dateRange,
    String? image,
    int? year,
    String? month,
    String? photoUrl,
    String? relation,
    String? status,
  }) {
    return FamilyMember(
      id: id ?? this.id,
      name: name ?? this.name,
      nik: nik ?? this.nik,
      dateRange: dateRange ?? this.dateRange,
      image: image ?? this.image,
      year: year ?? this.year,
      month: month ?? this.month,
      photoUrl: photoUrl ?? this.photoUrl,
      relation: relation ?? this.relation,
      status: status ?? this.status,
    );
  }

  /// Convert to JSON (untuk API calls atau storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nik': nik,
      'dateRange': dateRange,
      'image': image,
      'year': year,
      'month': month,
      'photoUrl': photoUrl,
      'relation': relation,
      'status': status,
    };
  }

  /// Create from JSON
  factory FamilyMember.fromJson(Map<String, dynamic> json) {
    return FamilyMember(
      id: json['id'] as String,
      name: json['name'] as String,
      nik: json['nik'] as String,
      dateRange: json['dateRange'] as String,
      image: json['image'] as String? ?? '👤',
      year: json['year'] as int,
      month: json['month'] as String,
      photoUrl: json['photoUrl'] as String?,
      relation: json['relation'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}
