import 'package:equatable/equatable.dart';

class AchievementModel extends Equatable {
  final String id;
  final String name;
  final String icon;
  final String description;
  final String category;
  final bool unlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.category,
    required this.unlocked,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      description: json['description'] as String,
      category: json['category'] as String? ?? 'special',
      unlocked: json['unlocked'] as bool? ?? false,
      unlockedAt: json['unlocked_at'] != null
          ? DateTime.parse(json['unlocked_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'description': description,
      'category': category,
      'unlocked': unlocked,
      'unlocked_at': unlockedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        icon,
        description,
        category,
        unlocked,
        unlockedAt,
      ];
}
