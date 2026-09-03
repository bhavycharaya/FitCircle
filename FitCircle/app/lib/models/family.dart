// lib/models/family.dart
class Family {
  final String id;
  final String familyName;
  final String familyCode;
  final String createdBy;
  final DateTime createdAt;

  const Family({
    required this.id,
    required this.familyName,
    required this.familyCode,
    required this.createdBy,
    required this.createdAt,
  });

  factory Family.fromJson(Map<String, dynamic> json) => Family(
    id:         json['id'] as String,
    familyName: json['family_name'] as String,
    familyCode: json['family_code'] as String,
    createdBy:  json['created_by'] as String,
    createdAt:  DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'family_name': familyName,
    'family_code': familyCode,
    'created_by':  createdBy,
  };
}

// ─────────────────────────────────────────────────────────────

class FamilyMember {
  final String id;
  final String familyId;
  final String userId;
  final DateTime joinedAt;

  // Joined from profiles
  final String? name;
  final String? avatarUrl;

  const FamilyMember({
    required this.id,
    required this.familyId,
    required this.userId,
    required this.joinedAt,
    this.name,
    this.avatarUrl,
  });

  factory FamilyMember.fromJson(Map<String, dynamic> json) => FamilyMember(
    id:       json['id'] as String,
    familyId: json['family_id'] as String,
    userId:   json['user_id'] as String,
    joinedAt: DateTime.parse(json['joined_at'] as String),
    name:     json['profiles'] != null ? (json['profiles'] as Map<String, dynamic>)['name'] as String? : null,
    avatarUrl: json['profiles'] != null ? (json['profiles'] as Map<String, dynamic>)['avatar_url'] as String? : null,
  );
}
