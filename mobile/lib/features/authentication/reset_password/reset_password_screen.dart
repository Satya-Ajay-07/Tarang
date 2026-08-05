import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/validators.dart';
import 'package:mobile/core/providers/core_providers.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String token;

  const ResetPasswordScreen({super.key, required this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleResetPassword() async {
    if (widget.token.isEmpty) {
      AppDialogs.showError(
        context: context,
        title: 'Error',
        message: 'No reset token found. Please request a new password reset email.',
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final repo = ref.read(authRepositoryProvider);
        final success = await repo.resetPassword(widget.token, _passwordController.text);

        if (success && mounted) {
          AppDialogs.showSuccess(
            context: context,
            title: 'Password Updated',
            message: 'Your password has been reset successfully. Please log in with your new password.',
            onConfirm: () => context.go('/login'),
          );
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showError(
            context: context,
            title: 'Reset Failed',
            message: e.toString(),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_open,
                size: 80,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(height: AppTheme.spaceM),
              const Text(
                'Enter New Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              const Text(
                'Please enter your new password below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: AppTheme.spaceL),
              PasswordField(
                labelText: 'New Password',
                controller: _passwordController,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: AppTheme.spaceM),
              PasswordField(
                labelText: 'Confirm Password',
                controller: _confirmPasswordController,
                validator: (value) => Validators.validateConfirmPassword(
                  value,
                  _passwordController.text,
                ),
              ),
              const SizedBox(height: AppTheme.spaceL),
              PrimaryButton(
                text: 'Update Password',
                onPressed: _handleResetPassword,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
