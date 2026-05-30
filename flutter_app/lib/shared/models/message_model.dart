import 'package:json_annotation/json_annotation.dart';
part 'message_model.g.dart';

@JsonSerializable()
class ConversationModel {
  final String    id;
  final String    buyerId;
  final String    vendorId;
  final String?   productId;
  final String?   lastMessage;
  final DateTime? lastMessageAt;
  final int       buyerUnread;
  final int       vendorUnread;
  final DateTime  createdAt;
  // Joined
  final String?   otherPartyName;
  final String?   otherPartyAvatar;
  final String?   productTitle;

  const ConversationModel({
    required this.id,
    required this.buyerId,
    required this.vendorId,
    this.productId,
    this.lastMessage,
    this.lastMessageAt,
    this.buyerUnread  = 0,
    this.vendorUnread = 0,
    required this.createdAt,
    this.otherPartyName,
    this.otherPartyAvatar,
    this.productTitle,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) => _$ConversationModelFromJson(json);
  Map<String, dynamic> toJson() => _$ConversationModelToJson(this);
}

@JsonSerializable()
class MessageModel {
  final String    id;
  final String    conversationId;
  final String    senderId;
  final String?   body;
  final String?   imageUrl;
  final String?   offerId;
  final bool      isRead;
  final DateTime? readAt;
  final DateTime  createdAt;

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.body,
    this.imageUrl,
    this.offerId,
    this.isRead   = false,
    this.readAt,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) => _$MessageModelFromJson(json);
  Map<String, dynamic> toJson() => _$MessageModelToJson(this);
}
