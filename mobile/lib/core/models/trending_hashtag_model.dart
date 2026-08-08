import 'package:equatable/equatable.dart';

class TrendingHashtagModel extends Equatable {
  final String tag;
  final int count;
  final String category;

  const TrendingHashtagModel({
    required this.tag,
    required this.count,
    required this.category,
  });

  factory TrendingHashtagModel.fromJson(Map<String, dynamic> json) {
    return TrendingHashtagModel(
      tag: json['tag'] as String,
      count: json['count'] as int? ?? 0,
      category: json['category'] as String? ?? 'popular_this_week',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'count': count,
      'category': category,
    };
  }

  @override
  List<Object?> get props => [tag, count, category];
}
