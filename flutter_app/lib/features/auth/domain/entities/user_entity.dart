import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String  id;
  final String  email;
  final String  role;
  final String? fullName;
  final String? avatarUrl;
  final bool    isActive;

  const UserEntity({
    required this.id,
    required this.email,
    required this.role,
    this.fullName,
    this.avatarUrl,
    this.isActive = true,
  });

  @override
  List<Object?> get props => [id, email, role];

  bool get isVendor => role == 'vendor';
  bool get isAdmin  => role == 'admin' || role == 'moderator';
}
