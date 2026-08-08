import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/shared/widgets/auth_shell.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/utils/validators.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';

// ISO Country List from Web Page.tsx
class CountryInfo {
  final String code;
  final String name;
  final String dialCode;
  const CountryInfo({required this.code, required this.name, required this.dialCode});
}

const List<CountryInfo> countries = [
  CountryInfo(code: 'IN', name: 'India', dialCode: '+91'),
  CountryInfo(code: 'US', name: 'United States', dialCode: '+1'),
  CountryInfo(code: 'GB', name: 'United Kingdom', dialCode: '+44'),
  CountryInfo(code: 'CA', name: 'Canada', dialCode: '+1'),
  CountryInfo(code: 'AU', name: 'Australia', dialCode: '+61'),
  CountryInfo(code: 'DE', name: 'Germany', dialCode: '+49'),
  CountryInfo(code: 'FR', name: 'France', dialCode: '+33'),
  CountryInfo(code: 'AE', name: 'United Arab Emirates', dialCode: '+971'),
  CountryInfo(code: 'SG', name: 'Singapore', dialCode: '+65'),
];

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();

  CountryInfo _selectedCountry = countries.first;
  bool _showPassword = false;
  String? _inlineError;

  // Password strength state
  int _strengthScore = 0;
  String _strengthText = 'Very Weak';
  Color _strengthColor = Colors.red;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  void _checkPasswordStrength() {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() {
        _strengthScore = 0;
        _strengthText = 'Very Weak';
        _strengthColor = Colors.red;
      });
      return;
    }

    int score = 0;
    if (password.length >= 8) score += 1;
    if (password.contains(RegExp(r'[A-Z]'))) score += 1;
    if (password.contains(RegExp(r'[0-9]'))) score += 1;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score += 1;

    String text = 'Very Weak';
    Color color = Colors.red;

    if (score == 2) {
      text = 'Weak';
      color = Colors.orange;
    } else if (score == 3) {
      text = 'Medium';
      color = Colors.yellow;
    } else if (score == 4) {
      text = 'Strong';
      color = const Color(0xFF10B981);
    }

    setState(() {
      _strengthScore = score;
      _strengthText = text;
      _strengthColor = color;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _fullNameController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    setState(() {
      _inlineError = null;
    });

    if (_formKey.currentState!.validate()) {
      final phoneRaw = _phoneController.text.trim();
      final cleanedPhone = phoneRaw.replaceAll(RegExp(r'\D'), '');
      if (phoneRaw.isNotEmpty && (cleanedPhone.length < 8 || cleanedPhone.length > 15)) {
        setState(() {
          _inlineError = 'Please enter a valid phone number (8-15 digits).';
        });
        return;
      }

      final fullPhoneNumber = phoneRaw.isNotEmpty
          ? '${_selectedCountry.dialCode} $phoneRaw'
          : null;

      await ref.read(authProvider.notifier).register(
            email: _emailController.text.trim(),
            username: _usernameController.text.trim(),
            password: _passwordController.text,
            fullName: _fullNameController.text.trim().isEmpty
                ? null
                : _fullNameController.text.trim(),
            country: _selectedCountry.name,
            phoneNumber: fullPhoneNumber,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.status == AuthStatus.checking;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next.status == AuthStatus.error && next.errorMessage != null) {
        setState(() {
          _inlineError = next.errorMessage;
        });
        ref.read(authProvider.notifier).clearError();
      } else if (next.status == AuthStatus.unverified) {
        TarangSnackbar.show(
          context,
          'Registration successful. Check email for validation link.',
          isSuccess: true,
        );
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
                    'Create your Wave Circle Identity',
                    style: AppTextStyles.h5.copyWith(
                      color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Every Voice Creates a Wave',
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

            // Fields Grid/Layout
            TarangTextField(
              label: 'Full Name',
              hint: 'Enter your name',
              controller: _fullNameController,
              validator: (value) =>
                  Validators.validateRequired(value, 'Full Name'),
            ),
            const SizedBox(height: 16),

            TarangTextField(
              label: 'Username',
              hint: 'Choose a username',
              controller: _usernameController,
              validator: Validators.validateUsername,
              onChanged: (val) {
                // Sourced from web signup lowercase + character replacements
                final clean = val.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_]'), '');
                if (clean != val) {
                  _usernameController.value = TextEditingValue(
                    text: clean,
                    selection: TextSelection.collapsed(offset: clean.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),

            TarangTextField(
              label: 'Email Address',
              hint: 'Enter your email address',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: Validators.validateEmail,
            ),
            const SizedBox(height: 16),

            // Country Dropdown
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COUNTRY',
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<CountryInfo>(
                  initialValue: _selectedCountry,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                  dropdownColor: isDark ? AppTheme.darkCard : AppTheme.lightCard,
                  items: countries
                      .map((c) => DropdownMenuItem<CountryInfo>(
                            value: c,
                            child: Text(
                              '${c.name} (${c.dialCode})',
                              style: AppTextStyles.caption.copyWith(
                                color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                              ),
                            ),
                          ))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedCountry = val;
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Phone Number
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PHONE NUMBER',
                  style: AppTextStyles.label.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 48,
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.darkSurface.withValues(alpha: 0.4)
                            : AppTheme.lightSurface.withValues(alpha: 0.4),
                        border: Border.all(
                          color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _selectedCountry.dialCode,
                        style: AppTextStyles.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TarangTextField(
                        hint: 'Enter your phone number',
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Password
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PASSWORD',
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
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Strength: $_strengthText',
                        style: AppTextStyles.metadata.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '$_strengthScore/4',
                        style: AppTextStyles.metadata.copyWith(
                          color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: _strengthScore / 4,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _strengthColor,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Submit Button
            TarangButton(
              text: isLoading ? 'Launching Wave Account...' : 'Join the Ocean',
              variant: TarangButtonVariant.primary,
              size: TarangButtonSize.lg,
              loading: isLoading,
              onPressed: _handleRegister,
            ),
            const SizedBox(height: 24),

            // Footer Link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already registered? ',
                  style: AppTextStyles.metadata.copyWith(
                    color: isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight,
                  ),
                ),
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Text(
                    'Sign In',
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
