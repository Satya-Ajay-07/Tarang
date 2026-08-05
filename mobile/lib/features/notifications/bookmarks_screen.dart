import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/notifications/providers/notification_providers.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';

class BookmarksScreen extends ConsumerWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bookmarkProvider);
    final notifier = ref.read(bookmarkProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saved Bookmarks 🔖'),
      ),
      body: SafeArea(
        child: state.isLoading && state.bookmarks.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                        const SizedBox(height: AppTheme.spaceM),
                        Text(state.errorMessage!),
                        const SizedBox(height: AppTheme.spaceM),
                        ElevatedButton(
                          onPressed: notifier.loadBookmarks,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : state.bookmarks.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceXL),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.bookmark_border, size: 72, color: Colors.grey),
                              const SizedBox(height: AppTheme.spaceM),
                              const Text(
                                'Save Waves for Later',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              const Text(
                                'Bookmark waves to keep track of important posts. Only you can view your bookmarked waves.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                              const SizedBox(height: AppTheme.spaceL),
                              ElevatedButton(
                                onPressed: () {
                                  // Back to home
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Explore Waves'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: notifier.loadBookmarks,
                        child: ListView.builder(
                          itemCount: state.bookmarks.length,
                          itemBuilder: (context, index) {
                            final wave = state.bookmarks[index];
                            return WaveCard(wave: wave);
                          },
                        ),
                      ),
      ),
    );
  }
}
