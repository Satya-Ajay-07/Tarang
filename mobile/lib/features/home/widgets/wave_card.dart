import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/home/providers/feed_provider.dart';
import 'package:mobile/features/home/widgets/poll_widget.dart';
import 'package:mobile/features/home/widgets/quote_spread_widget.dart';
import 'package:mobile/features/explore/hashtag_page.dart';
import 'package:mobile/features/profile/profile_screen.dart';
import 'package:mobile/core/services/haptic_service.dart';
import 'package:share_plus/share_plus.dart';

class WaveCard extends ConsumerWidget {
  final WaveModel wave;

  const WaveCard({
    super.key,
    required this.wave,
  });

  Widget _buildContent(BuildContext context) {
    final text = wave.content;
    if (text == null || text.isEmpty) return const SizedBox.shrink();

    // Regex to match hashtags
    final regExp = RegExp(r'#\w+');
    final matches = regExp.allMatches(text);

    if (matches.isEmpty) {
      return Text(text, style: const TextStyle(fontSize: 15, height: 1.3));
    }

    final spans = <TextSpan>[];
    int lastIndex = 0;

    for (final match in matches) {
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: text.substring(lastIndex, match.start),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ));
      }

      final tag = text.substring(match.start, match.end);
      spans.add(TextSpan(
        text: tag,
        style: const TextStyle(
          color: AppTheme.primaryTeal,
          fontWeight: FontWeight.bold,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => HashtagPage(tag: tag),
              ),
            );
          },
      ));

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastIndex),
        style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
      ));
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(fontSize: 15, height: 1.3),
        children: spans,
      ),
    );
  }

  void _showMoreMenu(BuildContext context, WidgetRef ref, String currentUserId) {
    final isOwner = wave.creatorId == currentUserId;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy Link'),
              onTap: () {
                Clipboard.setData(ClipboardData(
                  text: 'https://tarang.app/wave/${wave.id}',
                ));
                context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Wave link copied to clipboard')),
                );
              },
            ),
            if (isOwner) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Edit Wave'),
                onTap: () {
                  context.pop();
                  context.push('/compose', extra: {'editWave': wave});
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Wave'),
                onTap: () async {
                  context.pop();
                  final confirm = await AppDialogs.showConfirmation(
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
            ] else ...[
              ListTile(
                leading: const Icon(Icons.report, color: Colors.amber),
                title: const Text('Report (Placeholder)'),
                onTap: null, // Disabled placeholder
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showSpreadMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusL)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.repeat, color: AppTheme.primaryTeal),
              title: const Text('🌊 Spread Immediately'),
              onTap: () {
                context.pop();
                ref.read(feedProvider.notifier).spreadWave(wave.id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.comment, color: AppTheme.primaryTeal),
              title: const Text('💭 Spread with Thoughts'),
              onTap: () {
                context.pop();
                context.push('/compose', extra: {'spreadFromWave': wave});
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    final isSpread = wave.spreadFromId != null && (wave.content == null || wave.content!.isEmpty);
    
    // Determine target display wave (reposted wave details)
    final displayWave = isSpread && wave.spreadFrom != null ? wave.spreadFrom! : wave;
    final isQuoteSpread = displayWave.spreadFromId != null && displayWave.content != null && displayWave.content!.isNotEmpty;

    // Time calculations
    final difference = DateTime.now().difference(displayWave.createdAt);
    String timeAgo = '${difference.inMinutes}m';
    if (difference.inMinutes >= 60) {
      timeAgo = '${difference.inHours}h';
    }
    if (difference.inHours >= 24) {
      timeAgo = '${difference.inDays}d';
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceM),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Repost / Spread Header indicator
            if (isSpread) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(Icons.repeat, size: 14, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      '${wave.creator.fullName ?? wave.creator.username} spread',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],

            // User Info details
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(
                          username: displayWave.creator.username,
                        ),
                      ),
                    );
                  },
                  child: CustomAvatar(url: displayWave.creator.avatarUrl, radius: 20),
                ),
                const SizedBox(width: AppTheme.spaceS),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(
                            username: displayWave.creator.username,
                          ),
                        ),
                      );
                    },
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '@${displayWave.creator.username}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('•', style: TextStyle(color: Colors.grey)),
                            const SizedBox(width: 4),
                            Text(timeAgo, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                            if (displayWave.isEdited) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Edited',
                                  style: TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_horiz, size: 20),
                  onPressed: () => _showMoreMenu(context, ref, currentUserId),
                ),
              ],
            ),

            // Content body
            Padding(
              padding: const EdgeInsets.only(left: 48.0, top: 4.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildContent(context),
                  
                  // Media attachment placeholder
                  if (displayWave.mediaUrl != null && displayWave.mediaUrl!.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.spaceS),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                      child: Image.network(
                        displayWave.mediaUrl!,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 100,
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image, color: Colors.grey),
                          );
                        },
                      ),
                    ),
                  ],

                  // Poll Widget
                  if (displayWave.poll != null)
                    PollWidget(waveId: displayWave.id, poll: displayWave.poll!),

                  // Quote Spread Embedded Widget
                  if (isQuoteSpread)
                    QuoteSpreadWidget(originalWave: displayWave.spreadFrom),

                  const SizedBox(height: AppTheme.spaceM),

                  // Actions row bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Reply button
                      _buildActionButton(
                        icon: Icons.chat_bubble_outline,
                        count: displayWave.joinsCount,
                        onPressed: () {
                          HapticService.light();
                          // Open replies placeholder screen
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
                      // Spread button
                      _buildActionButton(
                        icon: Icons.repeat,
                        count: displayWave.spreadsCount,
                        color: displayWave.spreadByMe ? Colors.green : null,
                        onPressed: () {
                          HapticService.light();
                          _showSpreadMenu(context, ref);
                        },
                      ),
                      // Ripple (Like) button
                      _buildActionButton(
                        icon: displayWave.rippledByMe ? Icons.favorite : Icons.favorite_border,
                        count: displayWave.ripplesCount,
                        color: displayWave.rippledByMe ? Colors.red : null,
                        onPressed: () {
                          HapticService.light();
                          ref.read(feedProvider.notifier).toggleRipple(displayWave.id);
                        },
                      ),
                      // Bookmark button
                      _buildActionButton(
                        icon: displayWave.bookmarkedByMe ? Icons.bookmark : Icons.bookmark_border,
                        color: displayWave.bookmarkedByMe ? AppTheme.primaryTeal : null,
                        onPressed: () {
                          HapticService.light();
                          ref.read(feedProvider.notifier).toggleBookmark(displayWave.id);
                        },
                      ),
                      // Share button
                      IconButton(
                        icon: const Icon(Icons.share_outlined, size: 20, color: Colors.grey),
                        onPressed: () {
                          HapticService.light();
                          Share.share(
                            'Check out this Wave on Tarang: https://tarang.app/wave/${displayWave.id}',
                            subject: 'Tarang Wave',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    int? count,
    Color? color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color ?? Colors.grey),
            if (count != null && count > 0) ...[
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: color ?? Colors.grey,
                  fontWeight: color != null ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
