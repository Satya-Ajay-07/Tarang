import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/profile/providers/profile_providers.dart';
import 'profile_screen.dart';

class FollowListScreen extends ConsumerWidget {
  final String userId;
  final String title;
  final bool isFollowersTab;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.title,
    required this.isFollowersTab,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = isFollowersTab
        ? ref.watch(followersProvider(userId))
        : ref.watch(followingProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: state.isLoading
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
                          onPressed: isFollowersTab
                              ? () => ref
                                  .read(followersProvider(userId).notifier)
                                  .loadFollowers()
                              : () => ref
                                  .read(followingProvider(userId).notifier)
                                  .loadFollowing(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : state.list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spaceXL),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.people_outline,
                                  size: 64, color: Colors.grey),
                              const SizedBox(height: AppTheme.spaceM),
                              Text(
                                isFollowersTab
                                    ? 'No riders follow this user yet'
                                    : 'This user is not riding with anyone yet',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          if (isFollowersTab) {
                            await ref
                                .read(followersProvider(userId).notifier)
                                .loadFollowers();
                          } else {
                            await ref
                                .read(followingProvider(userId).notifier)
                                .loadFollowing();
                          }
                        },
                        child: ListView.builder(
                          itemCount: state.list.length,
                          itemBuilder: (context, index) {
                            final u = state.list[index];
                            return ListTile(
                              leading: CustomAvatar(url: u.avatarUrl),
                              title: Text(u.fullName ?? u.username),
                              subtitle: Text('@${u.username}'),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        ProfileScreen(username: u.username),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
      ),
    );
  }
}
