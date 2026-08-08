import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/trending_hashtag_model.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/features/explore/providers/explore_providers.dart';
import 'package:mobile/features/explore/hashtag_page.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';
import 'package:mobile/features/profile/profile_screen.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  TabController? _tabController;
  Timer? _debounce;
  bool _isSearchingActive = false;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController!.addListener(_handleTabChange);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _tabController?.removeListener(_handleTabChange);
    _tabController?.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  String _lastQuery = '';

  void _handleTabChange() {
    if (_searchController.text.trim().isNotEmpty) {
      _triggerSearch();
    }
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    setState(() {
      _isSearchingActive = text.isNotEmpty;
    });

    final query = text.trim();
    if (query == _lastQuery) return; // Prevent duplicate execution on focus changes / composition events

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _triggerSearch();
    });
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    _lastQuery = query;
    if (query.isEmpty) {
      ref.read(searchProvider.notifier).search('');
      return;
    }

    final kinds = ['all', 'people', 'waves', 'circles'];
    final selectedKind = kinds[_tabController!.index];
    ref.read(searchProvider.notifier).search(query, kind: selectedKind);
  }


  void _handleSearchSubmit(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchProvider.notifier).addRecentSearch(query.trim());
    }
  }

  Widget _buildSuggestedRiderRow(UserModel rider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TarangCard(
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ProfileScreen(username: rider.username)),
              ),
              child: TarangAvatar(
                username: rider.username,
                avatarUrl: rider.avatarUrl,
                size: TarangAvatarSize.md,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen(username: rider.username)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rider.fullName ?? rider.username,
                      style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${rider.username}',
                      style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: TarangButton(
                text: 'Ride',
                variant: TarangButtonVariant.primary,
                size: TarangButtonSize.sm,
                onPressed: () => ref.read(exploreProvider.notifier).toggleRideSuggested(rider.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingHashtagCard(TrendingHashtagModel ht, int rank) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final isHot = ht.category == 'trending_now';
    final isRising = ht.category == 'rising';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => HashtagPage(tag: ht.tag),
            ),
          );
        },
        child: TarangCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#$rank',
                    style: AppTextStyles.h5.copyWith(
                      color: isDark ? Colors.white24 : Colors.black12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Row(
                    children: [
                      if (isHot)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '🔥 HOT',
                            style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (isRising)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            '📈 RISING',
                            style: TextStyle(color: Color(0xFF10B981), fontSize: 8, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                '#${ht.tag}',
                style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
              ),
              const SizedBox(height: 2),
              Text(
                '${ht.count} waves',
                style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingWaveCard(WaveModel wave, int rank) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TarangCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                TarangAvatar(
                  username: wave.creator.username,
                  avatarUrl: wave.creator.avatarUrl,
                  size: TarangAvatarSize.sm,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wave.creator.fullName ?? wave.creator.username,
                        style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '@${wave.creator.username}',
                        style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white12 : Colors.black12,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '#$rank',
                    style: AppTextStyles.metadata.copyWith(fontWeight: FontWeight.bold, color: textThemeColor),
                  ),
                ),
              ],
            ),
            if (wave.content != null && wave.content!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                wave.content!,
                style: AppTextStyles.caption.copyWith(color: textThemeColor),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                Text('🤍 ${wave.ripplesCount}', style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted)),
                const SizedBox(width: 12),
                Text('🔁 ${wave.spreadsCount}', style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted)),
                const SizedBox(width: 12),
                Text('💬 ${wave.joinsCount}', style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String id, String label, String icon) {
    final isSelected = _selectedCategory == id;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: isSelected,
        onSelected: (val) {
          if (val) {
            setState(() {
              _selectedCategory = id;
            });
          }
        },
        selectedColor: isDark ? AppTheme.primaryTealLight.withValues(alpha: 0.2) : AppTheme.primaryTeal.withValues(alpha: 0.1),
        backgroundColor: Colors.transparent,
        labelStyle: AppTextStyles.metadata.copyWith(
          fontWeight: FontWeight.bold,
          color: isSelected
              ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
              : (isDark ? AppTheme.textSecondaryDark : AppTheme.textSecondaryLight),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected
                ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                : (isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingDashboard(ExploreState exploreState) {
    if (exploreState.isLoading) {
      return const Center(child: TarangLoading());
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    // Filter hashtags based on selected category
    List<TrendingHashtagModel> tags = exploreState.trendingHashtags;
    if (_selectedCategory != 'all') {
      tags = tags.where((h) => h.category == _selectedCategory).toList();
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        // Category filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildCategoryChip('all', 'All', '🌊'),
              _buildCategoryChip('trending_now', 'Trending Now', '🔥'),
              _buildCategoryChip('rising', 'Rising', '📈'),
              _buildCategoryChip('popular_this_week', 'This Week', '⭐'),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Suggested riders to ride
        if (exploreState.suggestedRiders.isNotEmpty) ...[
          Text('Suggested Riders', style: AppTextStyles.captionBold.copyWith(color: titleColor)),
          const SizedBox(height: 8),
          ...exploreState.suggestedRiders.map(_buildSuggestedRiderRow),
          const SizedBox(height: 20),
        ],

        // Trending hashtags
        if (tags.isNotEmpty) ...[
          Text('Trending Hashtags', style: AppTextStyles.captionBold.copyWith(color: titleColor)),
          const SizedBox(height: 8),
          ...tags.asMap().entries.map((entry) => _buildTrendingHashtagCard(entry.value, entry.key + 1)),
          const SizedBox(height: 20),
        ],

        // Trending waves
        if (exploreState.trendingWaves.isNotEmpty) ...[
          Text('Trending Waves', style: AppTextStyles.captionBold.copyWith(color: titleColor)),
          const SizedBox(height: 8),
          ...exploreState.trendingWaves.asMap().entries.map((entry) => _buildTrendingWaveCard(entry.value, entry.key + 1)),
        ],
      ],
    );
  }

  Widget _buildSearchResults(SearchState searchState) {
    if (searchState.isLoading) {
      return const Center(child: TarangLoading());
    }

    if (searchState.errorMessage != null) {
      return TarangErrorState(
        message: searchState.errorMessage!,
        onRetry: _triggerSearch,
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    return TabBarView(
      controller: _tabController,
      children: [
        // Tab 1: All Results
        ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (searchState.people.isNotEmpty) ...[
              Text('Riders', style: AppTextStyles.captionBold.copyWith(color: textThemeColor)),
              const SizedBox(height: 8),
              ...searchState.people.take(3).map(_buildSearchResultRiderRow),
              const SizedBox(height: 16),
            ],
            if (searchState.waves.isNotEmpty) ...[
              Text('Waves', style: AppTextStyles.captionBold.copyWith(color: textThemeColor)),
              const SizedBox(height: 8),
              ...searchState.waves.map((w) => Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: WaveCard(wave: w),
                  )),
            ],
            if (searchState.people.isEmpty && searchState.waves.isEmpty)
              const SizedBox(
                height: 300,
                child: TarangEmptyState(
                  title: 'No results found',
                  body: 'Try searching for different terms or keywords.',
                ),
              ),
          ],
        ),

        // Tab 2: Riders (people)
        searchState.people.isEmpty
            ? const TarangEmptyState(title: 'No riders found', body: 'No riders match your query.')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: searchState.people.length,
                itemBuilder: (context, index) => _buildSearchResultRiderRow(searchState.people[index]),
              ),

        // Tab 3: Waves
        searchState.waves.isEmpty
            ? const TarangEmptyState(title: 'No waves found', body: 'No waves match your query.')
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: searchState.waves.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: WaveCard(wave: searchState.waves[index]),
                ),
              ),

        // Tab 4: Circles (empty placeholder)
        const TarangEmptyState(title: 'No Circles found', body: 'Circle search is coming soon.'),
      ],
    );
  }

  Widget _buildSearchResultRiderRow(UserModel user) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: TarangCard(
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => ProfileScreen(username: user.username)),
              ),
              child: TarangAvatar(
                username: user.username,
                avatarUrl: user.avatarUrl,
                size: TarangAvatarSize.md,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => ProfileScreen(username: user.username)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName ?? user.username,
                      style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '@${user.username}',
                      style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              height: 32,
              child: TarangButton(
                text: 'Ride',
                variant: TarangButtonVariant.primary,
                size: TarangButtonSize.sm,
                onPressed: () => ref.read(searchProvider.notifier).toggleRideSearchResult(user.id),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exploreState = ref.watch(exploreProvider);
    final searchState = ref.watch(searchProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return Scaffold(
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TarangTextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              hint: 'Search Waves, Riders, Hashtags...',
              leftIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
              rightIcon: _isSearchingActive
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                      child: const Icon(Icons.clear_rounded, color: AppTheme.textMuted),
                    )
                  : null,
              onSubmitted: _handleSearchSubmit,
            ),
          ),

          // Search Kind Tabs (visible only when search text is active)
          if (_isSearchingActive)
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: TabBar(
                controller: _tabController,
                labelStyle: AppTextStyles.label.copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: AppTextStyles.label,
                labelColor: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                unselectedLabelColor: AppTheme.textMuted,
                indicatorColor: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'Riders'),
                  Tab(text: 'Waves'),
                  Tab(text: 'Circles'),
                ],
              ),
            ),

          // Body list
          Expanded(
            child: _isSearchingActive ? _buildSearchResults(searchState) : _buildTrendingDashboard(exploreState),
          ),
        ],
      ),
    );
  }
}
