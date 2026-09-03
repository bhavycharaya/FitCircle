// lib/services/exercise_service.dart
import '../config/supabase_config.dart';
import '../models/exercise.dart';

class ExerciseService {
  final _client = SupabaseConfig.client;

  /// Save a new workout.
  Future<Exercise> saveWorkout({
    required String userId,
    required String familyId,
    required ExerciseType type,
    int? durationMinutes,
    int? repetitions,
    int? sets,
    double? distance,
    String? notes,
    DateTime? performedAt,
  }) async {
    final result = await _client
        .from('exercises')
        .insert({
          'user_id':          userId,
          'family_id':        familyId,
          'exercise_type':    type.dbValue,
          'duration_minutes': durationMinutes,
          'repetitions':      repetitions,
          'sets':             sets,
          'distance':         distance,
          'notes':            notes,
          'performed_at':     (performedAt ?? DateTime.now()).toIso8601String(),
        })
        .select()
        .single();

    return Exercise.fromJson(result);
  }

  /// Get workout history for the current user.
  /// Notes are included since this is own data only.
  Future<List<Exercise>> getMyWorkouts({
    required String userId,
    int days = 30,
    ExerciseType? filterType,
  }) async {
    final fromDate = DateTime.now().subtract(Duration(days: days));
    var query = _client
        .from('exercises')
        .select()
        .eq('user_id', userId)
        .gte('performed_at', fromDate.toIso8601String());

    if (filterType != null) {
      query = query.eq('exercise_type', filterType.dbValue);
    }

    final results = await query.order('performed_at', ascending: false);
    return results.map((r) => Exercise.fromJson(r)).toList();
  }

  /// Get today's exercises for a user.
  Future<List<Exercise>> getTodayExercises({required String userId}) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final results = await _client
        .from('exercises')
        .select()
        .eq('user_id', userId)
        .gte('performed_at', startOfDay.toIso8601String())
        .order('performed_at', ascending: false);

    return results.map((r) => Exercise.fromJson(r)).toList();
  }

  /// Get total exercise minutes for a user today.
  Future<int> getTodayMinutes({required String userId}) async {
    final exercises = await getTodayExercises(userId: userId);
    return exercises.fold(0, (sum, e) => sum + (e.durationMinutes ?? 0));
  }

  /// Get exercise summary per family member (public — no notes).
  /// Only exposes duration_minutes, not private notes.
  Future<List<FamilyExerciseSummary>> getFamilySummary({
    required String familyId,
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);

    final results = await _client
        .from('exercises')
        .select('user_id, duration_minutes, profiles(name, avatar_url)')
        .eq('family_id', familyId)
        .gte('performed_at', startOfDay.toIso8601String());

    // Aggregate by user
    final Map<String, FamilyExerciseSummary> summaries = {};
    for (final r in results) {
      final uid = r['user_id'] as String;
      final mins = r['duration_minutes'] as int? ?? 0;
      final profile = r['profiles'] as Map<String, dynamic>?;

      if (summaries.containsKey(uid)) {
        summaries[uid] = summaries[uid]!.copyWith(
          totalMinutes: summaries[uid]!.totalMinutes + mins,
        );
      } else {
        summaries[uid] = FamilyExerciseSummary(
          userId:       uid,
          name:         profile?['name'] as String? ?? 'Unknown',
          avatarUrl:    profile?['avatar_url'] as String?,
          totalMinutes: mins,
        );
      }
    }

    return summaries.values.toList();
  }

  /// Delete a workout (own only — RLS enforces this).
  Future<void> deleteWorkout(String id) async {
    await _client.from('exercises').delete().eq('id', id);
  }
}

class FamilyExerciseSummary {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int totalMinutes;

  const FamilyExerciseSummary({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.totalMinutes,
  });

  FamilyExerciseSummary copyWith({int? totalMinutes}) => FamilyExerciseSummary(
    userId:       userId,
    name:         name,
    avatarUrl:    avatarUrl,
    totalMinutes: totalMinutes ?? this.totalMinutes,
  );
}
