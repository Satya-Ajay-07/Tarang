import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String username;
  final String? fullName;
  final String? country;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? location;
  final DateTime createdAt;
  final String role;
  final String? phoneNumber;
  final String? website;
  final String? twitterUrl;
  final String? githubUrl;
  final String? pinnedWaveId;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.email,
    required this.username,
    this.fullName,
    this.country,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.location,
    required this.createdAt,
    required this.role,
    this.phoneNumber,
    this.website,
    this.twitterUrl,
    this.githubUrl,
    this.pinnedWaveId,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String,
      fullName: json['full_name'] as String?,
      country: json['country'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      coverUrl: json['cover_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      role: json['role'] as String? ?? 'user',
      phoneNumber: json['phone_number'] as String?,
      website: json['website'] as String?,
      twitterUrl: json['twitter_url'] as String?,
      githubUrl: json['github_url'] as String?,
      pinnedWaveId: json['pinned_wave_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'country': country,
      'avatar_url': avatarUrl,
      'cover_url': coverUrl,
      'bio': bio,
      'location': location,
      'created_at': createdAt.toIso8601String(),
      'role': role,
      'phone_number': phoneNumber,
      'website': website,
      'twitter_url': twitterUrl,
      'github_url': githubUrl,
      'pinned_wave_id': pinnedWaveId,
      'is_active': isActive,
    };
  }

  @override
  List<Object?> get props => [
        id,
        email,
        username,
        fullName,
        country,
        avatarUrl,
        coverUrl,
        bio,
        location,
        createdAt,
        role,
        phoneNumber,
        website,
        twitterUrl,
        githubUrl,
        pinnedWaveId,
        isActive,
      ];
}
