import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/features/messages/providers/messages_provider.dart';
import 'package:mobile/features/messages/chat_screen.dart';

class ConversationListScreen extends ConsumerStatefulWidget {
  const ConversationListScreen({super.key});

  @override
  ConsumerState<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends ConsumerState<ConversationListScreen> {
  final _searchController = TextEditingController();
  List<UserModel> _searchResults = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider.notifier).loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    try {
      final response = await ref.read(apiClientProvider).dio.get('/explore', queryParameters: {'q': query, 'kind': 'people'});
      if (response.statusCode == 200) {
        final List<dynamic>? usersJson = response.data['people']; // API returns people
        if (usersJson != null) {
          final list = usersJson.map((json) => UserModel.fromJson(json)).toList();
          setState(() {
            _searchResults = list;
          });
        }
      }
    } catch (_) {
      // ignore
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    return Scaffold(
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: borderColor)),
        title: Text(
          'Messages',
          style: AppTextStyles.h5.copyWith(color: textThemeColor, fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // Search box
          Padding(
            padding: const EdgeInsets.all(16),
            child: TarangTextField(
              controller: _searchController,
              onChanged: _performSearch,
              hint: 'Search people to chat...',
              leftIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted),
            ),
          ),

          Expanded(
            child: _searchController.text.isNotEmpty
                ? _buildSearchResults()
                : _buildConversationsList(state),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    if (_isSearching) {
      return const Center(child: TarangLoading());
    }

    if (_searchResults.isEmpty) {
      return const TarangEmptyState(
        title: 'No users found',
        body: 'Try searching for another rider handle or name.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final user = _searchResults[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: TarangCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: TarangAvatar(
                username: user.username,
                avatarUrl: user.avatarUrl,
                size: TarangAvatarSize.md,
              ),
              title: Text(
                user.fullName ?? user.username,
                style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
              ),
              subtitle: Text(
                '@${user.username}',
                style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
              ),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => ChatScreen(otherUser: user),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildConversationsList(MessagesState state) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;

    if (state.isLoading && state.conversations.isEmpty) {
      return const Center(child: TarangLoading());
    }

    if (state.conversations.isEmpty) {
      return const TarangEmptyState(
        title: 'No conversations yet',
        body: 'Search users above to start messaging.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(messagesProvider.notifier).loadConversations(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: state.conversations.length,
        itemBuilder: (context, index) {
          final conv = state.conversations[index];
          final lastMsg = conv.lastMessage;

          // Time elapsed string
          String timeStr = '';
          if (lastMsg != null) {
            final diff = DateTime.now().difference(lastMsg.createdAt);
            if (diff.inMinutes < 60) {
              timeStr = '${diff.inMinutes}m';
            } else if (diff.inHours < 24) {
              timeStr = '${diff.inHours}h';
            } else {
              timeStr = '${diff.inDays}d';
            }
          }

          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: TarangCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: TarangAvatar(
                  username: conv.otherUser.username,
                  avatarUrl: conv.otherUser.avatarUrl,
                  size: TarangAvatarSize.md,
                ),
                title: Text(
                  conv.otherUser.fullName ?? conv.otherUser.username,
                  style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                ),
                subtitle: Text(
                  lastMsg?.content ?? 'Start chatting...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    fontWeight: conv.unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
                    color: conv.unreadCount > 0
                        ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
                        : AppTheme.textMuted,
                  ),
                ),
                trailing: conv.unreadCount > 0
                    ? Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          conv.unreadCount.toString(),
                          style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      )
                    : (lastMsg != null
                        ? Text(
                            timeStr,
                            style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                          )
                        : null),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(otherUser: conv.otherUser),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
