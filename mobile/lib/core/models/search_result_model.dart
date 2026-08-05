import 'package:equatable/equatable.dart';
import 'user_model.dart';

class WaveSearchResultModel extends Equatable {
  final String id;
  final String? content;
  final String creatorId;
  final DateTime createdAt;
  final int ripplesCount;

  const WaveSearchResultModel({
    required this.id,
    this.content,
    required this.creatorId,
    required this.createdAt,
    required this.ripplesCount,
  });

  factory WaveSearchResultModel.fromJson(Map<String, dynamic> json) {
    return WaveSearchResultModel(
      id: json['id'] as String,
      content: json['content'] as String?,
      creatorId: json['creator_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      ripplesCount: json['ripples_count'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [id, content, creatorId, createdAt, ripplesCount];
}

class SearchResultModel extends Equatable {
  final String query;
  final List<UserModel> people;
  final List<WaveSearchResultModel> waves;

  const SearchResultModel({
    required this.query,
    required this.people,
    required this.waves,
  });

  factory SearchResultModel.fromJson(Map<String, dynamic> json) {
    return SearchResultModel(
      query: json['query'] as String? ?? '',
      people: (json['people'] as List<dynamic>?)
              ?.map((e) => UserModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      waves: (json['waves'] as List<dynamic>?)
              ?.map((e) => WaveSearchResultModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  @override
  List<Object?> get props => [query, people, waves];
}
