import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/settings/providers/settings_provider.dart';

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _checkPasswordStrength(String password) {
    if (password.length < 8) return 'Too Short (Min 8)';
    bool hasUppercase = password.contains(RegExp(r'[A-Z]'));
    bool hasDigits = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialCharacters = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

    int score = 0;
    if (hasUppercase) score++;
    if (hasDigits) score++;
    if (hasSpecialCharacters) score++;

    if (score == 3) return 'Strong 💪';
    if (score == 2) return 'Moderate 😐';
    return 'Weak ⚠️';
  }

  Color _getStrengthColor(String strength) {
    if (strength.contains('Strong')) return Colors.green;
    if (strength.contains('Moderate')) return Colors.amber;
    return Colors.red;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(settingsProvider.notifier).changePassword(
          currentPassword: _currentController.text,
          newPassword: _newController.text,
        );

    final state = ref.read(settingsProvider);
    if (state.isSuccess) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Password Changed'),
            content: const Text('Your password has been successfully updated.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // pop dialog
                  Navigator.pop(context); // pop screen
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);
    final strength = _checkPasswordStrength(_newController.text);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Change Password'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            children: [
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              TextFormField(
                controller: _currentController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter current password';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceM),
              TextFormField(
                controller: _newController,
                obscureText: _obscureNew,
                onChanged: (val) => setState(() {}), // Trigger strength rebuild
                decoration: InputDecoration(
                  labelText: 'New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Enter new password';
                  if (val.length < 8) return 'Password must be at least 8 characters';
                  return null;
                },
              ),
              if (_newController.text.isNotEmpty) ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('Strength: ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    Text(
                      strength,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStrengthColor(strength),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: AppTheme.spaceM),
              TextFormField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                validator: (val) {
                  if (val != _newController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceXL),
              ElevatedButton(
                onPressed: state.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: state.isSubmitting
                    ? const CircularProgressIndicator()
                    : const Text('Update Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
