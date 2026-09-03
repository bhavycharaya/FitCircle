// lib/screens/challenges/challenges_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/fitcircle_provider.dart';
import '../../models/achievement.dart';
import '../../widgets/achievement_badge.dart';
import '../../config/app_theme.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fitcircle = context.watch<FitCircleProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Challenges & Achievements'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.orange,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Family Challenges'),
            Tab(text: 'Achievements'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Tab 1: Challenges
          ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (fitcircle.challenges.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: const [
                      Icon(Icons.emoji_events, size: 48, color: AppColors.gold),
                      SizedBox(height: 16),
                      Text(
                        'September Family Challenge',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '500,000 Combined Steps',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                      ),
                      SizedBox(height: 20),
                      LinearProgressIndicator(
                        value: 0.65,
                        minHeight: 10,
                        backgroundColor: AppColors.border,
                        color: AppColors.orange,
                      ),
                      SizedBox(height: 8),
                      Text(
                        '325,400 / 500,000 steps (65%)',
                        style: TextStyle(color: AppColors.purpleLight, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ] else
                ...fitcircle.challenges.map((c) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.bgCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(c.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.purple.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text('${c.daysRemaining} days left', style: const TextStyle(fontSize: 11, color: AppColors.purpleLight)),
                              ),
                            ],
                          ),
                          if (c.description != null) ...[
                            const SizedBox(height: 6),
                            Text(c.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                          ],
                          const SizedBox(height: 16),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: c.progressPercent,
                              minHeight: 10,
                              backgroundColor: AppColors.border,
                              color: AppColors.orange,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${c.progress ?? 0} / ${c.target} (${(c.progressPercent * 100).round()}%)',
                            style: const TextStyle(color: AppColors.purpleLight, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ],
                      ),
                    )),
            ],
          ),

          // Tab 2: Achievements
          GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.85,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
            ),
            itemCount: AchievementType.values.length,
            itemBuilder: (ctx, idx) {
              final type = AchievementType.values[idx];
              final userAchievement = fitcircle.achievements.where((a) => a.type == type).firstOrNull;
              return AchievementBadge(
                type: type,
                isUnlocked: userAchievement != null,
                unlockedAt: userAchievement?.achievedAt,
              );
            },
          ),
        ],
      ),
    );
  }
}
