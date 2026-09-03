// lib/models/profile.dart
class Profile {
  final String id;
  final String name;
  final String? avatarUrl;
  final int dailyStepGoal;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Profile({
    required this.id,
    required this.name,
    this.avatarUrl,
    required this.dailyStepGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    id:           json['id'] as String,
    name:         json['name'] as String,
    avatarUrl:    json['avatar_url'] as String?,
    dailyStepGoal: json['daily_step_goal'] as int? ?? 10000,
    createdAt:    DateTime.parse(json['created_at'] as String),
    updatedAt:    DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':              id,
    'name':            name,
    'avatar_url':      avatarUrl,
    'daily_step_goal': dailyStepGoal,
  };

  Profile copyWith({
    String? name,
    String? avatarUrl,
    int? dailyStepGoal,
  }) => Profile(
    id:            id,
    name:          name ?? this.name,
    avatarUrl:     avatarUrl ?? this.avatarUrl,
    dailyStepGoal: dailyStepGoal ?? this.dailyStepGoal,
    createdAt:     createdAt,
    updatedAt:     updatedAt,
  );
}
