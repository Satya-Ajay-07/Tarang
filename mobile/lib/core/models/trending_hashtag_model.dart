import 'package:equatable/equatable.dart';

class TrendingHashtagModel extends Equatable {
  final String tag;
  final int count;

  const TrendingHashtagModel({
    required this.tag,
    required this.count,
  });

  factory TrendingHashtagModel.fromJson(Map<String, dynamic> json) {
    return TrendingHashtagModel(
      tag: json['tag'] as String,
      count: json['count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tag': tag,
      'count': count,
    };
  }

  @override
  List<Object?> get props => [tag, count];
}
