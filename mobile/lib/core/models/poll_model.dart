import 'package:equatable/equatable.dart';

class PollOptionModel extends Equatable {
  final String id;
  final String pollId;
  final String text;
  final int votesCount;
  final bool votedByMe;

  const PollOptionModel({
    required this.id,
    required this.pollId,
    required this.text,
    required this.votesCount,
    required this.votedByMe,
  });

  factory PollOptionModel.fromJson(Map<String, dynamic> json) {
    return PollOptionModel(
      id: json['id'] as String,
      pollId: json['poll_id'] as String,
      text: json['text'] as String,
      votesCount: json['votes_count'] as int? ?? 0,
      votedByMe: json['voted_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'poll_id': pollId,
      'text': text,
      'votes_count': votesCount,
      'voted_by_me': votedByMe,
    };
  }

  PollOptionModel copyWith({
    int? votesCount,
    bool? votedByMe,
  }) {
    return PollOptionModel(
      id: id,
      pollId: pollId,
      text: text,
      votesCount: votesCount ?? this.votesCount,
      votedByMe: votedByMe ?? this.votedByMe,
    );
  }

  @override
  List<Object?> get props => [id, pollId, text, votesCount, votedByMe];
}

class PollModel extends Equatable {
  final String id;
  final String question;
  final DateTime expiresAt;
  final List<PollOptionModel> options;
  final int totalVotes;
  final bool hasVoted;
  final String? votedOptionId;

  const PollModel({
    required this.id,
    required this.question,
    required this.expiresAt,
    required this.options,
    required this.totalVotes,
    required this.hasVoted,
    this.votedOptionId,
  });

  factory PollModel.fromJson(Map<String, dynamic> json) {
    return PollModel(
      id: json['id'] as String,
      question: json['question'] as String,
      expiresAt: DateTime.parse(json['expires_at'] as String),
      options: (json['options'] as List<dynamic>?)
              ?.map((e) => PollOptionModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      totalVotes: json['total_votes'] as int? ?? 0,
      hasVoted: json['has_voted'] as bool? ?? false,
      votedOptionId: json['voted_option_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'question': question,
      'expires_at': expiresAt.toIso8601String(),
      'options': options.map((e) => e.toJson()).toList(),
      'total_votes': totalVotes,
      'has_voted': hasVoted,
      'voted_option_id': votedOptionId,
    };
  }

  PollModel copyWith({
    List<PollOptionModel>? options,
    int? totalVotes,
    bool? hasVoted,
    String? votedOptionId,
  }) {
    return PollModel(
      id: id,
      question: question,
      expiresAt: expiresAt,
      options: options ?? this.options,
      totalVotes: totalVotes ?? this.totalVotes,
      hasVoted: hasVoted ?? this.hasVoted,
      votedOptionId: votedOptionId ?? this.votedOptionId,
    );
  }

  @override
  List<Object?> get props => [id, question, expiresAt, options, totalVotes, hasVoted, votedOptionId];
}
