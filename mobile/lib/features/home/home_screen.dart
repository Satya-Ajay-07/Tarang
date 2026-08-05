import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/providers/theme_provider.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/home/providers/feed_provider.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';
import 'package:mobile/features/explore/explore_screen.dart';
import 'package:mobile/features/profile/profile_screen.dart';
import 'package:mobile/features/notifications/notification_screen.dart';
import 'package:mobile/features/notifications/bookmarks_screen.dart';
import 'package:mobile/features/notifications/providers/notification_providers.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTabIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(feedProvider.notifier).loadFeed();
    }
  }

  Widget _buildHomeFeed() {
    final feedState = ref.watch(feedProvider);

    if (feedState.status == FeedStatus.loading && feedState.waves.isEmpty) {
      // Skeleton loader shimmer list
      return ListView.builder(
        itemCount: 6,
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spaceS),
        itemBuilder: (context, index) => const Padding(
          padding: EdgeInsets.symmetric(
              horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ShimmerLoader(width: 40, height: 40, borderRadius: 20),
                  SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ShimmerLoader(width: 120, height: 14),
                      SizedBox(height: 4),
                      ShimmerLoader(width: 80, height: 10),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 12),
              ShimmerLoader(width: double.infinity, height: 16),
              SizedBox(height: 6),
              ShimmerLoader(width: 200, height: 16),
              SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ShimmerLoader(width: 40, height: 16),
                  ShimmerLoader(width: 40, height: 16),
                  ShimmerLoader(width: 40, height: 16),
                  ShimmerLoader(width: 40, height: 16),
                ],
              ),
            ],
          ),
        ),
      );
    }

    if (feedState.status == FeedStatus.error && feedState.waves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: AppTheme.spaceM),
              const Text(
                'Failed to load feed',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: AppTheme.spaceS),
              Text(
                feedState.errorMessage ??
                    'Please verify your internet connection.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: AppTheme.spaceL),
              ElevatedButton(
                onPressed: () =>
                    ref.read(feedProvider.notifier).loadFeed(refresh: true),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (feedState.waves.isEmpty) {
      return RefreshIndicator(
        onRefresh: () =>
            ref.read(feedProvider.notifier).loadFeed(refresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.3),
            const Icon(Icons.waves, size: 64, color: AppTheme.primaryTeal),
            const SizedBox(height: AppTheme.spaceM),
            const Text(
              'Your ocean is quiet',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: AppTheme.spaceS),
            const Text(
              'No waves are rolling right now. Be the first to create one!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).loadFeed(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: feedState.waves.length + 1,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == feedState.waves.length) {
            if (feedState.status == FeedStatus.loadingMore) {
              return const Padding(
                padding: EdgeInsets.all(AppTheme.spaceM),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            return const SizedBox(height: 80); // Bottom list spacer
          }
          return WaveCard(wave: feedState.waves[index]);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeProvider);

    final tabs = [
      _buildHomeFeed(),
      const ExploreScreen(),
      const SizedBox
          .shrink(), // Compose placeholder (never rendered, opens compose screen)
      const NotificationScreen(),
      user == null
          ? const Center(child: CircularProgressIndicator())
          : ProfileScreen(username: user.username),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarang 🌊'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const BookmarksScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              themeMode == ThemeMode.dark ? Icons.light_mode : Icons.dark_mode,
            ),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirm = await AppDialogs.showConfirmation(
                context: context,
                title: 'Log Out',
                message:
                    'Are you sure you want to log out of your Tarang session?',
                confirmText: 'Log Out',
              );
              if (confirm == true) {
                await ref.read(authProvider.notifier).logout();
              }
            },
          ),
        ],
      ),
      body: tabs[_currentTabIndex],
      floatingActionButton: _currentTabIndex == 0
          ? FloatingActionButton(
              onPressed: () => context.push('/compose'),
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentTabIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppTheme.primaryTeal,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) {
            context.push('/compose');
          } else {
            setState(() {
              _currentTabIndex = index;
            });
          }
        },
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_rounded),
            label: 'Explore',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.add_box_outlined),
            activeIcon: Icon(Icons.add_box),
            label: 'Compose',
          ),
          BottomNavigationBarItem(
            icon: Badge(
              label: Text(ref.watch(unreadCountProvider).toString()),
              isLabelVisible: ref.watch(unreadCountProvider) > 0,
              child: const Icon(Icons.notifications_none_rounded),
            ),
            activeIcon: Badge(
              label: Text(ref.watch(unreadCountProvider).toString()),
              isLabelVisible: ref.watch(unreadCountProvider) > 0,
              child: const Icon(Icons.notifications),
            ),
            label: 'Notifications',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
