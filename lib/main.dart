import 'package:flutter/material.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BetterThanYouApp());
}

class BetterThanYouApp extends StatelessWidget {
  const BetterThanYouApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BETTER THAN YOU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.home,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
