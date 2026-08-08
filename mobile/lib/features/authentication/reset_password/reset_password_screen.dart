import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/shared/widgets/auth_shell.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/utils/validators.dart';
import 'package:mobile/core/providers/core_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  String? _inlineError;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    setState(() {
      _inlineError = null;
    });

    if (widget.token.isEmpty) {
      setState(() {
        _inlineError = 'No reset token found. Please request a new password reset email.';
      });
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final repo = ref.read(authRepositoryProvider);
        final success =
            await repo.resetPassword(widget.token, _passwordController.text);

        if (success && mounted) {
          AppDialogs.showSuccess(
            context: context,
            title: 'Password Updated',
            message:
                'Your password has been reset successfully. Please log in with your new password.',
            onConfirm: () => context.go('/login'),
          );
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
                    'Enter New Password',
                    style: AppTextStyles.h5.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please enter your new password below.',
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

            // New Password
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEW PASSWORD',
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                TarangTextField(
                  hint: 'Min 8 characters',
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  validator: Validators.validatePassword,
                  rightIcon: GestureDetector(
                    onTap: () => setState(() => _showPassword = !_showPassword),
                    child: Icon(
                      _showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Confirm Password
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONFIRM PASSWORD',
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                TarangTextField(
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  validator: (value) => Validators.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                  rightIcon: GestureDetector(
                    onTap: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                    child: Icon(
                      _showConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            TarangButton(
              text: _isLoading ? 'Updating...' : 'Update Password',
              variant: TarangButtonVariant.primary,
              size: TarangButtonSize.lg,
              loading: _isLoading,
              onPressed: _handleResetPassword,
            ),
          ],
        ),
      ),
    );
  }
}
