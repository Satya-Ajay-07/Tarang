import 'package:equatable/equatable.dart';
import 'user_model.dart';
import 'poll_model.dart';

class WaveModel extends Equatable {
  final String id;
  final String? content;
  final String? mediaUrl;
  final String? mediaType;
  final String creatorId;
  final UserModel creator;
  final DateTime createdAt;
  final String? parentWaveId;
  final String? spreadFromId;
  final WaveModel? spreadFrom;
  final String? circleId;
  final int ripplesCount;
  final int joinsCount;
  final int spreadsCount;
  final bool rippledByMe;
  final bool spreadByMe;
  final bool bookmarkedByMe;
  final PollModel? poll;
  final DateTime? updatedAt;
  final bool isEdited;

  const WaveModel({
    required this.id,
    this.content,
    this.mediaUrl,
    this.mediaType,
    required this.creatorId,
    required this.creator,
    required this.createdAt,
    this.parentWaveId,
    this.spreadFromId,
    this.spreadFrom,
    this.circleId,
    required this.ripplesCount,
    required this.joinsCount,
    required this.spreadsCount,
    required this.rippledByMe,
    required this.spreadByMe,
    required this.bookmarkedByMe,
    this.poll,
    this.updatedAt,
    required this.isEdited,
  });

  factory WaveModel.fromJson(Map<String, dynamic> json) {
    return WaveModel(
      id: json['id'] as String,
      content: json['content'] as String?,
      mediaUrl: json['media_url'] as String?,
      mediaType: json['media_type'] as String?,
      creatorId: json['creator_id'] as String,
      creator: UserModel.fromJson(json['creator'] as Map<String, dynamic>),
      createdAt: DateTime.parse(json['created_at'] as String),
      parentWaveId: json['parent_wave_id'] as String?,
      spreadFromId: json['spread_from_id'] as String?,
      spreadFrom: json['spread_from'] != null
          ? WaveModel.fromJson(json['spread_from'] as Map<String, dynamic>)
          : null,
      circleId: json['circle_id'] as String?,
      ripplesCount: json['ripples_count'] as int? ?? 0,
      joinsCount: json['joins_count'] as int? ?? 0,
      spreadsCount: json['spreads_count'] as int? ?? 0,
      rippledByMe: json['rippled_by_me'] as bool? ?? false,
      spreadByMe: json['spread_by_me'] as bool? ?? false,
      bookmarkedByMe: json['bookmarked_by_me'] as bool? ?? false,
      poll: json['poll'] != null
          ? PollModel.fromJson(json['poll'] as Map<String, dynamic>)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      isEdited: json['is_edited'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'media_url': mediaUrl,
      'media_type': mediaType,
      'creator_id': creatorId,
      'creator': creator.toJson(),
      'created_at': createdAt.toIso8601String(),
      'parent_wave_id': parentWaveId,
      'spread_from_id': spreadFromId,
      'spread_from': spreadFrom?.toJson(),
      'circle_id': circleId,
      'ripples_count': ripplesCount,
      'joins_count': joinsCount,
      'spreads_count': spreadsCount,
      'rippled_by_me': rippledByMe,
      'spread_by_me': spreadByMe,
      'bookmarked_by_me': bookmarkedByMe,
      'poll': poll?.toJson(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_edited': isEdited,
    };
  }

  WaveModel copyWith({
    String? content,
    String? mediaUrl,
    String? mediaType,
    int? ripplesCount,
    int? joinsCount,
    int? spreadsCount,
    bool? rippledByMe,
    bool? spreadByMe,
    bool? bookmarkedByMe,
    PollModel? poll,
    DateTime? updatedAt,
    bool? isEdited,
    WaveModel? spreadFrom,
  }) {
    return WaveModel(
      id: id,
      content: content ?? this.content,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      mediaType: mediaType ?? this.mediaType,
      creatorId: creatorId,
      creator: creator,
      createdAt: createdAt,
      parentWaveId: parentWaveId,
      spreadFromId: spreadFromId,
      spreadFrom: spreadFrom ?? this.spreadFrom,
      circleId: circleId,
      ripplesCount: ripplesCount ?? this.ripplesCount,
      joinsCount: joinsCount ?? this.joinsCount,
      spreadsCount: spreadsCount ?? this.spreadsCount,
      rippledByMe: rippledByMe ?? this.rippledByMe,
      spreadByMe: spreadByMe ?? this.spreadByMe,
      bookmarkedByMe: bookmarkedByMe ?? this.bookmarkedByMe,
      poll: poll ?? this.poll,
      updatedAt: updatedAt ?? this.updatedAt,
      isEdited: isEdited ?? this.isEdited,
    );
  }

  @override
  List<Object?> get props => [
        id,
        content,
        mediaUrl,
        mediaType,
        creatorId,
        creator,
        createdAt,
        parentWaveId,
        spreadFromId,
        spreadFrom,
        circleId,
        ripplesCount,
        joinsCount,
        spreadsCount,
        rippledByMe,
        spreadByMe,
        bookmarkedByMe,
        poll,
        updatedAt,
        isEdited,
      ];
}
