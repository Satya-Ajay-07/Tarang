import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/shared/widgets/auth_shell.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/utils/validators.dart';
import 'package:mobile/core/providers/core_providers.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _success = false;
  String? _inlineError;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleForgotPassword() async {
    setState(() {
      _inlineError = null;
    });

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        final repo = ref.read(authRepositoryProvider);
        final result = await repo.forgotPassword(email);

        if (result) {
          setState(() {
            _success = true;
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AuthShell(
      child: _success
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Column(
                    children: [
                      const TarangLogo(size: 60.0, showText: false),
                      const SizedBox(height: 24),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isDark ? AppTheme.successDark : AppTheme.successLight)
                              .withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          Icons.mark_email_read_outlined,
                          color: isDark ? AppTheme.successDark : AppTheme.successLight,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Instructions Sent',
                        style: AppTextStyles.h5.copyWith(
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We have dispatched a reset link. Please check your inbox (or simulated logs).',
                        style: AppTextStyles.caption.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                TarangButton(
                  text: 'Back to Login',
                  variant: TarangButtonVariant.primary,
                  size: TarangButtonSize.lg,
                  onPressed: () => context.go('/login'),
                ),
              ],
            )
          : Form(
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
                          'Restore Account Flow',
                          style: AppTextStyles.h5.copyWith(
                            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Enter your email to receive a password reset token link',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Inline Error Banner
                  if (_inlineError != null) ...[
                    Container(
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.dangerDark : AppTheme.dangerLight)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (isDark ? AppTheme.dangerDark : AppTheme.dangerLight)
                              .withValues(alpha: 0.2),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _inlineError!,
                              style: AppTextStyles.metadata.copyWith(
                                color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Email
                  TarangTextField(
                    label: 'Registered Email',
                    hint: 'e.g. ajay@tarang.in',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.validateEmail,
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  TarangButton(
                    text: _isLoading ? 'Sending link...' : 'Send Reset Link',
                    variant: TarangButtonVariant.primary,
                    size: TarangButtonSize.lg,
                    loading: _isLoading,
                    onPressed: _handleForgotPassword,
                  ),
                  const SizedBox(height: 24),

                  // Cancel Link
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Cancel and return to Login',
                      style: AppTextStyles.metadata.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
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
