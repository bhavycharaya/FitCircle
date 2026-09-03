// lib/services/challenge_service.dart
// FitCircle — Challenge tracking & management
import '../config/supabase_config.dart';
import '../models/challenge.dart';

class ChallengeService {
  final _client = SupabaseConfig.client;

  /// Fetch all challenges for a family with calculated progress.
  Future<List<Challenge>> getFamilyChallenges(String familyId) async {
    final results = await _client
        .from('challenges')
        .select()
        .eq('family_id', familyId)
        .order('start_date', ascending: false);

    final challenges = <Challenge>[];

    for (final r in results) {
      final challenge = Challenge.fromJson(r);
      final progress = await _calculateProgress(challenge);
      challenges.add(Challenge(
        id:            challenge.id,
        familyId:      challenge.familyId,
        title:         challenge.title,
        description:   challenge.description,
        target:        challenge.target,
        challengeType: challenge.challengeType,
        startDate:     challenge.startDate,
        endDate:       challenge.endDate,
        createdAt:     challenge.createdAt,
        progress:      progress,
      ));
    }

    return challenges;
  }

  /// Create a new family challenge.
  Future<Challenge> createChallenge({
    required String familyId,
    required String title,
    String? description,
    required int target,
    required ChallengeType type,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final result = await _client
        .from('challenges')
        .insert({
          'family_id':      familyId,
          'title':          title,
          'description':    description,
          'target':         target,
          'challenge_type': type.dbValue,
          'start_date':     startDate.toIso8601String().substring(0, 10),
          'end_date':       endDate.toIso8601String().substring(0, 10),
        })
        .select()
        .single();

    return Challenge.fromJson(result);
  }

  /// Calculate challenge progress based on type.
  Future<int> _calculateProgress(Challenge challenge) async {
    final startStr = challenge.startDate.toIso8601String().substring(0, 10);
    final endStr   = challenge.endDate.toIso8601String().substring(0, 10);

    switch (challenge.challengeType) {
      case ChallengeType.combinedSteps:
      case ChallengeType.mostSteps:
      case ChallengeType.monthlySteps:
        final results = await _client
            .from('daily_steps')
            .select('steps')
            .eq('family_id', challenge.familyId)
            .gte('date', startStr)
            .lte('date', endStr);

        return results.fold<int>(0, (sum, r) => sum + (r['steps'] as int? ?? 0));

      case ChallengeType.mostExerciseMinutes:
        final results = await _client
            .from('exercises')
            .select('duration_minutes')
            .eq('family_id', challenge.familyId)
            .gte('performed_at', challenge.startDate.toIso8601String())
            .lte('performed_at', challenge.endDate.toIso8601String());

        return results.fold<int>(0, (sum, r) => sum + (r['duration_minutes'] as int? ?? 0));

      case ChallengeType.consecutiveGoalDays:
        // Return average consecutive streak in family
        final results = await _client
            .from('streaks')
            .select('current_streak')
            .inFilter('user_id', (await _getFamilyUserIds(challenge.familyId)));

        if (results.isEmpty) return 0;
        final maxStreak = results.fold<int>(0, (maxVal, r) {
          final val = r['current_streak'] as int? ?? 0;
          return val > maxVal ? val : maxVal;
        });
        return maxStreak;
    }
  }

  Future<List<String>> _getFamilyUserIds(String familyId) async {
    final results = await _client
        .from('family_members')
        .select('user_id')
        .eq('family_id', familyId);
    return results.map((r) => r['user_id'] as String).toList();
  }
}
