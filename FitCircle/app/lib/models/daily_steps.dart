// lib/models/daily_steps.dart

class DailySteps {
  final String id;
  final String userId;
  final String familyId;
  final DateTime date;
  final int steps;
  final double? distance;
  final int? calories;
  final String source;
  final DateTime updatedAt;

  const DailySteps({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.date,
    required this.steps,
    this.distance,
    this.calories,
    required this.source,
    required this.updatedAt,
  });

  factory DailySteps.fromJson(Map<String, dynamic> json) => DailySteps(
    id:        json['id'] as String,
    userId:    json['user_id'] as String,
    familyId:  json['family_id'] as String,
    date:      DateTime.parse(json['date'] as String),
    steps:     json['steps'] as int? ?? 0,
    distance:  (json['distance'] as num?)?.toDouble(),
    calories:  json['calories'] as int?,
    source:    json['source'] as String? ?? 'manual',
    updatedAt: DateTime.parse(json['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'user_id':   userId,
    'family_id': familyId,
    'date':      date.toIso8601String().substring(0, 10),
    'steps':     steps,
    'distance':  distance,
    'calories':  calories,
    'source':    source,
  };

  DailySteps copyWith({int? steps, double? distance, int? calories}) => DailySteps(
    id:        id,
    userId:    userId,
    familyId:  familyId,
    date:      date,
    steps:     steps ?? this.steps,
    distance:  distance ?? this.distance,
    calories:  calories ?? this.calories,
    source:    source,
    updatedAt: updatedAt,
  );
}

// ─────────────────────────────────────────────────────────────
// LeaderboardEntry — populated from the family_leaderboard view

class LeaderboardEntry {
  final String userId;
  final String familyId;
  final String name;
  final String? avatarUrl;
  final int steps;
  final int rank;
  final DateTime date;

  // Computed fields
  final int? dailyGoal;

  const LeaderboardEntry({
    required this.userId,
    required this.familyId,
    required this.name,
    this.avatarUrl,
    required this.steps,
    required this.rank,
    required this.date,
    this.dailyGoal,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) => LeaderboardEntry(
    userId:    json['user_id'] as String,
    familyId:  json['family_id'] as String,
    name:      json['name'] as String,
    avatarUrl: json['avatar_url'] as String?,
    steps:     json['steps'] as int? ?? 0,
    rank:      (json['rank'] as num?)?.toInt() ?? 0,
    date:      DateTime.parse(json['date'] as String),
    dailyGoal: json['daily_step_goal'] as int?,
  );

  /// Core FitCircle overtake calculation.
  /// Returns null if this entry IS #1.
  int? stepsToOvertake(LeaderboardEntry personAbove) {
    if (rank <= 1) return null;
    final diff = personAbove.steps - steps + 1;
    return diff > 0 ? diff : null;
  }

  String get medal {
    switch (rank) {
      case 1: return '🥇';
      case 2: return '🥈';
      case 3: return '🥉';
      default: return '$rank';
    }
  }

  double get goalProgress {
    if (dailyGoal == null || dailyGoal! <= 0) return 0;
    return (steps / dailyGoal!).clamp(0.0, 1.0);
  }
}
