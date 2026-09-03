// lib/services/achievement_service.dart
// Checks conditions and grants achievements to users
import '../config/supabase_config.dart';
import '../models/achievement.dart';

class AchievementService {
  final _client = SupabaseConfig.client;

  /// Fetch all achievements earned by a user.
  Future<List<Achievement>> getUserAchievements(String userId) async {
    final results = await _client
        .from('achievements')
        .select()
        .eq('user_id', userId)
        .order('achieved_at', ascending: false);

    return results
        .map((r) {
          final type = AchievementType.fromDb(r['achievement_type'] as String);
          if (type == null) return null;
          return Achievement.fromJson(r);
        })
        .whereType<Achievement>()
        .toList();
  }

  /// Grant an achievement if not already earned.
  /// Returns the new Achievement, or null if already has it.
  Future<Achievement?> grantIfNew({
    required String userId,
    required AchievementType type,
  }) async {
    // Check if already earned
    final existing = await _client
        .from('achievements')
        .select('id')
        .eq('user_id', userId)
        .eq('achievement_type', type.dbValue)
        .maybeSingle();

    if (existing != null) return null;

    final result = await _client
        .from('achievements')
        .insert({
          'user_id':          userId,
          'achievement_type': type.dbValue,
        })
        .select()
        .single();

    return Achievement.fromJson(result);
  }

  /// Check and grant all relevant achievements based on current stats.
  /// Call this after step upsert and after overtake events.
  Future<List<Achievement>> checkAndGrantAchievements({
    required String userId,
    required int todaySteps,
    required int weeklySteps,
    required int lifetimeSteps,
    required int currentStreak,
    required int currentRank,
    required int? previousRank,
    required bool justOvertook,
    required bool goalCompleted,
  }) async {
    final granted = <Achievement>[];

    Future<void> tryGrant(AchievementType type) async {
      final a = await grantIfNew(userId: userId, type: type);
      if (a != null) granted.add(a);
    }

    // First completed goal
    if (goalCompleted) await tryGrant(AchievementType.firstStep);

    // 10K in a day
    if (todaySteps >= 10000) await tryGrant(AchievementType.k10Club);

    // 25K in a day
    if (todaySteps >= 25000) await tryGrant(AchievementType.k25Day);

    // 50K in a week
    if (weeklySteps >= 50000) await tryGrant(AchievementType.k50Week);

    // 7 day streak
    if (currentStreak >= 7) await tryGrant(AchievementType.dayWarrior7);

    // Overtaker
    if (justOvertook) await tryGrant(AchievementType.overtaker);

    // Comeback: moved up 2+ positions
    if (previousRank != null && previousRank - currentRank >= 2) {
      await tryGrant(AchievementType.comeback);
    }

    // Family Champion: #1
    if (currentRank == 1) await tryGrant(AchievementType.familyChampion);

    // Million steps
    if (lifetimeSteps >= 1000000) await tryGrant(AchievementType.millionSteps);

    return granted;
  }
}
