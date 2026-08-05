import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/poll_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/home/providers/feed_provider.dart';

class PollWidget extends ConsumerWidget {
  final String waveId;
  final PollModel poll;

  const PollWidget({
    super.key,
    required this.waveId,
    required this.poll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isExpired = poll.expiresAt.isBefore(DateTime.now());
    final showResults = poll.hasVoted || isExpired;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            poll.question,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: AppTheme.spaceM),
          ...poll.options.map((opt) {
            if (showResults) {
              final percent = poll.totalVotes > 0
                  ? (opt.votesCount / poll.totalVotes) * 100
                  : 0.0;
              final isMyVote = poll.votedOptionId == opt.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                child: Stack(
                  children: [
                    // Percentage indicator bar
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusS),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: Colors.transparent,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryTeal
                                .withValues(alpha: isMyVote ? 0.25 : 0.1),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    opt.text,
                                    style: TextStyle(
                                      fontWeight: isMyVote
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                    ),
                                  ),
                                ),
                                if (isMyVote) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.check_circle,
                                      size: 16, color: AppTheme.primaryTeal),
                                ],
                              ],
                            ),
                          ),
                          Text(
                            '${percent.toStringAsFixed(1)}% (${opt.votesCount})',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Voting option button
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spaceS),
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(feedProvider.notifier).votePoll(waveId, opt.id);
                  },
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.radiusM),
                    ),
                  ),
                  child: Text(
                    opt.text,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface),
                  ),
                ),
              );
            }
          }),
          const SizedBox(height: AppTheme.spaceS),
          Text(
            '${poll.totalVotes} votes • ${isExpired ? "Final Results" : "Active Poll"}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
