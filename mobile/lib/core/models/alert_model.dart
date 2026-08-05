import 'package:equatable/equatable.dart';
import 'package:mobile/core/models/user_model.dart';

class AlertModel extends Equatable {
  final String id;
  final String recipientId;
  final UserModel? sender;
  final String? waveId;
  final String type; // ripple, join, spread, follow
  final String? content;
  final bool isRead;
  final DateTime createdAt;

  const AlertModel({
    required this.id,
    required this.recipientId,
    this.sender,
    this.waveId,
    required this.type,
    this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      recipientId: json['recipient_id'] as String,
      sender: json['sender'] != null
          ? UserModel.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      waveId: json['wave_id'] as String?,
      type: json['type'] as String,
      content: json['content'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recipient_id': recipientId,
      'sender': sender?.toJson(),
      'wave_id': waveId,
      'type': type,
      'content': content,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AlertModel copyWith({
    String? id,
    String? recipientId,
    UserModel? sender,
    String? waveId,
    String? type,
    String? content,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return AlertModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      sender: sender ?? this.sender,
      waveId: waveId ?? this.waveId,
      type: type ?? this.type,
      content: content ?? this.content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        recipientId,
        sender,
        waveId,
        type,
        content,
        isRead,
        createdAt,
      ];
}
