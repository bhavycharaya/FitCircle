// lib/providers/fitcircle_provider.dart
import 'package:flutter/material.dart';
import '../services/step_service.dart';
import '../services/leaderboard_service.dart';
import '../services/exercise_service.dart';
import '../services/challenge_service.dart';
import '../services/achievement_service.dart';
import '../models/daily_steps.dart';
import '../models/exercise.dart';
import '../models/challenge.dart';
import '../models/achievement.dart';

class FitCircleProvider extends ChangeNotifier {
  final _stepService = StepService();
  final _leaderboardService = LeaderboardService();
  final _exerciseService = ExerciseService();
  final _challengeService = ChallengeService();
  final _achievementService = AchievementService();

  // State
  int _todaySteps = 0;
  int _weeklySteps = 0;
  int _monthlySteps = 0;
  int _lifetimeSteps = 0;

  List<LeaderboardEntry> _leaderboard = [];
  LeaderboardPeriod _selectedPeriod = LeaderboardPeriod.today;
  String _overtakeMessage = '';
  
  List<Exercise> _todayExercises = [];
  List<Exercise> _myWorkouts = [];
  List<Challenge> _challenges = [];
  List<Achievement> _achievements = [];

  bool _isLoading = false;
  String? _userId;
  String? _familyId;
  String? _overtakeCelebration;

  // Getters
  int get todaySteps => _todaySteps;
  int get weeklySteps => _weeklySteps;
  int get monthlySteps => _monthlySteps;
  int get lifetimeSteps => _lifetimeSteps;

  List<LeaderboardEntry> get leaderboard => _leaderboard;
  LeaderboardPeriod get selectedPeriod => _selectedPeriod;
  String get overtakeMessage => _overtakeMessage;
  String? get overtakeCelebration => _overtakeCelebration;

  List<Exercise> get todayExercises => _todayExercises;
  List<Exercise> get myWorkouts => _myWorkouts;
  List<Challenge> get challenges => _challenges;
  List<Achievement> get achievements => _achievements;
  bool get isLoading => _isLoading;

  LeaderboardEntry? get myLeaderboardEntry {
    try {
      return _leaderboard.firstWhere((e) => e.userId == _userId);
    } catch (_) {
      return null;
    }
  }

  void initialize({required String userId, required String familyId}) {
    _userId = userId;
    _familyId = familyId;

    loadAllData();
    _startRealtimeAndTracking();
  }

  Future<void> loadAllData() async {
    if (_userId == null || _familyId == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Load Steps
      final todayRecord = await _stepService.getTodaySteps(userId: _userId!);
      _todaySteps = todayRecord?.steps ?? 0;
      _weeklySteps = await _stepService.getWeeklySteps(userId: _userId!);
      _monthlySteps = await _stepService.getMonthlySteps(userId: _userId!);
      _lifetimeSteps = await _stepService.getLifetimeSteps(userId: _userId!);

      // 2. Load Leaderboard & Overtake message
      await fetchLeaderboard();

      // 3. Load Exercises
      _todayExercises = await _exerciseService.getTodayExercises(userId: _userId!);
      _myWorkouts = await _exerciseService.getMyWorkouts(userId: _userId!);

      // 4. Load Challenges & Achievements
      _challenges = await _challengeService.getFamilyChallenges(_familyId!);
      _achievements = await _achievementService.getUserAchievements(_userId!);
    } catch (e) {
      debugPrint('Error loading FitCircle data: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchLeaderboard([LeaderboardPeriod? period]) async {
    if (_familyId == null || _userId == null) return;
    if (period != null) _selectedPeriod = period;

    final oldRank = myLeaderboardEntry?.rank;

    _leaderboard = await _leaderboardService.getLeaderboard(
      familyId: _familyId!,
      period: _selectedPeriod,
    );

    _overtakeMessage = LeaderboardService.getOvertakeMessage(
      leaderboard: _leaderboard,
      userId: _userId!,
    );

    final newRank = myLeaderboardEntry?.rank;
    if (oldRank != null && newRank != null && newRank < oldRank) {
      _overtakeCelebration = '🎉 You moved up to #$newRank!';
      notifyListeners();
      Future.delayed(const Duration(seconds: 4), () {
        _overtakeCelebration = null;
        notifyListeners();
      });
    }

    notifyListeners();
  }

  void _startRealtimeAndTracking() {
    if (_familyId == null || _userId == null) return;

    // Realtime subscription for family steps
    _leaderboardService.subscribeToFamily(
      familyId: _familyId!,
      onUpdate: () => fetchLeaderboard(),
    );

    // Hardware sensor tracking
    _stepService.onStepUpdate = (newSteps) {
      _todaySteps = newSteps;
      notifyListeners();
      fetchLeaderboard();
    };

    _stepService.startTracking(
      userId: _userId!,
      familyId: _familyId!,
      todayBaselineSteps: _todaySteps,
    );
  }

  Future<void> addManualSteps(int steps) async {
    if (_userId == null || _familyId == null) return;

    final updated = await _stepService.addManualSteps(
      userId: _userId!,
      familyId: _familyId!,
      additionalSteps: steps,
    );

    _todaySteps = updated.steps;
    await fetchLeaderboard();
  }

  Future<void> logWorkout({
    required ExerciseType type,
    int? durationMinutes,
    int? repetitions,
    int? sets,
    double? distance,
    String? notes,
  }) async {
    if (_userId == null || _familyId == null) return;

    final workout = await _exerciseService.saveWorkout(
      userId: _userId!,
      familyId: _familyId!,
      type: type,
      durationMinutes: durationMinutes,
      repetitions: repetitions,
      sets: sets,
      distance: distance,
      notes: notes,
    );

    _todayExercises.insert(0, workout);
    _myWorkouts.insert(0, workout);
    notifyListeners();
  }

  @override
  void dispose() {
    _stepService.stopTracking();
    _leaderboardService.unsubscribe();
    super.dispose();
  }
}
