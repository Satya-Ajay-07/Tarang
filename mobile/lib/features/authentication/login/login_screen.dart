import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/utils/validators.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameOrEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _rememberMe = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  Future<void> _loadSavedCredentials() async {
    final storage = ref.read(secureStorageServiceProvider);
    final credentials = await storage.getCredentials();
    final rememberMe = await storage.getRememberMe();

    if (rememberMe && credentials['usernameOrEmail'] != null) {
      setState(() {
        _usernameOrEmailController.text = credentials['usernameOrEmail']!;
        _passwordController.text = credentials['password'] ?? '';
        _rememberMe = true;
      });
    }
  }

  @override
  void dispose() {
    _usernameOrEmailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(authProvider.notifier).login(
            _usernameOrEmailController.text.trim(),
            _passwordController.text,
            _rememberMe,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.checking;

    // Listen to error states
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        AppDialogs.showError(
          context: context,
          title: 'Login Error',
          message: next.errorMessage!,
        );
        ref.read(authProvider.notifier).clearError();
      } else if (next.status == AuthStatus.deactivated && next.errorMessage != null) {
        final days = next.deactivationDaysRemaining;
        final daysStr = days != null ? '\nRemaining cooldown: ${days.toStringAsFixed(1)} days.' : '';
        AppDialogs.showError(
          context: context,
          title: 'Account Deactivated',
          message: '${next.errorMessage!}$daysStr',
        );
        ref.read(authProvider.notifier).clearError();
      }
    });

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const AppLogo(size: 80),
                const SizedBox(height: AppTheme.spaceXL),
                Text(
                  'Welcome Back',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTheme.spaceM),
                CustomTextField(
                  labelText: 'Username or Email',
                  hintText: 'Enter your username or email',
                  controller: _usernameOrEmailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => Validators.validateRequired(value, 'Username or Email'),
                ),
                const SizedBox(height: AppTheme.spaceM),
                PasswordField(
                  labelText: 'Password',
                  controller: _passwordController,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: AppTheme.spaceS),
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (val) {
                        setState(() {
                          _rememberMe = val ?? false;
                        });
                      },
                    ),
                    const Text('Remember me'),
                    const Spacer(),
                    TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: const Text('Forgot Password?'),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spaceM),
                PrimaryButton(
                  text: 'Log In',
                  onPressed: _handleLogin,
                  isLoading: isLoading,
                ),
                const SizedBox(height: AppTheme.spaceM),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Don't have an account?"),
                    TextButton(
                      onPressed: () => context.push('/register'),
                      child: const Text('Register'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
