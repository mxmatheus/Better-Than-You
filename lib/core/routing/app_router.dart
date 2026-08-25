import 'package:flutter/material.dart';
import '../../domain/auth/auth_repository.dart';
import '../../presentation/auth/bootstrap_screen.dart';
import '../../presentation/auth/login_screen.dart';
import '../../presentation/auth/register_screen.dart';
import '../../presentation/daily/daily_challenge_screen.dart';
import '../../presentation/daily/daily_leaderboard_screen.dart';
import '../../presentation/match/match_screen.dart';
import '../../presentation/profile/profile_screen.dart';
import '../../presentation/shell/app_shell.dart';

abstract final class AppRoutes {
  static const String root = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String matchmaking = '/matchmaking';
  static const String match = '/match';
  static const String daily = '/daily';
  static const String dailyLeaderboard = '/daily-leaderboard';
  static const String profile = '/profile';
}

final class AppRouter {
  static Route<dynamic> generateRoute(
    RouteSettings settings, {
    AuthRepository? authRepository,
  }) {
    // Route protection: If unauthenticated, redirect protected destinations to login
    final isProtected = [
      AppRoutes.home,
      AppRoutes.match,
      AppRoutes.daily,
      AppRoutes.dailyLeaderboard,
      AppRoutes.profile,
    ].contains(settings.name);

    if (isProtected && authRepository != null && !authRepository.currentState.isAuthenticated) {
      return MaterialPageRoute(
        builder: (_) => LoginScreen(authRepository: authRepository),
        settings: settings,
      );
    }

    switch (settings.name) {
      case AppRoutes.root:
        return MaterialPageRoute(
          builder: (_) => BootstrapScreen(authRepository: authRepository),
          settings: settings,
        );
      case AppRoutes.login:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(authRepository: authRepository),
          settings: settings,
        );
      case AppRoutes.register:
        return MaterialPageRoute(
          builder: (_) => RegisterScreen(authRepository: authRepository),
          settings: settings,
        );
      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => AppShell(authRepository: authRepository),
          settings: settings,
        );
      case AppRoutes.match:
        return MaterialPageRoute(
          builder: (_) => const MatchScreen(),
          settings: settings,
        );
      case AppRoutes.daily:
        return MaterialPageRoute(
          builder: (_) => const DailyChallengeScreen(),
          settings: settings,
        );
      case AppRoutes.dailyLeaderboard:
        return MaterialPageRoute(
          builder: (_) => const DailyLeaderboardScreen(),
          settings: settings,
        );
      case AppRoutes.profile:
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(authRepository: authRepository),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
          settings: settings,
        );
    }
  }
}
