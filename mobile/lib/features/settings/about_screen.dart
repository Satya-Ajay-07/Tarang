import 'package:flutter/material.dart';
import 'package:mobile/core/config/app_config.dart';
import 'package:mobile/core/theme/app_theme.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Tarang'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          children: [
            const SizedBox(height: AppTheme.spaceXL),
            // Logo / Branding Header
            Center(
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '🌊',
                        style: TextStyle(fontSize: 40),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                  const Text(
                    'Tarang',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                  const Text(
                    'The Ocean of Waves',
                    style: TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spaceXL),

            // App details card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Column(
                  children: [
                    _buildInfoRow('App Version', '1.0.0'),
                    const Divider(),
                    _buildInfoRow('Build Number', '101'),
                    const Divider(),
                    _buildInfoRow('Environment', 'Production'),
                    const Divider(),
                    _buildInfoRow('API Gateway URL', AppConfig.baseUrl),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceM),

            // Legal versions card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Column(
                  children: [
                    _buildInfoRow('Terms of Service Version', 'v1.0'),
                    const Divider(),
                    _buildInfoRow('Privacy Policy Version', 'v1.0'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppTheme.spaceXL),
            const Center(
              child: Text(
                '© 2026 Tarang Team. All rights reserved.',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
