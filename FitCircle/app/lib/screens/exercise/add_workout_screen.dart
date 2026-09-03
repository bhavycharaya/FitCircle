// lib/screens/exercise/add_workout_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fitcircle_provider.dart';
import '../../models/exercise.dart';
import '../../config/app_theme.dart';

class AddWorkoutScreen extends StatefulWidget {
  const AddWorkoutScreen({super.key});

  @override
  State<AddWorkoutScreen> createState() => _AddWorkoutScreenState();
}

class _AddWorkoutScreenState extends State<AddWorkoutScreen> {
  ExerciseType _selectedType = ExerciseType.running;
  final _durationController = TextEditingController();
  final _repsController = TextEditingController();
  final _setsController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _durationController.dispose();
    _repsController.dispose();
    _setsController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final duration = int.tryParse(_durationController.text);
    final reps = int.tryParse(_repsController.text);
    final sets = int.tryParse(_setsController.text);
    final distance = double.tryParse(_distanceController.text);

    if (duration == null && reps == null && distance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter duration, reps, or distance')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await context.read<FitCircleProvider>().logWorkout(
            type: _selectedType,
            durationMinutes: duration,
            repetitions: reps,
            sets: sets,
            distance: distance,
            notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving workout: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log Workout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Exercise Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 12),

            // Exercise Type Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: ExerciseType.values.length,
              itemBuilder: (ctx, idx) {
                final type = ExerciseType.values[idx];
                final isSelected = type == _selectedType;
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = type),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.purple : AppColors.bgCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? AppColors.purpleLight : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${type.emoji} ${type.displayName}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 28),

            // Duration
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Duration (mins)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _durationController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 30'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Distance (km)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _distanceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: 'e.g. 5.2'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Reps & Sets
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Repetitions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _repsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 50'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Sets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _setsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(hintText: 'e.g. 3'),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Private Notes
            const Text('Private Notes (Only visible to you)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(hintText: 'e.g. Felt great! Morning run around the park.'),
            ),

            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: _isSaving ? null : _handleSave,
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Workout'),
            ),
          ],
        ),
      ),
    );
  }
}
