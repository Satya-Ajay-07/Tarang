import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/notifications/providers/notification_providers.dart';

void main() {
  group('Bookmark State Tests', () {
    test('Initial bookmarks state should be empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(bookmarkProvider);
      expect(state.isLoading, isTrue);
      expect(state.bookmarks, isEmpty);
    });
  });
}
