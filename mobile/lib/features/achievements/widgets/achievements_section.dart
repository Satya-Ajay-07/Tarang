import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/achievement_model.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/achievements/providers/achievements_provider.dart';

class AchievementsSection extends ConsumerWidget {
  final String? username;
  const AchievementsSection({super.key, this.username});

  void _showAchievementDetail(BuildContext context, AchievementModel ach) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusL)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Row(
          children: [
            Text(ach.icon, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                ach.name,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ach.description,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: AppTheme.spaceM),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusS),
              ),
              child: Text(
                ach.category.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ),
            if (ach.unlocked && ach.unlockedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Unlocked: ${ach.unlockedAt!.toLocal().toString().split(' ')[0]}',
                style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
              ),
            ] else ...[
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.lock, size: 14, color: Colors.grey),
                  SizedBox(width: 6),
                  Text(
                    'Locked',
                    style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryTeal)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(achievementsProviderFamily(username));

    // Handle Toast for newly unlocked achievement
    ref.listen<AchievementsState>(achievementsProviderFamily(username), (previous, next) {
      if (next.newlyUnlocked != null && previous?.newlyUnlocked?.id != next.newlyUnlocked?.id) {
        final unlocked = next.newlyUnlocked!;
        ref.read(achievementsProviderFamily(username).notifier).clearNewlyUnlocked();

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Text(unlocked.icon, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: AppTheme.spaceM),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ACHIEVEMENT UNLOCKED!',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                        Text(
                          unlocked.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          unlocked.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              backgroundColor: AppTheme.primaryTeal,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusM)),
            ),
          );
        });
      }
    });

    if (state.status == AchievementsStatus.loading && state.achievements.isEmpty) {
      return const Center(child: Padding(
        padding: EdgeInsets.all(32.0),
        child: CircularProgressIndicator(color: AppTheme.primaryTeal),
      ));
    }

    if (state.status == AchievementsStatus.error && state.achievements.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceL),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
              const SizedBox(height: 12),
              Text(state.errorMessage ?? 'Error loading achievements'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.read(achievementsProviderFamily(username).notifier).loadAchievements(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final earned = state.achievements.where((a) => a.unlocked).toList();
    final locked = state.achievements.where((a) => !a.unlocked).toList();

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '🏆 Achievements'.toUpperCase(),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppTheme.primaryTeal),
              ),
              if (state.achievements.isNotEmpty)
                Text(
                  '${earned.length}/${state.achievements.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spaceM),
          if (earned.isNotEmpty) ...[
            const Text(
              '✅ EARNED',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: AppTheme.spaceS),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppTheme.spaceS,
                mainAxisSpacing: AppTheme.spaceS,
                childAspectRatio: 1.0,
              ),
              itemCount: earned.length,
              itemBuilder: (context, index) => _buildBadgeTile(context, earned[index]),
            ),
            const SizedBox(height: AppTheme.spaceM),
          ],
          if (locked.isNotEmpty) ...[
            const Text(
              '🔒 LOCKED',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1),
            ),
            const SizedBox(height: AppTheme.spaceS),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: AppTheme.spaceS,
                mainAxisSpacing: AppTheme.spaceS,
                childAspectRatio: 1.0,
              ),
              itemCount: locked.length,
              itemBuilder: (context, index) => _buildBadgeTile(context, locked[index]),
            ),
          ],
          if (state.achievements.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Text('No achievements found.', style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBadgeTile(BuildContext context, AchievementModel ach) {
    final colors = {
      'creator':    [Colors.deepPurple.shade900.withValues(alpha: 0.1), Colors.deepPurple.shade500.withValues(alpha: 0.2)],
      'social':     [Colors.pink.shade900.withValues(alpha: 0.1), Colors.pink.shade500.withValues(alpha: 0.2)],
      'influence':  [Colors.amber.shade900.withValues(alpha: 0.1), Colors.amber.shade500.withValues(alpha: 0.2)],
      'dedication': [Colors.teal.shade900.withValues(alpha: 0.1), Colors.teal.shade500.withValues(alpha: 0.2)],
      'special':    [Colors.lightBlue.shade900.withValues(alpha: 0.1), Colors.lightBlue.shade500.withValues(alpha: 0.2)],
    };

    final grad = colors[ach.category] ?? colors['special']!;

    return GestureDetector(
      onTap: () => _showAchievementDetail(context, ach),
      child: Opacity(
        opacity: ach.unlocked ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(AppTheme.spaceS),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: grad, begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(AppTheme.radiusM),
            border: Border.all(
              color: ach.unlocked
                  ? AppTheme.primaryTeal.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(ach.icon, style: const TextStyle(fontSize: 28)),
              const SizedBox(height: 6),
              Text(
                ach.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
