import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/authentication/login/login_screen.dart';
import 'package:mobile/features/authentication/register/register_screen.dart';
import 'package:mobile/features/authentication/forgot_password/forgot_password_screen.dart';
import 'package:mobile/features/authentication/reset_password/reset_password_screen.dart';
import 'package:mobile/features/authentication/verify_email/verify_email_screen.dart';
import 'package:mobile/features/authentication/resend_verification/resend_verification_screen.dart';
import 'package:mobile/features/home/home_screen.dart';
import 'package:mobile/features/splash/splash_screen.dart';
import 'package:mobile/features/home/composer/compose_screen.dart';
import 'package:mobile/core/models/wave_model.dart';

final appRouterHelperProvider = Provider<AppRouterHelper>((ref) {
  return AppRouterHelper(ref);
});

class AppRouterHelper {
  final Ref _ref;
  AppRouterHelper(this._ref);

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authProvider);
    final status = authState.status;
    final path = state.uri.path;

    // While checking session, stay on splash screen
    if (status == AuthStatus.checking) {
      if (path != '/splash') {
        return '/splash';
      }
      return null;
    }

    final isAtSplashOrRoot = path == '/splash' || path == '/';

    switch (status) {
      case AuthStatus.checking:
        return null;

      case AuthStatus.authenticated:
        final isAuthRoute = path == '/login' ||
            path == '/register' ||
            path == '/forgot-password' ||
            path == '/reset-password' ||
            path == '/verify-email' ||
            path == '/resend-verification';
        if (isAtSplashOrRoot || isAuthRoute) {
          return '/home';
        }
        return null;

      case AuthStatus.unverified:
        if (path != '/verify-email' && path != '/resend-verification') {
          return '/resend-verification';
        }
        return null;

      case AuthStatus.initial:
      case AuthStatus.deactivated:
      case AuthStatus.error:
        final isPublicRoute = path == '/login' ||
            path == '/register' ||
            path == '/forgot-password' ||
            path == '/reset-password' ||
            path == '/verify-email' ||
            path == '/resend-verification';
        if (isAtSplashOrRoot || !isPublicRoute) {
          return '/login';
        }
        return null;
    }
  }
}

final routerListenableProvider = Provider<RouterListenable>((ref) {
  final listenable = RouterListenable();
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.status != next.status) {
      listenable.notify();
    }
  });
  return listenable;
});

class RouterListenable extends ChangeNotifier {
  void notify() {
    notifyListeners();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final routerHelper = ref.watch(appRouterHelperProvider);
  final listenable = ref.read(routerListenableProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: routerHelper.redirect,
    refreshListenable: listenable,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ResetPasswordScreen(token: token);
        },
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return VerifyEmailScreen(token: token);
        },
      ),
      GoRoute(
        path: '/resend-verification',
        builder: (context, state) => const ResendVerificationScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: '/compose',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final editWave = extra?['editWave'] as WaveModel?;
          final spreadFromWave = extra?['spreadFromWave'] as WaveModel?;
          return ComposeScreen(
            editWave: editWave,
            spreadFromWave: spreadFromWave,
          );
        },
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Route error: ${state.error}'),
      ),
    ),
  );
});

