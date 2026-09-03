// lib/widgets/achievement_badge.dart
import 'package:flutter/material.dart';
import '../models/achievement.dart';
import '../config/app_theme.dart';

class AchievementBadge extends StatelessWidget {
  final AchievementType type;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementBadge({
    super.key,
    required this.type,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUnlocked ? AppColors.purple.withOpacity(0.12) : AppColors.bgCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUnlocked ? AppColors.purpleLight : AppColors.border,
          width: isUnlocked ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isUnlocked ? AppColors.purple.withOpacity(0.25) : AppColors.bgSecondary,
              boxShadow: isUnlocked
                  ? [
                      BoxShadow(
                        color: AppColors.purple.withOpacity(0.4),
                        blurRadius: 12,
                        spreadRadius: 1,
                      )
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              type.emoji,
              style: TextStyle(
                fontSize: 28,
                color: isUnlocked ? null : Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            type.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isUnlocked ? AppColors.textPrimary : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            type.description,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          if (isUnlocked && unlockedAt != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Unlocked',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.green,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
