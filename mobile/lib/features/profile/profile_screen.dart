import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/profile/edit_profile_screen.dart';
import 'package:mobile/features/profile/followers_screen.dart';
import 'package:mobile/features/profile/providers/profile_providers.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';
import 'package:mobile/features/settings/settings_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile/features/achievements/widgets/achievements_section.dart';
import 'package:mobile/features/achievements/providers/achievements_provider.dart';
import 'package:mobile/core/services/haptic_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String username;

  const ProfileScreen({
    super.key,
    required this.username,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Trigger achievements check if looking at own profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(authProvider).user;
      if (currentUser != null && currentUser.username == widget.username) {
        ref.read(achievementsProviderFamily(null).notifier).checkAndAward();
      }
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  void _shareProfile(String username) {
    Share.share(
      'Check out @$username on Tarang: https://tarang.app/you/$username',
      subject: 'Tarang Profile',
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authProvider).user;
    final isMe = currentUser != null && currentUser.username == widget.username;

    final profileState = ref.watch(profileProvider(widget.username));
    final profileNotifier = ref.read(profileProvider(widget.username).notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    if (profileState.isLoading && profileState.username.isEmpty) {
      return const Scaffold(
        body: Center(child: TarangLoading()),
      );
    }

    if (profileState.errorMessage != null && profileState.username.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.username)),
        body: TarangErrorState(
          message: profileState.errorMessage!,
          onRetry: profileNotifier.loadProfile,
        ),
      );
    }

    final formattedJoinDate = profileState.createdAt != null
        ? 'Riding since ${profileState.createdAt!.toLocal().toString().split(' ')[0]}'
        : '';

    // Filter lists based on selected tabs
    final normalWaves = profileState.waves.where((w) => w.parentWaveId == null && w.spreadFromId == null).toList();
    final replies = profileState.waves.where((w) => w.parentWaveId != null).toList();
    final mediaWaves = profileState.waves.where((w) => w.mediaUrl != null && w.mediaUrl!.isNotEmpty).toList();

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 180.0,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (profileState.coverUrl != null &&
                      profileState.coverUrl!.isNotEmpty)
                    Image.network(profileState.coverUrl!, fit: BoxFit.cover)
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isDark ? AppTheme.primaryTeal.withValues(alpha: 0.1) : AppTheme.primaryTeal.withValues(alpha: 0.2),
                            isDark ? AppTheme.primaryTealLight.withValues(alpha: 0.2) : AppTheme.primaryTeal.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.black54, Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              if (isMe)
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.white),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: Colors.white),
                onPressed: () => _shareProfile(profileState.username),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar & Edit Profile / Follow Button row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -32),
                        child: Hero(
                          tag: 'avatar-${profileState.username}',
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            child: TarangAvatar(
                              username: profileState.username,
                              avatarUrl: profileState.avatarUrl,
                              size: TarangAvatarSize.lg,
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: isMe
                            ? TarangButton(
                                text: 'Edit Profile',
                                variant: TarangButtonVariant.secondary,
                                size: TarangButtonSize.sm,
                                onPressed: () async {
                                  final updated = await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const EditProfileScreen(),
                                    ),
                                  );
                                  if (updated == true) {
                                    profileNotifier.loadProfile();
                                  }
                                },
                              )
                            : Row(
                                children: [
                                  const SizedBox(width: 8),
                                  TarangButton(
                                    text: profileState.isRiding ? 'Riding' : 'Ride',
                                    variant: profileState.isRiding ? TarangButtonVariant.secondary : TarangButtonVariant.primary,
                                    size: TarangButtonSize.sm,
                                    onPressed: () {
                                      HapticService.selection();
                                      profileNotifier.toggleRide();
                                    },
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  // Profile names & metadata
                  Text(
                    profileState.fullName ?? profileState.username,
                    style: AppTextStyles.h5.copyWith(color: textThemeColor, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '@${profileState.username}',
                    style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (profileState.bio != null && profileState.bio!.isNotEmpty) ...[
                    Text(
                      profileState.bio!,
                      style: AppTextStyles.caption.copyWith(color: textThemeColor, height: 1.3),
                    ),
                    const SizedBox(height: 12),
                  ],

                  // Details rows (website, location, join date)
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 12, color: AppTheme.textMuted),
                          const SizedBox(width: 4),
                          Text(formattedJoinDate, style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted)),
                        ],
                      ),
                      if (profileState.location != null && profileState.location!.isNotEmpty)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textMuted),
                            const SizedBox(width: 4),
                            Text(profileState.location!, style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted)),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Follower / Following Stats
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userId: profileState.id,
                                title: 'Riding',
                                isFollowersTab: false,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              '${profileState.ridingCount}',
                              style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                            ),
                            const SizedBox(width: 4),
                            Text('Riding', style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userId: profileState.id,
                                title: 'Wave Riders',
                                isFollowersTab: true,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              '${profileState.ridersCount}',
                              style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                            ),
                            const SizedBox(width: 4),
                            Text('Wave Riders', style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                labelColor: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                unselectedLabelColor: AppTheme.textMuted,
                labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: AppTextStyles.label,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Waves'),
                  Tab(text: 'Replies'),
                  Tab(text: 'Media'),
                  Tab(text: 'Bookmarks'),
                  Tab(text: '🏆 Achievements'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Waves Feed Tab
            _buildTabFeed(normalWaves, 'Waves', "You haven't released any original waves yet.", profileNotifier.loadProfile),

            // Replies Tab
            _buildTabFeed(replies, 'Replies', "You haven't participated in any ripples or discussions.", profileNotifier.loadProfile),

            // Media Tab
            _buildTabFeed(mediaWaves, 'Media', "There are no images or video attachments on your timeline.", profileNotifier.loadProfile),

            // Bookmarks Tab
            _buildTabFeed([], 'Bookmarks', "Your saved bookmarks list is currently empty.", profileNotifier.loadProfile),

            // Achievements Tab
            AchievementsSection(
              username: (currentUser != null && currentUser.username == widget.username) ? null : widget.username,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabFeed(List<dynamic> list, String tabName, String emptyBody, Future<void> Function() onRefresh) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: list.isEmpty
          ? SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: SizedBox(
                height: 300,
                child: TarangEmptyState(
                  title: 'No content found',
                  body: emptyBody,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: WaveCard(wave: list[index]),
                );
              },
            ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
