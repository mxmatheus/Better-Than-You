import 'package:flutter/material.dart';
import '../../presentation/home/home_screen.dart';

abstract final class AppRoutes {
  static const String home = '/';
  static const String matchmaking = '/matchmaking';
  static const String match = '/match';
  static const String daily = '/daily';
  static const String profile = '/profile';
}

final class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Route not found')),
          ),
        );
    }
  }
}
