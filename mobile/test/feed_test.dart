import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/features/home/providers/feed_provider.dart';

void main() {
  group('Feed State Tests', () {
    test('Initial feed state should be empty', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(feedProvider);
      expect(state.status, FeedStatus.loading);
      expect(state.waves, isEmpty);
      expect(state.errorMessage, isNull);
    });
  });
}
