import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return Scaffold(
      appBar: AppBar(
        title: Text('#$tag', style: AppTextStyles.h5.copyWith(color: textThemeColor, fontWeight: FontWeight.bold)),
        shape: Border(bottom: BorderSide(color: borderColor)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Header stats card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal).withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '#',
                        style: AppTextStyles.h3.copyWith(
                          color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#$tag',
                        style: AppTextStyles.h5.copyWith(color: textThemeColor, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${state.waves.length} waves rolling',
                        style: AppTextStyles.caption.copyWith(color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // List of waves
            Expanded(
              child: state.isLoading && state.waves.isEmpty
                  ? const Center(child: TarangLoading())
                  : state.errorMessage != null && state.waves.isEmpty
                      ? TarangErrorState(
                          message: state.errorMessage!,
                          onRetry: notifier.loadHashtagWaves,
                        )
                      : state.waves.isEmpty
                          ? RefreshIndicator(
                              onRefresh: notifier.loadHashtagWaves,
                              child: SingleChildScrollView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                child: SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.6,
                                  child: const TarangEmptyState(
                                    title: 'No Waves Yet',
                                    body: 'Nobody has posted with this hashtag yet.',
                                  ),
                                ),
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: notifier.loadHashtagWaves,
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16),
                                itemCount: state.waves.length,
                                itemBuilder: (context, index) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: WaveCard(
                                    wave: state.waves[index],
                                  ),
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
