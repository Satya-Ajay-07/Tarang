import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
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

  Widget _buildStreamTabButton(String label, String value, String currentValue) {
    final isSelected = currentValue == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => ref.read(feedProvider.notifier).setStreamType(value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: AppTextStyles.label.copyWith(
            color: isSelected
                ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                : AppTheme.textMuted,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildHomeFeed() {
    final feedState = ref.watch(feedProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return Column(
      children: [
        // Tab selector bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: borderColor)),
          ),
          child: Row(
            children: [
              _buildStreamTabButton('Wave Stream', 'all', feedState.streamType),
              const SizedBox(width: 24),
              _buildStreamTabButton('Riding Currents', 'riding', feedState.streamType),
            ],
          ),
        ),
        Expanded(
          child: _buildFeedList(feedState),
        ),
      ],
    );
  }

  Widget _buildFeedList(FeedState feedState) {
    if (feedState.status == FeedStatus.loading && feedState.waves.isEmpty) {
      return ListView.builder(
        itemCount: 4,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: TarangCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    TarangSkeleton(variant: TarangSkeletonVariant.circle, width: 40, height: 40),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TarangSkeleton(variant: TarangSkeletonVariant.text, width: 120, height: 12),
                        SizedBox(height: 6),
                        TarangSkeleton(variant: TarangSkeletonVariant.text, width: 80, height: 10),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const TarangSkeleton(variant: TarangSkeletonVariant.text, width: double.infinity, height: 14),
                const SizedBox(height: 8),
                const TarangSkeleton(variant: TarangSkeletonVariant.text, width: 220, height: 14),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(4, (_) => const TarangSkeleton(variant: TarangSkeletonVariant.text, width: 44, height: 12)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (feedState.status == FeedStatus.error && feedState.waves.isEmpty) {
      return TarangErrorState(
        message: feedState.errorMessage ?? 'Failed to load feed',
        onRetry: () => ref.read(feedProvider.notifier).loadFeed(refresh: true),
      );
    }

    if (feedState.waves.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => ref.read(feedProvider.notifier).loadFeed(refresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.7,
            child: TarangEmptyState(
              title: 'Your ocean is quiet',
              body: 'No waves are rolling right now. Be the first to create one!',
              action: TarangButton(
                text: 'Create a Wave',
                variant: TarangButtonVariant.primary,
                size: TarangButtonSize.sm,
                onPressed: () => context.push('/compose'),
              ),
            ),
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(feedProvider.notifier).loadFeed(refresh: true),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: feedState.waves.length + 1,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemBuilder: (context, index) {
          if (index == feedState.waves.length) {
            if (feedState.status == FeedStatus.loadingMore) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: TarangLoading(size: 24.0),
              );
            }
            return const SizedBox(height: 80); // Spacer at bottom
          }
          return Consumer(
            builder: (context, ref, child) {
              final wave = ref.watch(feedProvider.select((state) => state.waves[index]));
              return Padding(
                padding: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
                child: WaveCard(wave: wave),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;
    final appBarBg = isDark
        ? AppTheme.darkBackground.withValues(alpha: 0.8)
        : AppTheme.lightBackground.withValues(alpha: 0.8);

    final tabs = [
      _buildHomeFeed(),
      const ExploreScreen(),
      const SizedBox.shrink(), // Compose router intercept
      const NotificationScreen(),
      user == null
          ? const Center(child: TarangLoading())
          : ProfileScreen(username: user.username),
    ];

    return Scaffold(
      // Glassmorphic App Bar
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: appBarBg,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              titleSpacing: 16,
              shape: Border(bottom: BorderSide(color: borderColor)),
              title: const TarangLogo(size: 32.0),
              actions: [
                TarangIconButton(
                  icon: const Icon(Icons.mail_outline_rounded),
                  size: 36,
                  hasBorder: false,
                  tooltip: 'Messages',
                  onPressed: () => context.push('/messages'),
                ),
                TarangIconButton(
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  size: 36,
                  hasBorder: false,
                  tooltip: 'Saved',
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => const BookmarksScreen()),
                  ),
                ),
                TarangIconButton(
                  icon: Icon(themeMode == ThemeMode.dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded),
                  size: 36,
                  hasBorder: false,
                  tooltip: 'Toggle Theme',
                  onPressed: () => ref.read(themeProvider.notifier).toggleTheme(),
                ),
                TarangIconButton(
                  icon: const Icon(Icons.logout_rounded),
                  size: 36,
                  hasBorder: false,
                  tooltip: 'Logout',
                  onPressed: () async {
                    final confirm = await TarangConfirmDialog.show(
                      context: context,
                      title: 'Log Out',
                      message: 'Are you sure you want to log out of your Tarang session?',
                      confirmText: 'Log Out',
                    );
                    if (confirm == true) {
                      await ref.read(authProvider.notifier).logout();
                    }
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: tabs[_currentTabIndex],
      ),
      floatingActionButton: _currentTabIndex == 0
          ? Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppTheme.waveGradient,
              ),
              child: FloatingActionButton(
                onPressed: () => context.push('/compose'),
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: const Icon(Icons.edit_rounded, color: Colors.white),
              ),
            )
          : null,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: borderColor)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
          selectedItemColor: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
          unselectedItemColor: AppTheme.textMuted,
          showSelectedLabels: true,
          showUnselectedLabels: true,
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
              activeIcon: Icon(Icons.home_rounded),
              label: 'Ocean',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              activeIcon: Icon(Icons.search_rounded),
              label: 'Explore',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.add_circle_outline_rounded),
              activeIcon: Icon(Icons.add_circle_rounded),
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
                child: const Icon(Icons.notifications_rounded),
              ),
              label: 'Alerts',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'You',
            ),
          ],
        ),
      ),
    );
  }
}
