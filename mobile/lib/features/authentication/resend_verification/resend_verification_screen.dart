import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
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
          if (mounted) {
            AppDialogs.showSuccess(
              context: context,
              title: 'Verification Sent',
              message:
                  'A new verification email has been sent to $email. Please check your inbox.',
            );
          }
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showError(
            context: context,
            title: 'Resend Failed',
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

  Future<void> _handleBackToLogin() async {
    // Perform logout to clear local authState/storage
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resend Verification'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBackToLogin,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 80,
                color: AppTheme.primaryTeal,
              ),
              const SizedBox(height: AppTheme.spaceM),
              const Text(
                'Verification Pending',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppTheme.spaceM),
              const Text(
                'Please verify your email address to access Tarang. If you did not receive the email, enter your email below to resend.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15),
              ),
              const SizedBox(height: AppTheme.spaceL),
              CustomTextField(
                labelText: 'Email Address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: AppTheme.spaceL),
              PrimaryButton(
                text: _cooldownSeconds > 0
                    ? 'Resend Link in $_cooldownSeconds s'
                    : 'Resend Verification Email',
                onPressed: _cooldownSeconds > 0 ? null : _handleResend,
                isLoading: _isLoading,
              ),
              const SizedBox(height: AppTheme.spaceM),
              SecondaryButton(
                text: 'Back to Login',
                onPressed: _handleBackToLogin,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
