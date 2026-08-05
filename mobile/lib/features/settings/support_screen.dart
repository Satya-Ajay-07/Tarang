import 'package:flutter/material.dart';
import 'package:mobile/core/theme/app_theme.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  String _category = 'Feedback';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    
    // Simulate support submission
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support Submitted'),
        content: const Text(
          'Thank you! Your feedback has been sent to the Tarang team. We will contact you if needed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // dialog
              Navigator.pop(context); // screen
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Desk'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spaceM),
            children: [
              const Text(
                'How can we help you today?',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppTheme.spaceM),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Support Category',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Feedback', child: Text('Send Feedback')),
                  DropdownMenuItem(value: 'Bug', child: Text('Report a Bug')),
                  DropdownMenuItem(value: 'Request', child: Text('Feature Request')),
                  DropdownMenuItem(value: 'Account', child: Text('Account Security Issue')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _category = val;
                    });
                  }
                },
              ),
              const SizedBox(height: AppTheme.spaceM),
              TextFormField(
                controller: _messageController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: 'Message Details',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter details of your request';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spaceXL),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Submit to Tarang Support'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
