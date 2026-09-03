// lib/widgets/leaderboard_card.dart
import 'package:flutter/material.dart';
import '../models/daily_steps.dart';
import '../config/app_theme.dart';

class LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isCurrentUser;

  const LeaderboardCard({
    super.key,
    required this.entry,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isCurrentUser ? AppColors.purple.withOpacity(0.18) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrentUser ? AppColors.purpleLight : AppColors.border,
          width: isCurrentUser ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank / Medal
          SizedBox(
            width: 36,
            child: Text(
              entry.medal,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: entry.rank <= 3 ? 22 : 16,
                fontWeight: FontWeight.bold,
                color: entry.rank <= 3 ? AppColors.gold : AppColors.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.purple.withOpacity(0.3),
            backgroundImage: entry.avatarUrl != null ? NetworkImage(entry.avatarUrl!) : null,
            child: entry.avatarUrl == null
                ? Text(
                    entry.name.isNotEmpty ? entry.name[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 14),

          // Name & Current user badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      entry.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isCurrentUser ? AppColors.purpleLight : AppColors.textPrimary,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.purple,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Step count
          Text(
            '${entry.steps.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} steps',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isCurrentUser ? AppColors.purpleLight : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
