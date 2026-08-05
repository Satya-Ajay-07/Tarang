import 'package:equatable/equatable.dart';
import 'user_model.dart';

class RegisterResponseModel extends Equatable {
  final bool success;
  final UserModel user;
  final String? warning;

  const RegisterResponseModel({
    required this.success,
    required this.user,
    this.warning,
  });

  factory RegisterResponseModel.fromJson(Map<String, dynamic> json) {
    return RegisterResponseModel(
      success: json['success'] as bool? ?? true,
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      warning: json['warning'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'user': user.toJson(),
      'warning': warning,
    };
  }

  @override
  List<Object?> get props => [success, user, warning];
}
