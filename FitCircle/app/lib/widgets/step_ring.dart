// lib/widgets/step_ring.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class StepRing extends StatelessWidget {
  final int currentSteps;
  final int goalSteps;
  final double size;

  const StepRing({
    super.key,
    required this.currentSteps,
    required this.goalSteps,
    this.size = 220,
  });

  double get progress => goalSteps > 0 ? (currentSteps / goalSteps).clamp(0.0, 1.0) : 0;
  int get percentage => (progress * 100).round();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 16,
              color: AppColors.border,
            ),
          ),
          // Active Ring
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 16,
              strokeCap: StrokeCap.round,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
              backgroundColor: Colors.transparent,
            ),
          ),
          // Inside Text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🏃 STEPS', style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 4),
              Text(
                currentSteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},'),
                style: theme.textTheme.displayMedium?.copyWith(fontWeight: FontWeight.w900),
              ),
              Text(
                '/ ${goalSteps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')}',
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: progress >= 1.0 ? AppColors.green.withOpacity(0.2) : AppColors.purple.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: progress >= 1.0 ? AppColors.green : AppColors.purpleLight.withOpacity(0.5)),
                ),
                child: Text(
                  progress >= 1.0 ? '🎉 Goal Complete!' : '$percentage% Complete',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: progress >= 1.0 ? AppColors.green : AppColors.purpleLight,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
