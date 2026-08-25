import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'domain/auth/auth_repository.dart';
import 'domain/auth/local_auth_repository.dart';
import 'domain/auth/supabase_auth_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  AuthRepository authRepo;
  if (SupabaseConfig.isConfigured) {
    try {
      authRepo = SupabaseAuthRepository(client: Supabase.instance.client);
    } catch (_) {
      authRepo = LocalAuthRepository();
    }
  } else {
    authRepo = LocalAuthRepository();
  }

  runApp(BetterThanYouApp(authRepository: authRepo));
}

class BetterThanYouApp extends StatelessWidget {
  final AuthRepository? authRepository;

  const BetterThanYouApp({super.key, this.authRepository});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BETTER THAN YOU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      initialRoute: AppRoutes.root,
      onGenerateRoute: (settings) =>
          AppRouter.generateRoute(settings, authRepository: authRepository),
    );
  }
}
