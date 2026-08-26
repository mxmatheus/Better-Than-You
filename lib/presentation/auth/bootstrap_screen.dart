import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/logging/auth_logger.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_state.dart';
import '../../domain/auth/local_auth_repository.dart';

class BootstrapScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const BootstrapScreen({super.key, this.authRepository});

  @override
  State<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends State<BootstrapScreen> {
  late final AuthRepository _authRepository;
  StreamSubscription<AppAuthState>? _authSubscription;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? LocalAuthRepository();

    _authSubscription = _authRepository.authStateChanges.listen((state) {
      if (state is AuthAuthenticated && mounted && !_hasNavigated) {
        _navigateHome();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _hasNavigated) return;
      if (_authRepository.currentState.isAuthenticated) {
        _navigateHome();
      } else {
        _bootstrap();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  void _navigateHome() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    AuthLogger.routerTransition(destination: 'AppShell');
    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  void _navigateLogin() {
    if (_hasNavigated || !mounted) return;
    _hasNavigated = true;
    Navigator.of(context).pushReplacementNamed(AppRoutes.login);
  }

  Future<void> _bootstrap() async {
    final profile = await _authRepository.restoreSession();
    if (!mounted || _hasNavigated) return;

    if (profile != null) {
      _navigateHome();
    } else {
      // Allow brief grace period for asynchronous OAuth deep link tokens
      await Future.delayed(const Duration(milliseconds: 300));
      if (!mounted || _hasNavigated) return;

      if (_authRepository.currentState.isAuthenticated) {
        _navigateHome();
      } else {
        _navigateLogin();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'BETTER THAN YOU',
              style: AppTypography.displayLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
