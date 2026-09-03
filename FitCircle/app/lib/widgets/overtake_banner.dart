// lib/widgets/overtake_banner.dart
import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class OvertakeBanner extends StatelessWidget {
  final String message;

  const OvertakeBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isEmpty) return const SizedBox.shrink();

    final isFirst = message.contains('#1');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        gradient: isFirst
            ? LinearGradient(
                colors: [AppColors.gold.withOpacity(0.3), AppColors.orange.withOpacity(0.2)],
              )
            : AppColors.mainGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: (isFirst ? AppColors.gold : AppColors.purple).withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Icon(
            isFirst ? Icons.emoji_events : Icons.bolt,
            color: Colors.white,
            size: 28,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
