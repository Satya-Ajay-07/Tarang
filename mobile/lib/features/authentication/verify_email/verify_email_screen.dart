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

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String token;

  const VerifyEmailScreen({super.key, required this.token});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  final _resendFormKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  bool _isLoading = true;
  bool _isSuccess = false;
  bool _isPending = false;
  String _message = 'Validating verification token with backend servers...';

  // Resend state
  bool _resending = false;
  String? _resendSuccess;
  String? _resendError;
  int _cooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.token.isEmpty) {
      // Pending state by default if no token
      setState(() {
        _isLoading = false;
        _isPending = true;
        _message = 'A verification link has been sent to your email. Please check your inbox.';
      });
    } else {
      _handleVerify();
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    setState(() {
      _cooldown = 60;
    });
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldown == 0) {
        timer.cancel();
      } else {
        setState(() {
          _cooldown--;
        });
      }
    });
  }

  Future<void> _handleVerify() async {
    try {
      final repo = ref.read(authRepositoryProvider);
      final success = await repo.verifyEmail(widget.token);
      setState(() {
        _isLoading = false;
        _isSuccess = success;
        _message = success
            ? 'Your verification was successful. Redirecting to Login...'
            : 'Email verification failed. The link may have expired or is invalid.';
      });

      if (success) {
        Timer(const Duration(seconds: 3), () {
          if (mounted) {
            context.go('/login');
          }
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = e.toString();
      });
    }
  }

  Future<void> _handleResend() async {
    if (_resendFormKey.currentState!.validate()) {
      setState(() {
        _resending = true;
        _resendSuccess = null;
        _resendError = null;
      });

      try {
        final email = _emailController.text.trim();
        final repo = ref.read(authRepositoryProvider);
        final success = await repo.resendVerification(email);

        if (success) {
          _startCooldown();
          setState(() {
            _resendSuccess = 'Verification email resent successfully! Please check your inbox.';
          });
        }
      } catch (e) {
        setState(() {
          _resendError = e.toString();
        });
      } finally {
        setState(() {
          _resending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget content;

    if (_isLoading) {
      // 1. Loading State
      content = Column(
        children: [
          const TarangLoading(size: 40.0),
          const SizedBox(height: 16),
          Text(
            _message,
            textAlign: TextAlign.center,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
          ),
        ],
      );
    } else if (_isSuccess) {
      // 2. Success State
      content = Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (isDark ? AppTheme.successDark : AppTheme.successLight)
                  .withValues(alpha: 0.1),
            ),
            child: Icon(
              Icons.check_rounded,
              color: isDark ? AppTheme.successDark : AppTheme.successLight,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Email Verified!',
            style: AppTextStyles.h5.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _message,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    } else {
      // 3 & 4. Error or Pending States (both show resend option)
      final showResendForm = !_isSuccess;

      content = Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isPending
                  ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                      .withValues(alpha: 0.1)
                  : (isDark ? AppTheme.dangerDark : AppTheme.dangerLight)
                      .withValues(alpha: 0.1),
            ),
            child: Icon(
              _isPending ? Icons.mail_outline_rounded : Icons.warning_amber_rounded,
              color: _isPending
                  ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                  : (isDark ? AppTheme.dangerDark : AppTheme.dangerLight),
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _isPending ? 'Verification Pending' : 'Verification Failed',
            style: AppTextStyles.h5.copyWith(
              color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _message,
            style: AppTextStyles.caption.copyWith(
              color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
            ),
            textAlign: TextAlign.center,
          ),
          if (showResendForm) ...[
            const SizedBox(height: 24),
            Divider(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            const SizedBox(height: 16),
            Form(
              key: _resendFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    "Didn't receive the email or verification link expired?",
                    style: AppTextStyles.label.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (_resendSuccess != null) ...[
                    Text(
                      _resendSuccess!,
                      style: AppTextStyles.metadata.copyWith(
                        color: isDark ? AppTheme.successDark : AppTheme.successLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  if (_resendError != null) ...[
                    Text(
                      _resendError!,
                      style: AppTextStyles.metadata.copyWith(
                        color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: TarangTextField(
                          hint: 'rider@tarang.in',
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          validator: Validators.validateEmail,
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        height: 48,
                        child: TarangButton(
                          text: _resending
                              ? 'Resending...'
                              : _cooldown > 0
                                  ? 'Wait ${_cooldown}s'
                                  : 'Resend',
                          variant: TarangButtonVariant.primary,
                          size: TarangButtonSize.sm,
                          disabled: _resending || _cooldown > 0,
                          onPressed: _handleResend,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => context.go('/login'),
            child: Text(
              'Back to Login',
              style: AppTextStyles.metadata.copyWith(
                color: AppTheme.foam,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    return AuthShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Screen title
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
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          content,
        ],
      ),
    );
  }
}
