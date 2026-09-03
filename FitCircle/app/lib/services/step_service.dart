// lib/services/step_service.dart
// FitCircle — Step tracking: sensor + manual entry + Supabase sync
import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';
import '../config/supabase_config.dart';
import '../models/daily_steps.dart';

class StepService {
  final _client = SupabaseConfig.client;

  StreamSubscription<StepCount>? _stepCountSub;
  StreamSubscription<PedestrianStatus>? _pedestrianSub;

  // Track the device's running step counter baseline for today
  int _deviceBaseline = 0;
  int _currentDeviceSteps = 0;
  bool _isTracking = false;

  // Callback to notify the provider of new step counts
  void Function(int steps)? onStepUpdate;

  // ── Permissions ───────────────────────────────────────
  /// Returns true if activity recognition permission is granted.
  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  Future<bool> hasPermission() async {
    return await Permission.activityRecognition.isGranted;
  }

  // ── Sensor Tracking ───────────────────────────────────
  /// Start listening to the device's step sensor.
  /// Syncs to Supabase whenever significant change occurs.
  Future<void> startTracking({
    required String userId,
    required String familyId,
    required int todayBaselineSteps,  // Already stored steps for today
  }) async {
    if (_isTracking) return;

    final hasPerms = await hasPermission();
    if (!hasPerms) return;

    _deviceBaseline = 0;  // Will be set on first reading
    _isTracking = true;

    _stepCountSub = Pedometer.stepCountStream.listen(
      (StepCount event) async {
        if (_deviceBaseline == 0) {
          // First reading of the session — set baseline
          _deviceBaseline = event.steps;
          _currentDeviceSteps = 0;
        } else {
          // Steps since we started listening this session
          _currentDeviceSteps = event.steps - _deviceBaseline;
        }

        final totalTodaySteps = todayBaselineSteps + _currentDeviceSteps;

        onStepUpdate?.call(totalTodaySteps);

        // Sync to Supabase every 50 steps to reduce DB writes
        if (_currentDeviceSteps % 50 == 0) {
          await upsertSteps(
            userId:   userId,
            familyId: familyId,
            steps:    totalTodaySteps,
            source:   'sensor',
          );
        }
      },
      onError: (_) {
        // Sensor unavailable — app falls back to manual entry
        _isTracking = false;
      },
    );
  }

  void stopTracking() {
    _stepCountSub?.cancel();
    _pedestrianSub?.cancel();
    _isTracking = false;
  }

  // ── Database Operations ────────────────────────────────

  /// Upsert today's step record (one row per user per day).
  Future<DailySteps> upsertSteps({
    required String userId,
    required String familyId,
    required int steps,
    String source = 'manual',
    double? distance,
    int? calories,
  }) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await _client
        .from('daily_steps')
        .upsert(
          {
            'user_id':   userId,
            'family_id': familyId,
            'date':      today,
            'steps':     steps,
            'source':    source,
            if (distance != null) 'distance': distance,
            if (calories != null) 'calories': calories,
          },
          onConflict: 'user_id,date',
        )
        .select()
        .single();

    return DailySteps.fromJson(result);
  }

  /// Add steps manually (additive).
  Future<DailySteps> addManualSteps({
    required String userId,
    required String familyId,
    required int additionalSteps,
  }) async {
    // Get current steps for today
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final existing = await getTodaySteps(userId: userId);
    final current = existing?.steps ?? 0;

    return upsertSteps(
      userId:   userId,
      familyId: familyId,
      steps:    current + additionalSteps,
      source:   'manual',
    );
  }

  /// Get today's step record for a user.
  Future<DailySteps?> getTodaySteps({required String userId}) async {
    final today = DateTime.now().toIso8601String().substring(0, 10);

    final result = await _client
        .from('daily_steps')
        .select()
        .eq('user_id', userId)
        .eq('date', today)
        .maybeSingle();

    if (result == null) return null;
    return DailySteps.fromJson(result);
  }

  /// Get step history for a user (last N days).
  Future<List<DailySteps>> getStepHistory({
    required String userId,
    int days = 30,
  }) async {
    final fromDate = DateTime.now().subtract(Duration(days: days));

    final results = await _client
        .from('daily_steps')
        .select()
        .eq('user_id', userId)
        .gte('date', fromDate.toIso8601String().substring(0, 10))
        .order('date', ascending: false);

    return results.map((r) => DailySteps.fromJson(r)).toList();
  }

  /// Get weekly total steps for a user.
  Future<int> getWeeklySteps({required String userId}) async {
    final startOfWeek = _startOfCurrentWeek();

    final results = await _client
        .from('daily_steps')
        .select('steps')
        .eq('user_id', userId)
        .gte('date', startOfWeek.toIso8601String().substring(0, 10));

    return results.fold<int>(0, (sum, r) => sum + (r['steps'] as int? ?? 0));
  }

  /// Get monthly total steps for a user.
  Future<int> getMonthlySteps({required String userId}) async {
    final startOfMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);

    final results = await _client
        .from('daily_steps')
        .select('steps')
        .eq('user_id', userId)
        .gte('date', startOfMonth.toIso8601String().substring(0, 10));

    return results.fold<int>(0, (sum, r) => sum + (r['steps'] as int? ?? 0));
  }

  /// Get lifetime total steps for a user.
  Future<int> getLifetimeSteps({required String userId}) async {
    final results = await _client
        .from('daily_steps')
        .select('steps')
        .eq('user_id', userId);

    return results.fold<int>(0, (sum, r) => sum + (r['steps'] as int? ?? 0));
  }

  // ── Helpers ───────────────────────────────────────────
  DateTime _startOfCurrentWeek() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }
}
