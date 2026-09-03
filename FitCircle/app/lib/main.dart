// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'config/supabase_config.dart';
import 'providers/auth_provider.dart';
import 'providers/fitcircle_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/onboarding/family_setup_screen.dart';
import 'screens/main_navigation_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env configuration
  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fallback if .env file is missing in dev
  }

  // Initialize Supabase client
  await SupabaseConfig.initialize();

  runApp(const FitCircleApp());
}

class FitCircleApp extends StatelessWidget {
  const FitCircleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => FitCircleProvider()),
      ],
      child: MaterialApp(
        title: 'FitCircle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/forgot-password': (context) => const ForgotPasswordScreen(),
          '/family-setup': (context) => const FamilySetupScreen(),
          '/main': (context) => const MainNavigationScreen(),
        },
      ),
    );
  }
}
