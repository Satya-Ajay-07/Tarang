import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/home/providers/feed_provider.dart';
import 'package:mobile/features/home/widgets/poll_widget.dart';
import 'package:mobile/features/home/widgets/quote_spread_widget.dart';
import 'package:mobile/features/explore/hashtag_page.dart';
import 'package:mobile/features/profile/profile_screen.dart';
import 'package:mobile/core/services/haptic_service.dart';
import 'package:cached_network_image/cached_network_image.dart';

class WaveCard extends ConsumerWidget {
  final WaveModel wave;

  const WaveCard({
    super.key,
    required this.wave,
  });

  Widget _buildContent(BuildContext context) {
    final text = wave.content;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final regex = RegExp(r'(https?://[^\s]+|www\.[^\s]+|#[a-zA-Z0-9_]+|@[a-zA-Z0-9_]+)');
    final matches = regex.allMatches(text);

    if (matches.isEmpty) {
      return Text(
        text,
        style: AppTextStyles.caption.copyWith(
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
      );
    }

    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
          ),
        ));
      }

      final part = text.substring(match.start, match.end);
      if (part.startsWith('#')) {
        spans.add(TextSpan(
          text: part,
          style: AppTextStyles.mention.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => HashtagPage(tag: part.substring(1)),
                ),
              );
            },
        ));
      } else if (part.startsWith('@')) {
        spans.add(TextSpan(
          text: part,
          style: AppTextStyles.mention.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfileScreen(username: part.substring(1)),
                ),
              );
            },
        ));
      } else {
        spans.add(TextSpan(
          text: part,
          style: AppTextStyles.caption.copyWith(
            color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
            decoration: TextDecoration.underline,
          ),
        ));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: AppTextStyles.caption.copyWith(
          color: isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight,
        ),
      ));
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, String currentUserId) {
    final isOwner = wave.creatorId == currentUserId;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    TarangBottomSheet.show(
      context: context,
      title: 'Options',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Text('🔗', style: TextStyle(fontSize: 18)),
            title: const Text('Copy Link'),
            onTap: () {
              Clipboard.setData(ClipboardData(
                text: 'https://tarangnetwork.vercel.app/wave/${wave.id}',
              ));
              context.pop();
              TarangSnackbar.show(context, 'Wave link copied to clipboard!');
            },
          ),
          if (isOwner) ...[
            ListTile(
              leading: const Text('✏️', style: TextStyle(fontSize: 18)),
              title: const Text('Edit Wave'),
              onTap: () {
                context.pop();
                context.push('/compose', extra: {'editWave': wave});
              },
            ),
            ListTile(
              leading: const Text('🗑️', style: TextStyle(fontSize: 18)),
              title: Text(
                'Delete Wave',
                style: TextStyle(color: isDark ? AppTheme.dangerDark : AppTheme.dangerLight),
              ),
              onTap: () async {
                context.pop();
                final confirm = await TarangConfirmDialog.show(
                  context: context,
                  title: 'Delete Wave',
                  message: 'Are you sure you want to permanently delete this Wave?',
                  confirmText: 'Delete',
                );
                if (confirm == true) {
                  ref.read(feedProvider.notifier).deleteWave(wave.id);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  void _showSpreadMenu(BuildContext context, WidgetRef ref) {
    TarangBottomSheet.show(
      context: context,
      title: 'Spread Wave',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Text('🌊', style: TextStyle(fontSize: 18)),
            title: const Text('Spread Immediately'),
            onTap: () {
              context.pop();
              ref.read(feedProvider.notifier).spreadWave(wave.id);
              TarangSnackbar.show(context, 'Wave spread to your timeline!');
            },
          ),
          ListTile(
            leading: const Text('💭', style: TextStyle(fontSize: 18)),
            title: const Text('Spread with Thoughts'),
            onTap: () {
              context.pop();
              context.push('/compose', extra: {'spreadFromWave': wave});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final isSpread = wave.spreadFromId != null && (wave.content == null || wave.content!.isEmpty);
    final displayWave = isSpread && wave.spreadFrom != null ? wave.spreadFrom! : wave;
    final isQuoteSpread = displayWave.spreadFromId != null && displayWave.content != null && displayWave.content!.isNotEmpty;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    // Time Ago calculation
    final difference = DateTime.now().difference(displayWave.createdAt);
    String timeAgo = '${difference.inMinutes}m';
    if (difference.inMinutes >= 60) {
      timeAgo = '${difference.inHours}h';
    }
    if (difference.inHours >= 24) {
      timeAgo = '${difference.inDays}d';
    }

    return TarangCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Repost / Spread Header indicator
          if (isSpread) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  const Text('🔁', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 8),
                  Text(
                    '@${wave.creator.username} spread this wave',
                    style: AppTextStyles.metadata.copyWith(
                      color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
            const SizedBox(height: 8),
          ],

          // User Info details
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen(username: displayWave.creator.username)),
                ),
                child: TarangAvatar(
                  username: displayWave.creator.username,
                  avatarUrl: displayWave.creator.avatarUrl,
                  size: TarangAvatarSize.md,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayWave.creator.fullName ?? displayWave.creator.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '@${displayWave.creator.username}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                          ),
                        ),
                      ],
                    ),
                    // Location Tags
                    if (displayWave.city != null || displayWave.state != null || displayWave.country != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Text('📍', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [displayWave.city, displayWave.state, displayWave.country]
                                  .where((e) => e != null && e.isNotEmpty)
                                  .join(', '),
                              style: AppTextStyles.metadata.copyWith(
                                color: AppTheme.textMuted,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    // Time Ago & Circle Status
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          timeAgo,
                          style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                        ),
                        if (displayWave.isEdited) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Edited',
                              style: AppTextStyles.label.copyWith(
                                fontSize: 8,
                                color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          '•',
                          style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          displayWave.circleId != null ? '🎯 Circle' : '🌍 Public',
                          style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              TarangIconButton(
                icon: const Text('•••', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                size: 32,
                hasBorder: false,
                onPressed: () => _showMoreMenu(context, ref, currentUserId),
              ),
            ],
          ),

          // Body Content (aligned left by pl-13 equivalent of 52px)
          Padding(
            padding: const EdgeInsets.only(left: 52, top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContent(context),

                // Media Attachment
                if (displayWave.mediaUrl != null && displayWave.mediaUrl!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedNetworkImage(
                      imageUrl: displayWave.mediaUrl!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        child: const Center(child: TarangLoading(size: 20.0)),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 120,
                        color: isDark ? Colors.grey[900] : Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.broken_image_rounded, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                  ),
                ],

                // Poll
                if (displayWave.poll != null) ...[
                  const SizedBox(height: 12),
                  PollWidget(waveId: displayWave.id, poll: displayWave.poll!),
                ],

                // Quote Spread Nested Card
                if (isQuoteSpread) ...[
                  const SizedBox(height: 12),
                  if (displayWave.spreadFrom != null)
                    QuoteSpreadWidget(originalWave: displayWave.spreadFrom)
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.darkSurface : AppTheme.lightSurface).withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder, style: BorderStyle.solid),
                      ),
                      child: Row(
                        children: [
                          const Text('🚫', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This original Wave is no longer available.',
                              style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],

                const SizedBox(height: 16),

                // Custom Actions Bar using exact web emojis
                Container(
                  padding: const EdgeInsets.only(top: 8),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      // Like/Ripple action
                      _buildEmojiButton(
                        context,
                        emoji: displayWave.rippledByMe ? '💙' : '🤍',
                        label: displayWave.ripplesCount.toString(),
                        isActive: displayWave.rippledByMe,
                        onPressed: () {
                          HapticService.light();
                          ref.read(feedProvider.notifier).toggleRipple(displayWave.id);
                        },
                      ),
                      // Joins/Reply action
                      _buildEmojiButton(
                        context,
                        emoji: '💬',
                        label: displayWave.joinsCount.toString(),
                        isActive: false,
                        onPressed: () {
                          HapticService.light();
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => Scaffold(
                                appBar: AppBar(title: const Text('Replies')),
                                body: const Center(child: Text('Wave Replies (Placeholder)')),
                              ),
                            ),
                          );
                        },
                      ),
                      // Spread action
                      _buildEmojiButton(
                        context,
                        emoji: '🔁',
                        label: displayWave.spreadsCount.toString(),
                        isActive: displayWave.spreadByMe,
                        onPressed: () {
                          HapticService.light();
                          _showSpreadMenu(context, ref);
                        },
                      ),
                      // Bookmark action
                      _buildEmojiButton(
                        context,
                        emoji: displayWave.bookmarkedByMe ? '🔖' : '🪶',
                        label: 'Save',
                        isActive: displayWave.bookmarkedByMe,
                        onPressed: () {
                          HapticService.light();
                          ref.read(feedProvider.notifier).toggleBookmark(displayWave.id);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiButton(
    BuildContext context, {
    required String emoji,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.label.copyWith(
                color: isActive
                    ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                    : baseColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
