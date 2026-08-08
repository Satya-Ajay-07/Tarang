import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:mobile/core/network/api_client.dart';
import 'package:mobile/core/providers/core_providers.dart';
import 'package:mobile/core/storage/secure_storage_service.dart';
import 'package:mobile/features/messages/models/conversation_model.dart';
import 'package:mobile/features/messages/models/message_model.dart';
import 'package:mobile/features/authentication/providers/auth_provider.dart';

enum TarangSocketState { disconnected, connecting, connected, reconnecting, disposed }

class MessagesState {
  final List<ConversationModel> conversations;
  final Map<String, List<MessageModel>> messagesByUserId;
  final Map<String, bool> typingUsers;
  final bool isLoading;

  MessagesState({
    required this.conversations,
    required this.messagesByUserId,
    required this.typingUsers,
    required this.isLoading,
  });

  MessagesState.initial()
      : conversations = [],
        messagesByUserId = {},
        typingUsers = {},
        isLoading = false;

  MessagesState copyWith({
    List<ConversationModel>? conversations,
    Map<String, List<MessageModel>>? messagesByUserId,
    Map<String, bool>? typingUsers,
    bool? isLoading,
  }) {
    return MessagesState(
      conversations: conversations ?? this.conversations,
      messagesByUserId: messagesByUserId ?? this.messagesByUserId,
      typingUsers: typingUsers ?? this.typingUsers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  TarangSocketState _socketState = TarangSocketState.disconnected;
  int _reconnectAttempts = 0;
  bool _isIntentionallyDisconnected = false;

  MessagesNotifier(this._apiClient, this._secureStorage) : super(MessagesState.initial()) {
    loadConversations();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _socketState = TarangSocketState.disposed;
    _isIntentionallyDisconnected = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    super.dispose();
  }

  Future<void> loadConversations() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.dio.get('/messages');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final list = data.map((json) => ConversationModel.fromJson(json)).toList();
        state = state.copyWith(conversations: list, isLoading: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadMessages(String otherUserId) async {
    try {
      final response = await _apiClient.dio.get('/messages/$otherUserId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final list = data.map((json) => MessageModel.fromJson(json)).toList();
        
        final map = Map<String, List<MessageModel>>.from(state.messagesByUserId);
        map[otherUserId] = list;
        state = state.copyWith(messagesByUserId: map);

        // Mark read
        await markAsRead(otherUserId);
      }
    } catch (e) {
      // fail silently
    }
  }

  Future<void> markAsRead(String otherUserId) async {
    try {
      final response = await _apiClient.dio.post('/messages/$otherUserId/read', data: {});
      if (response.statusCode == 200) {
        // Send WS read receipt
        if (_socketState == TarangSocketState.connected) {
          _channel?.sink.add(jsonEncode({
            'type': 'read_receipt',
            'recipient_id': otherUserId,
          }));
        }

        // Reset unread count locally
        final updatedConversations = state.conversations.map((c) {
          if (c.otherUser.id == otherUserId) {
            return ConversationModel(
              otherUser: c.otherUser,
              lastMessage: c.lastMessage,
              unreadCount: 0,
            );
          }
          return c;
        }).toList();

        state = state.copyWith(conversations: updatedConversations);
      }
    } catch (e) {
      // silent
    }
  }

  Future<void> _connectWebSocket() async {
    if (_socketState == TarangSocketState.connecting ||
        _socketState == TarangSocketState.connected ||
        _socketState == TarangSocketState.disposed ||
        _isIntentionallyDisconnected) {
      return;
    }

    _socketState = TarangSocketState.connecting;
    final token = await _secureStorage.getAccessToken();
    if (token == null) {
      _socketState = TarangSocketState.disconnected;
      return;
    }

    // Map http API url to ws url
    final baseUrl = _apiClient.dio.options.baseUrl;
    final wsProtocol = baseUrl.startsWith('https') ? 'wss' : 'ws';
    final host = baseUrl.replaceFirst(RegExp(r'https?://'), '').split('/api')[0];
    final wsUrl = '$wsProtocol://$host/api/v1/ws?token=$token';

    try {
      _subscription?.cancel();
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      _subscription = _channel!.stream.listen(
        (message) {
          if (_socketState == TarangSocketState.connecting) {
            _socketState = TarangSocketState.connected;
            _reconnectAttempts = 0; // Reset backoff on successful connection
          }
          _handleIncomingEvent(message);
        },
        onError: (err) {
          _handleDisconnect();
        },
        onDone: () {
          _handleDisconnect();
        },
      );

      _socketState = TarangSocketState.connected;
      _reconnectAttempts = 0;

      // Start ping timer every 30s
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
        if (_socketState == TarangSocketState.connected) {
          _channel?.sink.add(jsonEncode({'type': 'ping'}));
        }
      });
    } catch (_) {
      _handleDisconnect();
    }
  }

  void _handleDisconnect() {
    if (_socketState == TarangSocketState.disposed || _isIntentionallyDisconnected) {
      return;
    }
    _socketState = TarangSocketState.disconnected;
    _pingTimer?.cancel();
    _subscription?.cancel();
    _reconnectWS();
  }

  void _reconnectWS() {
    if (_reconnectTimer?.isActive ?? false) return;
    if (_socketState == TarangSocketState.disposed || _isIntentionallyDisconnected) return;

    _socketState = TarangSocketState.reconnecting;
    
    // Calculate exponential backoff delay capped at 60s
    int seconds = (1 << _reconnectAttempts);
    if (seconds < 2) seconds = 2;
    if (seconds > 60) seconds = 60;

    _reconnectAttempts++;

    _reconnectTimer = Timer(Duration(seconds: seconds), () {
      _reconnectTimer = null;
      if (mounted && !_isIntentionallyDisconnected && _socketState != TarangSocketState.disposed) {
        _connectWebSocket();
      }
    });
  }

  void _handleIncomingEvent(dynamic event) {
    try {
      final data = jsonDecode(event as String);
      final type = data['type'] as String?;

      if (type == 'pong') {
        return;
      }

      if (type == 'message') {
        final msg = MessageModel.fromJson(data['message'] as Map<String, dynamic>);
        final otherId = msg.senderId == _apiClient.dio.options.headers['userId']
            ? msg.recipientId
            : msg.senderId;

        // Add message to chat log
        final map = Map<String, List<MessageModel>>.from(state.messagesByUserId);
        final list = map[otherId] ?? [];
        map[otherId] = [...list, msg];

        // Update last message in thread list
        bool foundThread = false;
        final updatedConversations = state.conversations.map((c) {
          if (c.otherUser.id == otherId) {
            foundThread = true;
            return ConversationModel(
              otherUser: c.otherUser,
              lastMessage: msg,
              unreadCount: msg.senderId != otherId ? c.unreadCount : c.unreadCount + 1,
            );
          }
          return c;
        }).toList();

        state = state.copyWith(
          messagesByUserId: map,
          conversations: updatedConversations,
        );

        if (!foundThread) {
          // reload threads if it's a new conversation
          loadConversations();
        }
      } else if (type == 'typing') {
        final senderId = data['sender_id'] as String;
        final isTyping = data['typing'] as bool? ?? false;
        
        final typingMap = Map<String, bool>.from(state.typingUsers);
        typingMap[senderId] = isTyping;
        state = state.copyWith(typingUsers: typingMap);
      } else if (type == 'read_receipt') {
        final readerId = data['reader_id'] as String;
        // Mark all sent messages as read in the specific user's chat thread
        final map = Map<String, List<MessageModel>>.from(state.messagesByUserId);
        final list = map[readerId] ?? [];
        final updatedList = list.map((m) {
          if (m.recipientId == readerId) {
            return MessageModel(
              id: m.id,
              senderId: m.senderId,
              recipientId: m.recipientId,
              content: m.content,
              createdAt: m.createdAt,
              isRead: true,
            );
          }
          return m;
        }).toList();

        map[readerId] = updatedList;
        state = state.copyWith(messagesByUserId: map);
      }
    } catch (_) {
      // parse failure
    }
  }

  void sendMessage(String recipientId, String content) {
    if (content.trim().isEmpty) return;
    final payload = {
      'type': 'message',
      'recipient_id': recipientId,
      'content': content,
    };
    if (_socketState == TarangSocketState.connected) {
      _channel?.sink.add(jsonEncode(payload));
    }
  }

  void sendTypingStatus(String recipientId, bool isTyping) {
    final payload = {
      'type': 'typing',
      'recipient_id': recipientId,
      'typing': isTyping,
    };
    if (_socketState == TarangSocketState.connected) {
      _channel?.sink.add(jsonEncode(payload));
    }
  }

  void closeSocketIntentionally() {
    _isIntentionallyDisconnected = true;
    _pingTimer?.cancel();
    _reconnectTimer?.cancel();
    _subscription?.cancel();
    _channel?.sink.close();
    _socketState = TarangSocketState.disconnected;
  }
}

final messagesProvider = StateNotifierProvider<MessagesNotifier, MessagesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final secureStorage = ref.watch(secureStorageServiceProvider);
  final notifier = MessagesNotifier(apiClient, secureStorage);

  ref.listen<AuthState>(authProvider, (previous, next) {
    if (next.status != AuthStatus.authenticated) {
      notifier.closeSocketIntentionally();
    }
  });

  return notifier;
});
