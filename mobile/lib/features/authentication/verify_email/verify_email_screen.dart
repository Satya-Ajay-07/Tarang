import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/providers/core_providers.dart';

class VerifyEmailScreen extends ConsumerStatefulWidget {
  final String token;

  const VerifyEmailScreen({super.key, required this.token});

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isLoading = true;
  bool _isSuccess = false;
  String _message = 'Verifying your email address...';

  @override
  void initState() {
    super.initState();
    _handleVerify();
  }

  Future<void> _handleVerify() async {
    if (widget.token.isEmpty) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = 'No verification token provided. Please request a new link.';
      });
      return;
    }

    try {
      final repo = ref.read(authRepositoryProvider);
      final success = await repo.verifyEmail(widget.token);
      setState(() {
        _isLoading = false;
        _isSuccess = success;
        _message = success
            ? 'Your email address has been successfully verified! You can now log in to Tarang.'
            : 'Email verification failed. The link may have expired or is invalid.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _isSuccess = false;
        _message = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Verification'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ] else ...[
                Icon(
                  _isSuccess ? Icons.check_circle_outline : Icons.error_outline,
                  color: _isSuccess ? Colors.green : Colors.red,
                  size: 80,
                ),
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  _isSuccess
                      ? 'Verification Successful!'
                      : 'Verification Failed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: AppTheme.spaceM),
                Text(
                  _message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: AppTheme.spaceL),
                PrimaryButton(
                  text: 'Go to Login',
                  onPressed: () => context.go('/login'),
                ),
                if (!_isSuccess) ...[
                  const SizedBox(height: AppTheme.spaceM),
                  SecondaryButton(
                    text: 'Resend Verification Link',
                    onPressed: () => context.push('/resend-verification'),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
