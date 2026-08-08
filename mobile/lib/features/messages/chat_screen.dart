import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/core/theme/app_text_styles.dart';
import 'package:mobile/core/models/user_model.dart';
import 'package:mobile/core/shared/widgets/app_widgets.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';
import 'package:mobile/features/messages/providers/messages_provider.dart';
import 'package:mobile/features/messages/models/message_model.dart';
import 'package:mobile/core/services/haptic_service.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final UserModel otherUser;

  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(messagesProvider.notifier).loadMessages(widget.otherUser.id);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onTextChanged(String text) {
    ref.read(messagesProvider.notifier).sendTypingStatus(widget.otherUser.id, true);
    
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      ref.read(messagesProvider.notifier).sendTypingStatus(widget.otherUser.id, false);
    });
  }

  void _handleSend() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;
    
    HapticService.light();
    ref.read(messagesProvider.notifier).sendMessage(widget.otherUser.id, text);
    _inputController.clear();
    
    ref.read(messagesProvider.notifier).sendTypingStatus(widget.otherUser.id, false);
    
    // Auto-scroll
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(messagesProvider);
    final currentUserId = ref.read(authProvider).user?.id ?? '';
    
    final messages = state.messagesByUserId[widget.otherUser.id] ?? [];
    final isTyping = state.typingUsers[widget.otherUser.id] ?? false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textThemeColor = isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight;
    final borderColor = isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder;

    // Scroll to bottom on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && messages.isNotEmpty) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });

    return Scaffold(
      appBar: AppBar(
        shape: Border(bottom: BorderSide(color: borderColor)),
        title: Row(
          children: [
            TarangAvatar(
              username: widget.otherUser.username,
              avatarUrl: widget.otherUser.avatarUrl,
              size: TarangAvatarSize.sm,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.otherUser.fullName ?? widget.otherUser.username,
                    style: AppTextStyles.captionBold.copyWith(color: textThemeColor),
                  ),
                  if (isTyping)
                    Text(
                      'typing...',
                      style: AppTextStyles.metadata.copyWith(
                        color: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    Text(
                      '@${widget.otherUser.username}',
                      style: AppTextStyles.metadata.copyWith(color: AppTheme.textMuted),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: messages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TarangAvatar(
                            username: widget.otherUser.username,
                            avatarUrl: widget.otherUser.avatarUrl,
                            size: TarangAvatarSize.lg,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Say hi to ${widget.otherUser.fullName ?? widget.otherUser.username}!',
                            style: AppTextStyles.captionBold.copyWith(color: AppTheme.textMuted),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg.senderId == currentUserId;
                        return _buildMessageBubble(msg, isMe);
                      },
                    ),
            ),
            
            // Input Row
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TarangTextField(
                      controller: _inputController,
                      onChanged: _onTextChanged,
                      hint: 'Type a message...',
                      onSubmitted: (_) => _handleSend(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TarangIconButton(
                    icon: const Icon(Icons.send_rounded, size: 18),
                    size: 40,
                    backgroundColor: isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal,
                    foregroundColor: Colors.white,
                    hasBorder: false,
                    onPressed: _handleSend,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe
              ? (isDark ? AppTheme.primaryTealLight : AppTheme.primaryTeal)
              : (isDark ? AppTheme.darkCard : AppTheme.lightCard),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16),
          ),
          border: isMe
              ? null
              : Border.all(color: isDark ? AppTheme.darkCardBorder : AppTheme.lightCardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              msg.content,
              style: AppTextStyles.caption.copyWith(
                color: isMe ? Colors.white : (isDark ? AppTheme.textPrimaryDark : AppTheme.textPrimaryLight),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${msg.createdAt.toLocal().hour}:${msg.createdAt.toLocal().minute.toString().padLeft(2, '0')}',
                  style: AppTextStyles.metadata.copyWith(
                    color: isMe ? Colors.white60 : AppTheme.textMuted,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all_rounded,
                    size: 12,
                    color: msg.isRead ? Colors.lightBlueAccent : Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
