import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/profile/edit_profile_screen.dart';
import 'package:mobile/features/profile/followers_screen.dart';
import 'package:mobile/features/profile/providers/profile_providers.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';
import 'package:mobile/features/settings/settings_screen.dart';
import 'package:share_plus/share_plus.dart';

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
    _tabController = TabController(length: 2, vsync: this);
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

    if (profileState.isLoading && profileState.username.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (profileState.errorMessage != null && profileState.username.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.username)),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: AppTheme.spaceM),
              Text(profileState.errorMessage!),
              const SizedBox(height: AppTheme.spaceM),
              ElevatedButton(
                onPressed: profileNotifier.loadProfile,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final formattedJoinDate = profileState.createdAt != null
        ? 'Riding since ${profileState.createdAt!.toLocal().toString().split(' ')[0]}'
        : '';

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
                        color: AppTheme.primaryTeal.withValues(alpha: 0.2)),
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
                  icon: const Icon(Icons.settings, color: Colors.white),
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
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
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
                            backgroundColor:
                                Theme.of(context).scaffoldBackgroundColor,
                            child: CustomAvatar(
                                url: profileState.avatarUrl, radius: 36),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: isMe
                            ? OutlinedButton(
                                onPressed: () async {
                                  final updated =
                                      await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const EditProfileScreen(),
                                    ),
                                  );
                                  if (updated == true) {
                                    profileNotifier.loadProfile();
                                  }
                                },
                                child: const Text('Edit Profile'),
                              )
                            : Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.mail_outline),
                                    onPressed:
                                        null, // Disabled Message placeholder
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: profileNotifier.toggleRide,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: profileState.isRiding
                                          ? Colors.grey.shade300
                                          : AppTheme.primaryTeal,
                                      foregroundColor: profileState.isRiding
                                          ? Colors.black87
                                          : Colors.white,
                                    ),
                                    child: Text(profileState.isRiding
                                        ? 'Riding'
                                        : 'Ride'),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),

                  // Profile names & metadata
                  Text(
                    profileState.fullName ?? profileState.username,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                  Text(
                    '@${profileState.username}',
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: AppTheme.spaceS),
                  if (profileState.bio != null &&
                      profileState.bio!.isNotEmpty) ...[
                    Text(profileState.bio!,
                        style: const TextStyle(fontSize: 14, height: 1.3)),
                    const SizedBox(height: AppTheme.spaceS),
                  ],

                  // Details rows (website, location, join date)
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(formattedJoinDate,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      if (profileState.location != null &&
                          profileState.location!.isNotEmpty) ...[
                        const SizedBox(width: AppTheme.spaceM),
                        const Icon(Icons.location_on_outlined,
                            size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(profileState.location!,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 13)),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),

                  // Follower / Following Stats
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userId: profileState.id,
                                title: 'Following',
                                isFollowersTab: false,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              '${profileState.ridingCount}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Text('Following',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppTheme.spaceL),
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => FollowListScreen(
                                userId: profileState.id,
                                title: 'Riders (Followers)',
                                isFollowersTab: true,
                              ),
                            ),
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              '${profileState.ridersCount}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Text('Riders',
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spaceM),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryTeal,
                labelColor: AppTheme.primaryTeal,
                unselectedLabelColor: Colors.grey,
                tabs: const [
                  Tab(text: 'Waves'),
                  Tab(text: 'Replies (Placeholder)'),
                ],
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Waves Feed Tab
            RefreshIndicator(
              onRefresh: profileNotifier.loadProfile,
              child: profileState.waves.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                            height: MediaQuery.of(context).size.height * 0.15),
                        const Icon(Icons.waves, size: 64, color: Colors.grey),
                        const SizedBox(height: AppTheme.spaceM),
                        const Text(
                          'No Waves Yet',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: AppTheme.spaceS),
                        const Text(
                          'Keep riding to catch the first wave.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: profileState.waves.length,
                      itemBuilder: (context, index) {
                        return WaveCard(wave: profileState.waves[index]);
                      },
                    ),
            ),

            // Replies Tab (Placeholder)
            ListView(
              padding: const EdgeInsets.all(AppTheme.spaceM),
              children: [
                SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                const Icon(Icons.chat_bubble_outline,
                    size: 64, color: Colors.grey),
                const SizedBox(height: AppTheme.spaceM),
                const Text(
                  'Replies screen coming soon',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ],
        ),
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
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
