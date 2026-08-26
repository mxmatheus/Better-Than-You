import 'package:flutter/foundation.dart';

abstract final class AuthLogger {
  static void log(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[AUTH][$tag] $message');
    }
  }

  static String maskEmail(String email) {
    final trimmed = email.trim();
    if (!trimmed.contains('@')) return '***';
    final parts = trimmed.split('@');
    final name = parts[0];
    final domain = parts.length > 1 ? parts[1] : '';

    if (name.length <= 2) {
      return '${name[0]}*@$domain';
    }
    final first = name[0];
    final last = name[name.length - 1];
    final maskedLength = name.length - 2;
    final stars = '*' * (maskedLength > 6 ? 6 : maskedLength);
    return '$first$stars$last@$domain';
  }

  // Registration logging
  static void registerStart({required String email, required String username}) {
    log('REGISTER', 'start email=${maskEmail(email)} username=$username');
  }

  static void registerSuccess({
    required String userId,
    required String username,
  }) {
    log(
      'REGISTER',
      'success userId=$userId username=$username profileProvisioned=true',
    );
  }

  static void registerFailure({
    required String errorType,
    int? statusCode,
    String? code,
    required String message,
    String? mappedError,
  }) {
    final statusStr = statusCode != null ? ' statusCode=$statusCode' : '';
    final codeStr = code != null ? ' code=$code' : '';
    final mappedStr = mappedError != null ? ' mappedError=$mappedError' : '';
    log(
      'REGISTER',
      'failure errorType=$errorType$statusStr$codeStr message="$message"$mappedStr',
    );
  }

  // Login logging
  static void loginStart({required String email}) {
    log('LOGIN', 'start email=${maskEmail(email)}');
  }

  static void loginSuccess({required String userId, required String username}) {
    log('LOGIN', 'success userId=$userId username=$username');
  }

  static void loginFailure({
    required String errorType,
    int? statusCode,
    String? code,
    required String message,
    String? mappedError,
  }) {
    final statusStr = statusCode != null ? ' statusCode=$statusCode' : '';
    final codeStr = code != null ? ' code=$code' : '';
    final mappedStr = mappedError != null ? ' mappedError=$mappedError' : '';
    log(
      'LOGIN',
      'failure errorType=$errorType$statusStr$codeStr message="$message"$mappedStr',
    );
  }

  // Google OAuth logging
  static void googleStart({required String redirectTo}) {
    log('GOOGLE', 'start provider=google redirectTo=$redirectTo');
  }

  static void googleLaunched() {
    log('GOOGLE', 'OAuth browser window launched');
  }

  static void googleSuccess({
    required String userId,
    required String username,
  }) {
    log(
      'GOOGLE',
      'success userId=$userId username=$username profileVerified=true',
    );
  }

  static void googleFailure({
    required String errorType,
    int? statusCode,
    String? code,
    required String message,
    String? mappedError,
  }) {
    final statusStr = statusCode != null ? ' statusCode=$statusCode' : '';
    final codeStr = code != null ? ' code=$code' : '';
    final mappedStr = mappedError != null ? ' mappedError=$mappedError' : '';
    log(
      'GOOGLE',
      'failure errorType=$errorType$statusStr$codeStr message="$message"$mappedStr',
    );
  }

  // Deep Link logging
  static void deepLinkReceived({required String uri}) {
    final safeUri = uri.replaceAll(
      RegExp(r'(access_token|refresh_token|code|id_token)=[^&#]+'),
      r'$1=***',
    );
    log('DEEPLINK', 'received uri=$safeUri');
  }

  // Session lifecycle logging
  static void sessionRestoreStart() {
    log('SESSION', 'restoreSession start');
  }

  static void sessionRestored({
    required String userId,
    required String username,
  }) {
    log('SESSION', 'session restored for user=$userId username=$username');
  }

  static void sessionNotFound() {
    log('SESSION', 'no active session found (unauthenticated)');
  }

  static void authStateChanged({required String event, String? userId}) {
    final userStr = userId != null ? ' userId=$userId' : '';
    log('SESSION', 'auth state changed event=$event$userStr');
  }

  static void routerTransition({required String destination}) {
    log('ROUTER', 'authenticated -> $destination');
  }

  static void signOut() {
    log('SESSION', 'signOut called');
  }
}
