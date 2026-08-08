import 'package:equatable/equatable.dart';
import 'package:mobile/core/models/user_model.dart';
import 'message_model.dart';

class ConversationModel extends Equatable {
  final UserModel otherUser;
  final MessageModel? lastMessage;
  final int unreadCount;

  const ConversationModel({
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      otherUser: UserModel.fromJson(json['other_user'] as Map<String, dynamic>),
      lastMessage: json['last_message'] != null
          ? MessageModel.fromJson(json['last_message'] as Map<String, dynamic>)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'other_user': otherUser.toJson(),
      'last_message': lastMessage?.toJson(),
      'unread_count': unreadCount,
    };
  }

  @override
  List<Object?> get props => [otherUser, lastMessage, unreadCount];
}
