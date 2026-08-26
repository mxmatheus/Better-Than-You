import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/logging/auth_logger.dart';
import '../../core/routing/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../domain/auth/auth_error.dart';
import '../../domain/auth/auth_repository.dart';
import '../../domain/auth/auth_state.dart';
import '../../domain/auth/local_auth_repository.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository? authRepository;

  const LoginScreen({super.key, this.authRepository});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final AuthRepository _authRepository;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  StreamSubscription<AppAuthState>? _authSubscription;
  bool _isLoading = false;
  bool _isGoogleLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _authRepository = widget.authRepository ?? LocalAuthRepository();
    _authSubscription = _authRepository.authStateChanges.listen((state) {
      if (state is AuthAuthenticated && mounted) {
        AuthLogger.routerTransition(destination: 'AppShell');
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate() || _isLoading || _isGoogleLoading) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on AuthError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid email or password. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading || _isGoogleLoading) return;

    setState(() {
      _isGoogleLoading = true;
      _errorMessage = null;
    });

    try {
      await _authRepository.signInWithGoogle();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } on AuthError catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.message;
        _isGoogleLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Google sign-in failed. Please try again.';
        _isGoogleLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 32.0,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Brand Header
                  const Text(
                    'BETTER\nTHAN YOU',
                    style: AppTypography.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'PROVE IT.',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      letterSpacing: 3.0,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),

                  // Error Banner
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.loss.withAlpha(30),
                        border: Border.all(color: AppColors.loss),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 18,
                            color: AppColors.loss,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.loss,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Google Sign-In Button
                  OutlinedButton.icon(
                    onPressed: _isGoogleLoading || _isLoading
                        ? null
                        : _handleGoogleSignIn,
                    icon: _isGoogleLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.g_mobiledata,
                            size: 28,
                            color: AppColors.textPrimary,
                          ),
                    label: Text(
                      'CONTINUE WITH GOOGLE',
                      style: AppTypography.badgeText.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 12,
                        letterSpacing: 1.2,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.surfaceBorder,
                        width: 1.5,
                      ),
                      backgroundColor: AppColors.surface,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      const Expanded(
                        child: Divider(color: AppColors.surfaceBorder),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Divider(color: AppColors.surfaceBorder),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Email Input
                  Text(
                    'EMAIL',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      hintText: 'player@example.com',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.surfaceBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.surfaceBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.contains('@') || !value.contains('.')) {
                        return 'Enter a valid email address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),

                  // Password Input
                  Text(
                    'PASSWORD',
                    style: AppTypography.badgeText.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: AppTypography.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surface,
                      hintText: '••••••••',
                      hintStyle: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                      border: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.surfaceBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.surfaceBorder,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading || _isGoogleLoading
                        ? null
                        : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.background,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.background,
                            ),
                          )
                        : Text(
                            'ENTER ARENA',
                            style: AppTypography.badgeText.copyWith(
                              color: AppColors.background,
                              fontSize: 14,
                            ),
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Link to Register
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "DON'T HAVE AN ACCOUNT? ",
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(
                          context,
                        ).pushReplacementNamed(AppRoutes.register),
                        child: Text(
                          'REGISTER',
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
