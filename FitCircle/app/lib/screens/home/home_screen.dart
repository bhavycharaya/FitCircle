// lib/screens/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fitcircle_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/step_ring.dart';
import '../../widgets/overtake_banner.dart';
import '../../widgets/leaderboard_card.dart';
import '../../config/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fitcircle = context.watch<FitCircleProvider>();
    final user = auth.profile;
    final goal = user?.dailyStepGoal ?? 10000;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Good Morning, ${user?.name ?? "Runner"}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (auth.family != null)
              Text(
                auth.family!.familyName,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add manual steps',
            onPressed: () => _showManualStepDialog(context),
          ),
        ],
      ),
      body: fitcircle.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => fitcircle.loadAllData(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Step Ring
                    Center(
                      child: StepRing(
                        currentSteps: fitcircle.todaySteps,
                        goalSteps: goal,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Celebration Toast (if just overtook)
                    if (fitcircle.overtakeCelebration != null) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.green),
                        ),
                        child: Row(
                          children: [
                            const Text('🎉', style: TextStyle(fontSize: 24)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                fitcircle.overtakeCelebration!,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.green),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Overtake Banner
                    OvertakeBanner(message: fitcircle.overtakeMessage),
                    const SizedBox(height: 28),

                    // Leaderboard Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'FAMILY LEADERBOARD',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Leaderboard List
                    if (fitcircle.leaderboard.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text(
                          'No steps logged today yet.\nBe the first to start walking!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    else
                      ...fitcircle.leaderboard.map((entry) => LeaderboardCard(
                            entry: entry,
                            isCurrentUser: entry.userId == auth.currentUser?.id,
                          )),

                    const SizedBox(height: 24),

                    // Today's Exercise Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TODAY\'S EXERCISE',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: AppColors.textMuted,
                          ),
                        ),
                        Text(
                          '${fitcircle.todayExercises.length} workouts',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (fitcircle.todayExercises.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Text(
                          'No workouts logged today yet.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      )
                    else
                      ...fitcircle.todayExercises.map((e) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.bgCard,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(e.exerciseType.emoji, style: const TextStyle(fontSize: 20)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(e.exerciseType.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                                      Text(e.summaryText, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
                  ],
                ),
              ),
            ),
    );
  }

  void _showManualStepDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Steps Manually'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Enter steps (e.g. 500)',
            suffixText: 'steps',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val > 0) {
                context.read<FitCircleProvider>().addManualSteps(val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }
}
