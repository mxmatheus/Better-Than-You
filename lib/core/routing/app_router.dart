import 'package:flutter/material.dart';
import '../../presentation/daily/daily_challenge_screen.dart';
import '../../presentation/daily/daily_leaderboard_screen.dart';
import '../../presentation/home/home_screen.dart';
import '../../presentation/match/match_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String matchmaking = '/matchmaking';
  static const String match = '/match';
  static const String daily = '/daily';
  static const String dailyLeaderboard = '/daily-leaderboard';
  static const String profile = '/profile';
}

final class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.match:
        return MaterialPageRoute(builder: (_) => const MatchScreen());
      case AppRoutes.daily:
        return MaterialPageRoute(builder: (_) => const DailyChallengeScreen());
      case AppRoutes.dailyLeaderboard:
        return MaterialPageRoute(builder: (_) => const DailyLeaderboardScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
