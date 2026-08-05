import 'package:flutter/material.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class QuoteSpreadWidget extends StatelessWidget {
  final WaveModel? originalWave;

  const QuoteSpreadWidget({
    super.key,
    this.originalWave,
  });

  @override
  Widget build(BuildContext context) {
    if (originalWave == null) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
        padding: const EdgeInsets.all(AppTheme.spaceM),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(AppTheme.radiusM),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              'This original Wave is no longer available.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    final wave = originalWave!;
    final formattedTime = DateFormat.yMMMd().add_jm().format(wave.createdAt.toLocal());

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomAvatar(
                url: wave.creator.avatarUrl,
                radius: 12,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        wave.creator.fullName ?? wave.creator.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '@${wave.creator.username}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                formattedTime,
                style: const TextStyle(color: Colors.grey, fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceS),
          if (wave.content != null && wave.content!.isNotEmpty)
            Text(
              wave.content!,
              style: const TextStyle(fontSize: 14),
            ),
          if (wave.mediaUrl != null && wave.mediaUrl!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spaceS),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusS),
              child: Image.network(
                wave.mediaUrl!,
                height: 150,
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
        ],
      ),
    );
  }
}
