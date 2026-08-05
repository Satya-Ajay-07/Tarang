import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  const DeepLinkService._();

  static void handleDeepLink(BuildContext context, String urlString) {
    try {
      final uri = Uri.parse(urlString);
      final path = uri.path;

      // Handle Verification links
      if (path.contains('/verify-email')) {
        final token = uri.queryParameters['token'] ?? '';
        context.push('/verify-email?token=$token');
      }
      // Handle Password Reset links
      else if (path.contains('/reset-password')) {
        final token = uri.queryParameters['token'] ?? '';
        context.push('/reset-password?token=$token');
      }
      // Handle Profile links
      else if (path.contains('/you/')) {
        context.push('/home');
      }
      // Handle Hashtag links
      else if (path.contains('/hashtags/')) {
        context.push('/home');
      }
    } catch (_) {}
  }
}
