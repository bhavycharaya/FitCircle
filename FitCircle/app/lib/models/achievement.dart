// lib/models/achievement.dart

enum AchievementType {
  firstStep('first_step', 'First Step', 'Complete your first daily goal.', '🎯'),
  k10Club('10k_club', '10K Club', 'Walk 10,000 steps in a single day.', '👟'),
  k25Day('25k_day', '25K Day', 'Walk 25,000 steps in a single day.', '⚡'),
  k50Week('50k_week', '50K Week', 'Walk 50,000 steps in a single week.', '🔥'),
  dayWarrior7('7_day_warrior', '7 Day Warrior', 'Complete your goal 7 days in a row.', '💪'),
  overtaker('overtaker', 'Overtaker', 'Successfully overtake a family member.', '🏃'),
  comeback('comeback', 'Comeback', 'Move up 2+ positions in the leaderboard in one day.', '📈'),
  familyChampion('family_champion', 'Family Champion', 'Finish #1 in a weekly leaderboard.', '🏆'),
  millionSteps('million_steps', 'Million Steps', 'Walk 1,000,000 lifetime steps.', '🌟');

  const AchievementType(
    this.dbValue, this.title, this.description, this.emoji,
  );

  final String dbValue;
  final String title;
  final String description;
  final String emoji;

  static AchievementType? fromDb(String value) {
    try {
      return AchievementType.values.firstWhere((e) => e.dbValue == value);
    } catch (_) {
      return null;
    }
  }
}

class Achievement {
  final String id;
  final String userId;
  final AchievementType type;
  final DateTime achievedAt;

  const Achievement({
    required this.id,
    required this.userId,
    required this.type,
    required this.achievedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) => Achievement(
    id:         json['id'] as String,
    userId:     json['user_id'] as String,
    type:       AchievementType.fromDb(json['achievement_type'] as String)!,
    achievedAt: DateTime.parse(json['achieved_at'] as String),
  );
}
