import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/explore/providers/explore_providers.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';

class HashtagPage extends ConsumerWidget {
  final String tag;

  const HashtagPage({
    super.key,
    required this.tag,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hashtagProvider(tag));
    final notifier = ref.read(hashtagProvider(tag).notifier);

    return Scaffold(
      appBar: AppBar(
        title: Text(tag),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header stats card
            Container(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              color: Theme.of(context).colorScheme.surface,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        '#',
                        style: TextStyle(
                          color: AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spaceM),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tag,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.waves.length} waves rolling',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // List of waves
            Expanded(
              child: state.isLoading && state.waves.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : state.errorMessage != null && state.waves.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline,
                                  size: 48, color: Colors.red),
                              const SizedBox(height: AppTheme.spaceM),
                              Text(state.errorMessage!),
                              const SizedBox(height: AppTheme.spaceM),
                              ElevatedButton(
                                onPressed: notifier.loadHashtagWaves,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                      : state.waves.isEmpty
                          ? RefreshIndicator(
                              onRefresh: notifier.loadHashtagWaves,
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.2),
                                  const Icon(Icons.waves,
                                      size: 64, color: Colors.grey),
                                  const SizedBox(height: AppTheme.spaceM),
                                  const Text(
                                    'No Waves Yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                  const SizedBox(height: AppTheme.spaceS),
                                  const Text(
                                    'Nobody has posted with this hashtag yet.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: notifier.loadHashtagWaves,
                              child: ListView.builder(
                                itemCount: state.waves.length,
                                itemBuilder: (context, index) => WaveCard(
                                  wave: state.waves[index],
                                ),
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
