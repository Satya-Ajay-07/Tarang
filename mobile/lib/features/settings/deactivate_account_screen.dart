import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/settings/providers/settings_provider.dart';

class DeactivateAccountScreen extends ConsumerStatefulWidget {
  const DeactivateAccountScreen({super.key});

  @override
  ConsumerState<DeactivateAccountScreen> createState() =>
      _DeactivateAccountScreenState();
}

class _DeactivateAccountScreenState
    extends ConsumerState<DeactivateAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deactivation'),
        content: const Text(
          'Your account will be deactivated immediately. You can reactivate it within 7 days by logging back in.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:
                const Text('Deactivate', style: TextStyle(color: Colors.amber)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref
          .read(settingsProvider.notifier)
          .deactivateAccount(_passwordController.text);
      // Auth provider redirect handles navigation to Login automatically on logout
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Deactivate Account'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            children: [
              Card(
                color: _amberOpacity,
                child: Padding(
                  padding: EdgeInsets.all(AppTheme.spaceM),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚠️ Important Deactivation Notice',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: Colors.amber),
                      ),
                      SizedBox(height: AppTheme.spaceS),
                      Text(
                        '1. Your waves and profile will be hidden from other riders immediately.\n'
                        '2. You have a 7-day cooldown period. Logging back in before the end of the cooldown will automatically reactivate your account.\n'
                        '3. If you do not reactivate within 7 days, your account settings remain deactivated.',
                        style: TextStyle(height: 1.3, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXL),
              if (state.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppTheme.spaceM),
                  child: Text(
                    state.errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscureText,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                        _obscureText ? Icons.visibility : Icons.visibility_off),
                    onPressed: () =>
                        setState(() => _obscureText = !_obscureText),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty)
                    return 'Please enter your password to confirm';
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceXL),
              ElevatedButton(
                onPressed: state.isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber.shade700,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: state.isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Deactivate Account'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

const Color _amberOpacity = Color(0x11FFC107);
