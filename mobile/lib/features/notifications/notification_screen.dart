import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/alert_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/features/notifications/providers/notification_providers.dart';
import 'package:mobile/features/profile/profile_screen.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';
import 'package:mobile/core/providers/core_providers.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  String _getAlertEmoji(String type) {
    switch (type.toLowerCase()) {
      case 'ripple':
        return '💙';
      case 'join':
        return '💬';
      case 'spread':
        return '🔁';
      case 'follow':
        return '👤';
      case 'reply':
        return '✉️';
      case 'mention':
        return '🏷️';
      case 'poll':
        return '📊';
      case 'system':
        return '⚙️';
      default:
        return '🌊';
    }
  }

  void _handleAlertTap(BuildContext context, WidgetRef ref, AlertModel alert) async {
    // Mark as read
    if (!alert.isRead) {
      ref.read(notificationProvider.notifier).markRead(alert.id);
    }

    // Route depending on alert category
    if (alert.type.toLowerCase() == 'follow' && alert.sender != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(username: alert.sender!.username),
        ),
      );
    } else if (alert.waveId != null) {
      try {
        final waveRepo = ref.read(waveRepositoryProvider);
        final wave = await waveRepo.getWave(alert.waveId!);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Wave Details',
                    style: AppTextStyles.h5.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                body: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    WaveCard(wave: wave),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (_) {
        if (context.mounted) {
          TarangSnackbar.show(context, 'This original Wave is no longer available.', isError: true);
        }
      }
    }
  }

  Widget _buildAlertRow(BuildContext context, WidgetRef ref, AlertModel alert) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    // Time Ago calculation
    final difference = DateTime.now().difference(alert.createdAt);
    String timeAgo = '${difference.inMinutes}m ago';
    if (difference.inMinutes >= 60) {
      timeAgo = '${difference.inHours}h ago';
    }
    if (difference.inHours >= 24) {
      timeAgo = '${difference.inDays}d ago';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () => _handleAlertTap(context, ref, alert),
        child: Container(
          decoration: BoxDecoration(
            color: alert.isRead
                ? (isDark ? AppTheme.darkCard : AppTheme.lightCard).withValues(alpha: 0.4)
                : (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal).withValues(alpha: 0.05),
            border: Border.all(
              color: alert.isRead
                  ? borderColor
                  : (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal).withValues(alpha: 0.25),
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getAlertEmoji(alert.type),
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.content ?? '',
                      style: AppTextStyles.captionBold.copyWith(color: textThemeColor, height: 1.3),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeAgo,
                      style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
              if (!alert.isRead)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroupSection(BuildContext context, WidgetRef ref, String title, List<AlertModel> list) {
    if (list.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 12),
          child: Text(
            title.toUpperCase(),
            style: AppTextStyles.label.copyWith(
              color: AppTheme.textMuted,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        ...list.map((alert) => _buildAlertRow(context, ref, alert)),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final notifier = ref.read(notificationProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    // Categorize alerts
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayAlerts = state.alerts.where((a) => a.createdAt.isAfter(today)).toList();
    final yesterdayAlerts = state.alerts.where((a) => a.createdAt.isAfter(yesterday) && a.createdAt.isBefore(today)).toList();
    final earlierAlerts = state.alerts.where((a) => a.createdAt.isBefore(yesterday)).toList();

    return Scaffold(
      body: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Wave Alerts',
                  style: AppTextStyles.h5.copyWith(color: textThemeColor, fontWeight: FontWeight.bold),
                ),
                if (unreadCount > 0)
                  TextButton(
                    onPressed: () {
                      notifier.markAllRead();
                      TarangSnackbar.show(context, 'All alerts marked as read.', isSuccess: true);
                    },
                    child: Text(
                      'Mark all as read',
                      style: AppTextStyles.metadata.copyWith(
                        color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Content body
          Expanded(
            child: state.isLoading && state.alerts.isEmpty
                ? const Center(child: TarangLoading())
                : state.alerts.isEmpty
                    ? RefreshIndicator(
                        onRefresh: () => notifier.loadAlerts(),
                        child: const SingleChildScrollView(
                          physics: AlwaysScrollableScrollPhysics(),
                          child: SizedBox(
                            height: 400,
                            child: TarangEmptyState(
                              title: 'The ocean is calm',
                              body: 'No new ripples, joins, or follow alerts have reached your timeline yet.',
                            ),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => notifier.loadAlerts(),
                        child: ListView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.all(16),
                          children: [
                            _buildGroupSection(context, ref, 'Today', todayAlerts),
                            _buildGroupSection(context, ref, 'Yesterday', yesterdayAlerts),
                            _buildGroupSection(context, ref, 'Earlier', earlierAlerts),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
