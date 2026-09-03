// lib/screens/family/family_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/fitcircle_provider.dart';
import '../../config/app_theme.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final fitcircle = context.watch<FitCircleProvider>();
    final family = auth.family;

    return Scaffold(
      appBar: AppBar(
        title: Text(family?.familyName ?? 'My Family Circle'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Family Code Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.borderAccent),
              ),
              child: Column(
                children: [
                  const Text('FAMILY INVITE CODE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5, color: AppColors.orange)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SelectableText(
                        family?.familyCode ?? 'FIT-7K92X',
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.copy, color: AppColors.purpleLight, size: 20),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: family?.familyCode ?? 'FIT-7K92X'));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Family code copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Share this code with your family members to let them join your circle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'FAMILY MEMBERS',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: AppColors.textMuted),
            ),
            const SizedBox(height: 12),

            if (fitcircle.leaderboard.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              ...fitcircle.leaderboard.map((member) {
                final isMe = member.userId == auth.currentUser?.id;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isMe ? AppColors.purpleLight : AppColors.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.purple.withOpacity(0.3),
                        backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                        child: member.avatarUrl == null
                            ? Text(member.name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white))
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (isMe) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.purple, borderRadius: BorderRadius.circular(6)),
                                    child: const Text('YOU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Position #${member.rank} · ${member.steps} steps today',
                              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                      Text(member.medal, style: const TextStyle(fontSize: 22)),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
