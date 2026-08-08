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
  bool _showPassword = false;
  String? _inlineError;

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
    setState(() {
      _inlineError = null;
    });

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Listen to error states
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        setState(() {
          _inlineError = next.errorMessage;
        });
        ref.read(authProvider.notifier).clearError();
      } else if (next.status == AuthStatus.deactivated &&
          next.errorMessage != null) {
        final days = next.deactivationDaysRemaining;
        final daysStr = days != null
            ? '\nRemaining cooldown: ${days.toStringAsFixed(1)} days.'
            : '';
        setState(() {
          _inlineError = '${next.errorMessage!}$daysStr';
        });
        ref.read(authProvider.notifier).clearError();
      }
    });

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
                    'Welcome back to the Current',
                    style: AppTextStyles.h5.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sign in to start spreading your waves',
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

            // Username or Email
            TarangTextField(
              label: 'Username or Email',
              hint: 'Enter Correct Mail',
              controller: _usernameOrEmailController,
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  Validators.validateRequired(value, 'Username or Email'),
            ),
            const SizedBox(height: 16),

            // Password
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'PASSWORD',
                      style: AppTextStyles.label.copyWith(
                        color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot?',
                        style: AppTextStyles.label.copyWith(
                          color: AppTheme.foam,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TarangTextField(
                  hint: '••••••••',
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

            // Remember Me
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _rememberMe,
                    activeColor: AppTheme.foam,
                    onChanged: (val) {
                      setState(() {
                        _rememberMe = val ?? false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  child: Text(
                    'Remember my session',
                    style: AppTextStyles.caption.copyWith(
                      color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            TarangButton(
              text: isLoading ? 'Tuning in...' : 'Enter the Ocean',
              variant: TarangButtonVariant.primary,
              size: TarangButtonSize.lg,
              loading: isLoading,
              onPressed: _handleLogin,
            ),
            const SizedBox(height: 24),

            // Footer Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'New rider? ',
                  style: AppTextStyles.metadata.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.push('/register'),
                  child: Text(
                    'Create a Wave account',
                    style: AppTextStyles.metadata.copyWith(
                      color: AppTheme.foam,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
