import 'package:json_annotation/json_annotation.dart';
part 'user_model.g.dart';

enum UserRole { buyer, vendor, admin, moderator }

@JsonSerializable()
class UserModel {
  final String    id;
  final UserRole  role;
  final String?   username;
  final String?   fullName;
  final String?   avatarUrl;
  final String?   phone;
  final String?   bio;
  final String    kycStatus;
  final bool      isActive;
  final bool      isSuspended;
  final DateTime  createdAt;

  const UserModel({
    required this.id,
    required this.role,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.phone,
    this.bio,
    this.kycStatus   = 'pending',
    this.isActive    = true,
    this.isSuspended = false,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  String get displayName => fullName ?? username ?? 'User';
  bool get isVendor  => role == UserRole.vendor;
  bool get isAdmin   => role == UserRole.admin || role == UserRole.moderator;
}
