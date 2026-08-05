import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/notifications/providers/notification_providers.dart';

void main() {
  group('Notifications State Tests', () {
    test('Initial notifications state should be empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(notificationProvider);
      expect(state.isLoading, isTrue);
      expect(state.alerts, isEmpty);
    });

    test('Initial unread count should be zero', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final unreadCount = container.read(unreadCountProvider);
      expect(unreadCount, 0);
    });
  });
}
