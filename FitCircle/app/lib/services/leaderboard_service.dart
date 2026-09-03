// lib/services/leaderboard_service.dart
// FitCircle — Leaderboard queries + Realtime subscription
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/daily_steps.dart';

enum LeaderboardPeriod { today, thisWeek, thisMonth, allTime }

class LeaderboardService {
  final _client = SupabaseConfig.client;
  RealtimeChannel? _realtimeChannel;

  // ── Leaderboard Queries ────────────────────────────────

  /// Fetch the daily leaderboard for a family from the server-side view.
  /// Rank is ALWAYS computed server-side — never trusted from client.
  Future<List<LeaderboardEntry>> getDailyLeaderboard({
    required String familyId,
    DateTime? date,
  }) async {
    final targetDate = (date ?? DateTime.now()).toIso8601String().substring(0, 10);

    final results = await _client
        .from('family_leaderboard')
        .select()
        .eq('family_id', familyId)
        .eq('date', targetDate)
        .order('rank');

    return results.map((r) => LeaderboardEntry.fromJson(r)).toList();
  }

  /// Fetch weekly leaderboard.
  Future<List<LeaderboardEntry>> getWeeklyLeaderboard({
    required String familyId,
  }) async {
    final startOfWeek = _startOfCurrentWeek().toIso8601String().substring(0, 10);

    final results = await _client
        .from('weekly_leaderboard')
        .select()
        .eq('family_id', familyId)
        .eq('week_start', startOfWeek)
        .order('rank');

    return results.map((r) => LeaderboardEntry.fromJson({
      ...r,
      'steps': r['total_steps'],
      'date':  startOfWeek,
    })).toList();
  }

  /// Fetch monthly leaderboard.
  Future<List<LeaderboardEntry>> getMonthlyLeaderboard({
    required String familyId,
  }) async {
    final startOfMonth = _startOfCurrentMonth().toIso8601String().substring(0, 10);

    final results = await _client
        .from('monthly_leaderboard')
        .select()
        .eq('family_id', familyId)
        .eq('month_start', startOfMonth)
        .order('rank');

    return results.map((r) => LeaderboardEntry.fromJson({
      ...r,
      'steps': r['total_steps'],
      'date':  startOfMonth,
    })).toList();
  }

  /// Fetch all-time leaderboard.
  Future<List<LeaderboardEntry>> getAllTimeLeaderboard({
    required String familyId,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final results = await _client
        .from('alltime_leaderboard')
        .select()
        .eq('family_id', familyId)
        .order('rank');

    return results.map((r) => LeaderboardEntry.fromJson({
      ...r,
      'steps': r['total_steps'],
      'date':  today,
    })).toList();
  }

  /// Convenience method to fetch by period.
  Future<List<LeaderboardEntry>> getLeaderboard({
    required String familyId,
    required LeaderboardPeriod period,
  }) {
    return switch (period) {
      LeaderboardPeriod.today     => getDailyLeaderboard(familyId: familyId),
      LeaderboardPeriod.thisWeek  => getWeeklyLeaderboard(familyId: familyId),
      LeaderboardPeriod.thisMonth => getMonthlyLeaderboard(familyId: familyId),
      LeaderboardPeriod.allTime   => getAllTimeLeaderboard(familyId: familyId),
    };
  }

  // ── Overtake Engine ────────────────────────────────────

  /// The core FitCircle feature.
  /// Returns the overtake message string for the current user.
  static String getOvertakeMessage({
    required List<LeaderboardEntry> leaderboard,
    required String userId,
  }) {
    if (leaderboard.isEmpty) return 'Start walking to join the leaderboard!';

    final myIndex = leaderboard.indexWhere((e) => e.userId == userId);
    if (myIndex < 0) return 'Start walking to appear on the leaderboard!';

    final me = leaderboard[myIndex];

    // #1 case
    if (me.rank == 1) {
      if (leaderboard.length > 1) {
        final behind = leaderboard[1];
        final gap = me.steps - behind.steps;
        return gap < 500
            ? '🥇 You\'re #1! ${behind.name} is only $gap steps behind!'
            : '🥇 You\'re #1! Defend your lead!';
      }
      return '🥇 You\'re #1! Nobody to overtake!';
    }

    // Not #1 — find person above
    final above = leaderboard[myIndex - 1];
    final diff = above.steps - me.steps + 1;

    if (diff <= 0) return '🎉 You overtook ${above.name}!';

    if (diff == 1) return '⚡ 1 more step to overtake ${above.name}! GO!';

    if (diff < 100) return '🔥 Only $diff steps to overtake ${above.name}!';

    if (diff < 500) return 'You\'re just $diff steps behind ${above.name}!';

    return 'Only $diff steps to overtake ${above.name}!';
  }

  // ── Realtime Subscription ─────────────────────────────

  /// Subscribe to real-time step updates for a family.
  /// Calls [onUpdate] whenever any family member's steps change.
  /// Family-level filter ensures user only receives their family's data.
  void subscribeToFamily({
    required String familyId,
    required void Function() onUpdate,
  }) {
    _realtimeChannel?.unsubscribe();

    _realtimeChannel = _client
        .channel('family_steps_$familyId')
        .onPostgresChanges(
          event:  PostgresChangeEvent.all,
          schema: 'public',
          table:  'daily_steps',
          filter: PostgresChangeFilter(
            type:  FilterType.eq,
            column: 'family_id',
            value:  familyId,
          ),
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  void unsubscribe() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = null;
  }

  // ── Helper ─────────────────────────────────────────────
  DateTime _startOfCurrentWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  DateTime _startOfCurrentMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }
}
