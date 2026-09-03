// lib/screens/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitcircle_provider.dart';
import '../../config/app_theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fitcircle = context.watch<FitCircleProvider>();
    final profile = auth.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.red),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // User Avatar & Info
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: AppColors.purple.withOpacity(0.3),
                    backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                    child: profile?.avatarUrl == null
                        ? Text(
                            profile?.name.isNotEmpty == true ? profile!.name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    profile?.name ?? 'User',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    auth.family?.familyName ?? 'Family Circle',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // Statistics Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard('TODAY\'S STEPS', '${fitcircle.todaySteps}', Icons.directions_walk, AppColors.orange),
                _buildStatCard('WEEKLY STEPS', '${fitcircle.weeklySteps}', Icons.date_range, AppColors.purpleLight),
                _buildStatCard('MONTHLY STEPS', '${fitcircle.monthlySteps}', Icons.calendar_month, AppColors.gold),
                _buildStatCard('LIFETIME STEPS', '${fitcircle.lifetimeSteps}', Icons.stars, AppColors.green),
              ],
            ),

            const SizedBox(height: 28),

            // Goal Settings Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.bgCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Daily Step Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${profile?.dailyStepGoal ?? 10000} steps', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                    ],
                  ),
                  OutlinedButton(
                    onPressed: () => _showEditGoalDialog(context, profile?.dailyStepGoal ?? 10000),
                    child: const Text('Edit Goal'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showEditGoalDialog(BuildContext context, int currentGoal) {
    final controller = TextEditingController(text: currentGoal.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Daily Step Goal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(suffixText: 'steps'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null && val >= 1000) {
                context.read<AuthProvider>().updateProfile(dailyStepGoal: val);
                Navigator.pop(ctx);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
