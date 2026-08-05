import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/providers/theme_provider.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/settings/change_password_screen.dart';
import 'package:mobile/features/settings/deactivate_account_screen.dart';
import 'package:mobile/features/settings/delete_account_screen.dart';
import 'package:mobile/features/settings/support_screen.dart';
import 'package:mobile/features/settings/about_screen.dart';
import 'package:mobile/features/settings/providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showThemeSelector(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeProvider);

    showDialog(
      context: context,
      builder: (context) {
        var selectedTheme = currentTheme;

        return AlertDialog(
          title: const Text('Select Theme'),
          content: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: const Text('Light Mode'),
                    leading: Icon(
                      selectedTheme == ThemeMode.light
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selectedTheme == ThemeMode.light
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onTap: () {
                      setState(() => selectedTheme = ThemeMode.light);
                      ref
                          .read(themeProvider.notifier)
                          .setTheme(ThemeMode.light);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('Dark Mode'),
                    leading: Icon(
                      selectedTheme == ThemeMode.dark
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selectedTheme == ThemeMode.dark
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onTap: () {
                      setState(() => selectedTheme = ThemeMode.dark);
                      ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
                      Navigator.pop(context);
                    },
                  ),
                  ListTile(
                    title: const Text('System Default'),
                    leading: Icon(
                      selectedTheme == ThemeMode.system
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      color: selectedTheme == ThemeMode.system
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                    onTap: () {
                      setState(() => selectedTheme = ThemeMode.system);
                      ref
                          .read(themeProvider.notifier)
                          .setTheme(ThemeMode.system);
                      Navigator.pop(context);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showClearCacheConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear App Cache'),
        content: const Text(
          'This will clear all local image, feed, and profile caches. Do you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).clearAppCaches();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('App cache cleared successfully')),
              );
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final theme = ref.watch(themeProvider);

    String themeLabel = 'System';
    if (theme == ThemeMode.light) themeLabel = 'Light';
    if (theme == ThemeMode.dark) themeLabel = 'Dark';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          children: [
            // Account info summary
            if (user != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                color: Theme.of(context).colorScheme.surface,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 26,
                      backgroundImage:
                          user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                              ? NetworkImage(user.avatarUrl!)
                              : null,
                      child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                          ? const Icon(Icons.person, size: 28)
                          : null,
                    ),
                    const SizedBox(width: AppTheme.spaceM),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName ?? user.username,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '@${user.username}',
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            user.email,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Account section
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceM),
              child: Text(
                'Security & Access',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Change Password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const ChangePasswordScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: const Text('Email Verification Status'),
              subtitle: Text(
                  user?.isActive == true ? 'Verified' : 'Pending Verification'),
              trailing: user?.isActive == true
                  ? const Icon(Icons.check_circle, color: Colors.green)
                  : const Icon(Icons.warning, color: Colors.amber),
            ),

            const Divider(),

            // Appearance section
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceM),
              child: Text(
                'Preference Settings',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.palette_outlined),
              title: const Text('Appearance (Theme)'),
              subtitle: Text(themeLabel),
              onTap: () => _showThemeSelector(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.delete_sweep_outlined),
              title: const Text('Clear Cache'),
              onTap: () => _showClearCacheConfirmation(context, ref),
            ),

            const Divider(),

            // Support & Info section
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceM),
              child: Text(
                'Support & Legal',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryTeal),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.support_agent_outlined),
              title: const Text('Support Desk'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const SupportScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About Tarang'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const AboutScreen()),
                );
              },
            ),

            const Divider(),

            // Danger zone
            const Padding(
              padding: EdgeInsets.all(AppTheme.spaceM),
              child: Text(
                'Danger Zone',
                style:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.power_settings_new, color: Colors.amber),
              title: const Text('Deactivate Account'),
              textColor: Colors.amber.shade800,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const DeactivateAccountScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_forever, color: Colors.red),
              title: const Text('Delete Account Permanently'),
              textColor: Colors.red,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (context) => const DeleteAccountScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
