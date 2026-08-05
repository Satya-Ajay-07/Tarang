import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/models/trending_hashtag_model.dart';
import 'package:mobile/core/models/wave_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/explore/providers/explore_providers.dart';
import 'package:mobile/features/explore/hashtag_page.dart';
import 'package:mobile/features/home/widgets/wave_card.dart';

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

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _triggerSearch();
    });
  }

  void _triggerSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      ref.read(searchProvider.notifier).search('');
      return;
    }

    final kinds = ['all', 'people', 'waves', 'circles'];
    final selectedKind = kinds[_tabController!.index];
    ref.read(searchProvider.notifier).search(query, kind: selectedKind);
  }

  void _handleRecentSearchTap(String query) {
    _searchController.text = query;
    _searchFocusNode.unfocus();
    ref.read(searchProvider.notifier).addRecentSearch(query);
  }

  void _handleSearchSubmit(String query) {
    if (query.trim().isNotEmpty) {
      ref.read(searchProvider.notifier).addRecentSearch(query.trim());
    }
  }

  Widget _buildSuggestedRiderRow(dynamic rider) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      padding: const EdgeInsets.all(AppTheme.spaceM),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusM),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          CustomAvatar(url: rider.avatarUrl, radius: 20),
          const SizedBox(width: AppTheme.spaceM),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rider.fullName ?? rider.username,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  '@${rider.username}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                if (rider.bio != null && rider.bio!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    rider.bio!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(exploreProvider.notifier).toggleRideSuggested(rider.id);
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('Ride', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendingHashtagTile(TrendingHashtagModel tag) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(Icons.trending_up, color: AppTheme.primaryTeal, size: 18),
        ),
      ),
      title: Text(
        '#${tag.tag}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${tag.count} waves'),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => HashtagPage(tag: '#${tag.tag}'),
          ),
        );
      },
    );
  }

  Widget _buildTrendingWavesList(List<WaveModel> waves) {
    if (waves.isEmpty) return const SizedBox.shrink();
    return Column(
      children: waves.map((w) => WaveCard(wave: w)).toList(),
    );
  }

  Widget _buildExploreHub() {
    final state = ref.watch(exploreProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: AppTheme.spaceM),
            Text(state.errorMessage!),
            const SizedBox(height: AppTheme.spaceM),
            ElevatedButton(
              onPressed: () =>
                  ref.read(exploreProvider.notifier).loadExploreData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(exploreProvider.notifier).loadExploreData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Suggested Riders Section
            if (state.suggestedRiders.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '👥 Suggested Riders',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppTheme.spaceM),
                    ...state.suggestedRiders.map(_buildSuggestedRiderRow),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Trending Hashtags Section
            if (state.trendingHashtags.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.all(AppTheme.spaceM),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🏷 Trending Hashtags',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: AppTheme.spaceS),
                    ...state.trendingHashtags.map(_buildTrendingHashtagTile),
                  ],
                ),
              ),
              const Divider(height: 1),
            ],

            // Trending Waves Section
            if (state.trendingWaves.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(AppTheme.spaceM),
                child: Text(
                  '🔥 Trending Waves',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              _buildTrendingWavesList(state.trendingWaves),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(List<String> recents) {
    if (recents.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spaceM, vertical: AppTheme.spaceS),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Recent Searches',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.grey)),
              TextButton(
                onPressed: () =>
                    ref.read(searchProvider.notifier).clearRecentSearches(),
                child: const Text('Clear All'),
              ),
            ],
          ),
        ),
        ...recents.map((query) => ListTile(
              leading: const Icon(Icons.history, color: Colors.grey),
              title: Text(query),
              onTap: () => _handleRecentSearchTap(query),
            )),
        const Divider(),
      ],
    );
  }

  Widget _buildSearchResultsList() {
    final searchState = ref.watch(searchProvider);

    if (searchState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (searchState.errorMessage != null) {
      return Center(
        child: Text(searchState.errorMessage!),
      );
    }

    if (searchState.people.isEmpty && searchState.waves.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceXL),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🌊', style: TextStyle(fontSize: 48)),
              const SizedBox(height: AppTheme.spaceM),
              Text(
                'Nothing found for "${searchState.query}"',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppTheme.spaceS),
              const Text(
                'Try searching for different keywords or explore suggested riders.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // All
        ListView(
          children: [
            if (searchState.people.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(AppTheme.spaceM),
                child: Text('People',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ...searchState.people.map((u) => ListTile(
                    leading: CustomAvatar(url: u.avatarUrl),
                    title: Text(u.fullName ?? u.username),
                    subtitle: Text('@${u.username}'),
                    trailing: ElevatedButton(
                      onPressed: () => ref
                          .read(searchProvider.notifier)
                          .toggleRideSearchResult(u.id),
                      child: const Text('Ride'),
                    ),
                  )),
            ],
            if (searchState.waves.isNotEmpty) ...[
              const Padding(
                padding: EdgeInsets.all(AppTheme.spaceM),
                child: Text('Waves',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              ...searchState.waves.map((w) => WaveCard(wave: w)),
            ],
          ],
        ),

        // People
        ListView.builder(
          itemCount: searchState.people.length,
          itemBuilder: (context, index) {
            final u = searchState.people[index];
            return ListTile(
              leading: CustomAvatar(url: u.avatarUrl),
              title: Text(u.fullName ?? u.username),
              subtitle: Text('@${u.username}'),
              trailing: ElevatedButton(
                onPressed: () => ref
                    .read(searchProvider.notifier)
                    .toggleRideSearchResult(u.id),
                child: const Text('Ride'),
              ),
            );
          },
        ),

        // Waves
        ListView.builder(
          itemCount: searchState.waves.length,
          itemBuilder: (context, index) =>
              WaveCard(wave: searchState.waves[index]),
        ),

        // Hashtags Placeholder view (since search has no custom hashtags array, display suggestions)
        ListView(
          padding: const EdgeInsets.all(AppTheme.spaceM),
          children: [
            const Icon(Icons.tag, size: 64, color: Colors.grey),
            const SizedBox(height: AppTheme.spaceM),
            const Text(
              'Hashtags Feed',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: AppTheme.spaceS),
            Text(
              'Explore trending tags on the explore hub page.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spaceM),
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onSubmitted: _handleSearchSubmit,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                hintText: 'Search people, waves, hashtags...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                suffixIcon: _isSearchingActive
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocusNode.unfocus();
                          ref.read(searchProvider.notifier).search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
        ),
        bottom: _isSearchingActive
            ? TabBar(
                controller: _tabController,
                indicatorColor: AppTheme.primaryTeal,
                labelColor: AppTheme.primaryTeal,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(text: 'People'),
                  Tab(text: 'Waves'),
                  Tab(text: 'Hashtags'),
                ],
              )
            : null,
      ),
      body: SafeArea(
        child: _isSearchingActive
            ? Column(
                children: [
                  if (_searchController.text.trim().isNotEmpty &&
                      searchState.waves.isEmpty &&
                      searchState.people.isEmpty)
                    _buildRecentSearches(searchState.recentSearches),
                  Expanded(child: _buildSearchResultsList()),
                ],
              )
            : _buildExploreHub(),
      ),
    );
  }
}
