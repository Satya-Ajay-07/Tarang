import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/shared/widgets/auth_shell.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/utils/validators.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';

class ResendVerificationScreen extends ConsumerStatefulWidget {
  const ResendVerificationScreen({super.key});

  @override
  ConsumerState<ResendVerificationScreen> createState() =>
      _ResendVerificationScreenState();
}

class _ResendVerificationScreenState
    extends ConsumerState<ResendVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  int _cooldownSeconds = 0;
  Timer? _timer;
  String? _inlineSuccess;
  String? _inlineError;

  @override
  void initState() {
    super.initState();
    final email = ref.read(authProvider).unverifiedEmail;
    if (email != null && email.isNotEmpty) {
      _emailController.text = email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldownSeconds = 60;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  Future<void> _handleResend() async {
    setState(() {
      _inlineSuccess = null;
      _inlineError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final repo = ref.read(authRepositoryProvider);
        final success = await repo.resendVerification(email);

        if (success) {
          _startCooldown();
          setState(() {
            _inlineSuccess = 'A new verification email has been sent. Please check your inbox.';
          });
        }
      } catch (e) {
        setState(() {
          _inlineError = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBackToLogin() async {
    // Perform logout to clear local authState/storage
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthShell(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                  const TarangLogo(size: 60.0, showText: false),
                  const SizedBox(height: 12),
                  Text(
                    'Email Verification',
                    style: AppTextStyles.h5.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pulsing mail envelope icon decoration
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                      .withValues(alpha: 0.1),
                ),
                child: Icon(
                  Icons.mail_outline_rounded,
                  color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                  size: 28,
                ),
              ),
            ),
            const SizedBox(height: 16),

            Text(
              'Verification Pending',
              textAlign: TextAlign.center,
              style: AppTextStyles.h5.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A verification link has been sent to your email. Please check your inbox (or simulated logs if in development mode) to activate your account.',
              textAlign: TextAlign.center,
              style: AppTextStyles.caption.copyWith(
                color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),

            Divider(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            const SizedBox(height: 16),

            // Inline Success / Error Banner
            if (_inlineSuccess != null) ...[
              Text(
                _inlineSuccess!,
                style: AppTextStyles.metadata.copyWith(
                  color: isDark ? AppTheme.successDark : AppTheme.successLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
            if (_inlineError != null) ...[
              Text(
                _inlineError!,
                style: AppTextStyles.metadata.copyWith(
                  color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],

            // Email Field
            TarangTextField(
              label: 'Registered Email',
              hint: 'rider@tarang.in',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 20),

            // Submit Button
            TarangButton(
              text: _cooldownSeconds > 0
                  ? 'Resend Link in $_cooldownSeconds s'
                  : 'Resend Verification Email',
              variant: TarangButtonVariant.primary,
              size: TarangButtonSize.lg,
              disabled: _cooldownSeconds > 0 || _isLoading,
              loading: _isLoading,
              onPressed: _handleResend,
            ),
            const SizedBox(height: 24),

            // Back to Login Link
            GestureDetector(
              onTap: _handleBackToLogin,
              child: Text(
                'Return to Login',
                style: AppTextStyles.metadata.copyWith(
                  color: AppTheme.foam,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
