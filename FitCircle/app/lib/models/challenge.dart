// lib/models/challenge.dart

enum ChallengeType {
  combinedSteps('combined_steps', 'Combined Steps'),
  mostSteps('most_steps', 'Most Steps'),
  mostExerciseMinutes('most_exercise_minutes', 'Most Exercise Minutes'),
  consecutiveGoalDays('consecutive_goal_days', 'Consecutive Goal Days'),
  monthlySteps('monthly_steps', 'Monthly Steps');

  const ChallengeType(this.dbValue, this.displayName);
  final String dbValue;
  final String displayName;

  static ChallengeType fromDb(String value) =>
    ChallengeType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ChallengeType.combinedSteps,
    );
}

class Challenge {
  final String id;
  final String familyId;
  final String title;
  final String? description;
  final int target;
  final ChallengeType challengeType;
  final DateTime startDate;
  final DateTime endDate;
  final DateTime createdAt;

  // Progress — populated separately
  final int? progress;

  const Challenge({
    required this.id,
    required this.familyId,
    required this.title,
    this.description,
    required this.target,
    required this.challengeType,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
    this.progress,
  });

  factory Challenge.fromJson(Map<String, dynamic> json) => Challenge(
    id:            json['id'] as String,
    familyId:      json['family_id'] as String,
    title:         json['title'] as String,
    description:   json['description'] as String?,
    target:        json['target'] as int,
    challengeType: ChallengeType.fromDb(json['challenge_type'] as String),
    startDate:     DateTime.parse(json['start_date'] as String),
    endDate:       DateTime.parse(json['end_date'] as String),
    createdAt:     DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'family_id':      familyId,
    'title':          title,
    'description':    description,
    'target':         target,
    'challenge_type': challengeType.dbValue,
    'start_date':     startDate.toIso8601String().substring(0, 10),
    'end_date':       endDate.toIso8601String().substring(0, 10),
  };

  double get progressPercent {
    if (progress == null || target <= 0) return 0;
    return (progress! / target).clamp(0.0, 1.0);
  }

  bool get isActive {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate.add(const Duration(days: 1)));
  }

  bool get isCompleted => (progress ?? 0) >= target;

  int get daysRemaining {
    final diff = endDate.difference(DateTime.now()).inDays;
    return diff < 0 ? 0 : diff;
  }
}
