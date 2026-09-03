// lib/models/exercise.dart

enum ExerciseType {
  walking('walking', '🚶', 'Walking'),
  running('running', '🏃', 'Running'),
  cycling('cycling', '🚴', 'Cycling'),
  pushups('pushups', '💪', 'Push-ups'),
  squats('squats', '🦵', 'Squats'),
  plank('plank', '🧘', 'Plank'),
  jumpingJacks('jumping_jacks', '⭐', 'Jumping Jacks'),
  yoga('yoga', '🧘', 'Yoga'),
  stretching('stretching', '🤸', 'Stretching'),
  swimming('swimming', '🏊', 'Swimming'),
  gym('gym', '🏋️', 'Gym'),
  other('other', '💪', 'Other');

  const ExerciseType(this.dbValue, this.emoji, this.displayName);
  final String dbValue;
  final String emoji;
  final String displayName;

  static ExerciseType fromDb(String value) =>
    ExerciseType.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => ExerciseType.other,
    );
}

class Exercise {
  final String id;
  final String userId;
  final String familyId;
  final ExerciseType exerciseType;
  final int? durationMinutes;
  final int? repetitions;
  final int? sets;
  final double? distance;
  final String? notes;  // PRIVATE — never send to other users
  final DateTime performedAt;
  final DateTime createdAt;

  const Exercise({
    required this.id,
    required this.userId,
    required this.familyId,
    required this.exerciseType,
    this.durationMinutes,
    this.repetitions,
    this.sets,
    this.distance,
    this.notes,
    required this.performedAt,
    required this.createdAt,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
    id:              json['id'] as String,
    userId:          json['user_id'] as String,
    familyId:        json['family_id'] as String,
    exerciseType:    ExerciseType.fromDb(json['exercise_type'] as String),
    durationMinutes: json['duration_minutes'] as int?,
    repetitions:     json['repetitions'] as int?,
    sets:            json['sets'] as int?,
    distance:        (json['distance'] as num?)?.toDouble(),
    notes:           json['notes'] as String?,
    performedAt:     DateTime.parse(json['performed_at'] as String),
    createdAt:       DateTime.parse(json['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'user_id':          userId,
    'family_id':        familyId,
    'exercise_type':    exerciseType.dbValue,
    'duration_minutes': durationMinutes,
    'repetitions':      repetitions,
    'sets':             sets,
    'distance':         distance,
    'notes':            notes,
    'performed_at':     performedAt.toIso8601String(),
  };

  String get summaryText {
    final parts = <String>[];
    if (durationMinutes != null) parts.add('$durationMinutes min');
    if (repetitions != null)     parts.add('$repetitions reps');
    if (sets != null)            parts.add('$sets sets');
    if (distance != null)        parts.add('${distance!.toStringAsFixed(1)} km');
    return parts.join(' · ');
  }
}
