// lib/screens/exercise/exercise_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fitcircle_provider.dart';
import '../../models/exercise.dart';
import '../../config/app_theme.dart';
import 'add_workout_screen.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  ExerciseType? _selectedFilter;

  @override
  Widget build(BuildContext context) {
    final fitcircle = context.watch<FitCircleProvider>();
    final workouts = _selectedFilter == null
        ? fitcircle.myWorkouts
        : fitcircle.myWorkouts.where((w) => w.exerciseType == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise & Workouts'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddWorkoutScreen()),
          );
        },
        backgroundColor: AppColors.purple,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Workout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Pills
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  ChoiceChip(
                    label: const Text('All Workouts'),
                    selected: _selectedFilter == null,
                    onSelected: (_) => setState(() => _selectedFilter = null),
                    selectedColor: AppColors.purple,
                  ),
                  const SizedBox(width: 8),
                  ...ExerciseType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('${type.emoji} ${type.displayName}'),
                          selected: _selectedFilter == type,
                          onSelected: (val) => setState(() => _selectedFilter = val ? type : null),
                          selectedColor: AppColors.purple,
                        ),
                      )),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'WORKOUT HISTORY',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            if (workouts.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: const [
                    Icon(Icons.fitness_center, size: 48, color: AppColors.textMuted),
                    SizedBox(height: 16),
                    Text(
                      'No workouts recorded yet.',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap "Log Workout" below to add your exercises!',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: workouts.length,
                itemBuilder: (ctx, idx) {
                  final item = workouts[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.purple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(item.exerciseType.emoji, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.exerciseType.displayName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.summaryText,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                              if (item.notes != null && item.notes!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '🔒 Private Note: ${item.notes}',
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Text(
                          '${item.performedAt.day}/${item.performedAt.month}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
