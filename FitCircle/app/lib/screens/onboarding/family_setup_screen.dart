// lib/screens/onboarding/family_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/app_theme.dart';

class FamilySetupScreen extends StatefulWidget {
  const FamilySetupScreen({super.key});

  @override
  State<FamilySetupScreen> createState() => _FamilySetupScreenState();
}

class _FamilySetupScreenState extends State<FamilySetupScreen> {
  final _createNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  bool _isCreating = true;

  @override
  void dispose() {
    _createNameController.dispose();
    _joinCodeController.dispose();
    super.dispose();
  }

  Future<void> _handleAction() async {
    final auth = context.read<AuthProvider>();

    if (_isCreating) {
      final name = _createNameController.text.trim();
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a family name')),
        );
        return;
      }
      final success = await auth.createFamily(name);
      if (mounted && success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else if (mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!)),
        );
      }
    } else {
      final code = _joinCodeController.text.trim().toUpperCase();
      if (code.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a family code')),
        );
        return;
      }
      final success = await auth.joinFamily(code);
      if (mounted && success) {
        Navigator.pushReplacementNamed(context, '/main');
      } else if (mounted && auth.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(auth.errorMessage!)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Circle'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set Up Your Circle',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create a new circle for your family or join an existing one with a code.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // Segmented Toggle
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.bgCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isCreating = true),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: _isCreating ? AppColors.mainGradient : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Create Circle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _isCreating ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isCreating = false),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: !_isCreating ? AppColors.mainGradient : null,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Join Circle',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: !_isCreating ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              if (_isCreating) ...[
                const Text('Family Circle Name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _createNameController,
                  decoration: const InputDecoration(
                    hintText: 'e.g. The Sharma Family',
                    prefixIcon: Icon(Icons.people_outline, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A unique code (like FIT-7K92X) will be generated for your family members to join.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ] else ...[
                const Text('Family Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 8),
                TextField(
                  controller: _joinCodeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    hintText: 'e.g. FIT-7K92X',
                    prefixIcon: Icon(Icons.qr_code, color: AppColors.textMuted),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ask the creator of your family circle for their 9-character family code.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: auth.isLoading ? null : _handleAction,
                child: auth.isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(_isCreating ? 'Create Family Circle' : 'Join Family Circle'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
