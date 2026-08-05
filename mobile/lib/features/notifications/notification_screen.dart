import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mobile/core/models/alert_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/notifications/providers/notification_providers.dart';
import 'package:mobile/features/profile/profile_screen.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';
import 'package:mobile/core/providers/core_providers.dart';

class NotificationScreen extends ConsumerWidget {
  const NotificationScreen({super.key});

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'ripple':
        return Icons.favorite;
      case 'spread':
        return Icons.repeat;
      case 'join':
        return Icons.chat_bubble;
      case 'follow':
        return Icons.person_add;
      default:
        return Icons.notifications;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'ripple':
        return Colors.red;
      case 'spread':
        return Colors.green;
      case 'join':
        return AppTheme.primaryTeal;
      case 'follow':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  void _handleAlertTap(
      BuildContext context, WidgetRef ref, AlertModel alert) async {
    // Mark as read
    if (!alert.isRead) {
      ref.read(notificationProvider.notifier).markRead(alert.id);
    }

    // Navigation depending on notification type
    if (alert.type == 'follow' && alert.sender != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileScreen(username: alert.sender!.username),
        ),
      );
    } else if (alert.waveId != null) {
      // Fetch and open wave details
      try {
        final waveRepo = ref.read(waveRepositoryProvider);
        final wave = await waveRepo.getWave(alert.waveId!);
        if (context.mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => Scaffold(
                appBar: AppBar(title: const Text('Wave Details')),
                body: ListView(
                  children: [
                    WaveCard(wave: wave),
                  ],
                ),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('This original Wave is no longer available.')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);
    final unreadCount = ref.watch(unreadCountProvider);
    final notifier = ref.read(notificationProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications 🔔'),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: notifier.markAllRead,
              child: const Text('Mark All Read'),
            ),
        ],
      ),
      body: SafeArea(
        child: state.isLoading && state.alerts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: AppTheme.spaceM),
                        Text(state.errorMessage!),
                        const SizedBox(height: AppTheme.spaceM),
                        ElevatedButton(
                          onPressed: notifier.loadAlerts,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : state.alerts.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceXL),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.notifications_none,
                                  size: 72, color: Colors.grey.shade400),
                              const SizedBox(height: AppTheme.spaceM),
                              const Text(
                                'Your Ocean is Calm',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              const SizedBox(height: AppTheme.spaceS),
                              const Text(
                                'No notifications yet. When people ripple, join, or spread your waves, they will show up here.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: notifier.loadAlerts,
                        child: ListView.separated(
                          itemCount: state.alerts.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final alert = state.alerts[index];
                            final formattedTime = DateFormat.yMMMd()
                                .add_jm()
                                .format(alert.createdAt.toLocal());

                            return Dismissible(
                              key: Key(alert.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: Colors.red,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete,
                                    color: Colors.white),
                              ),
                              onDismissed: (direction) {
                                notifier.deleteAlert(alert.id);
                              },
                              child: ListTile(
                                tileColor: alert.isRead
                                    ? Colors.transparent
                                    : AppTheme.primaryTeal
                                        .withValues(alpha: 0.05),
                                leading: Stack(
                                  children: [
                                    CustomAvatar(
                                        url: alert.sender?.avatarUrl,
                                        radius: 22),
                                    Positioned(
                                      bottom: 0,
                                      right: 0,
                                      child: Container(
                                        padding: const EdgeInsets.all(2),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black
                                                  .withValues(alpha: 0.1),
                                              blurRadius: 4,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _getTypeIcon(alert.type),
                                          size: 12,
                                          color: _getTypeColor(alert.type),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: RichText(
                                        text: TextSpan(
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                            fontSize: 14,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: alert.sender?.fullName ??
                                                  alert.sender?.username ??
                                                  'System',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                                text:
                                                    ' ${alert.content ?? ""}'),
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (!alert.isRead)
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppTheme.primaryTeal,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                  ],
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    formattedTime,
                                    style: const TextStyle(
                                        color: Colors.grey, fontSize: 11),
                                  ),
                                ),
                                onTap: () =>
                                    _handleAlertTap(context, ref, alert),
                              ),
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
