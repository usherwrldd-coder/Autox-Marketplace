import 'package:json_annotation/json_annotation.dart';
part 'order_model.g.dart';

enum OrderStatus { pending, in_escrow, shipped, delivered, disputed, refunded, cancelled }

@JsonSerializable()
class OrderModel {
  final String       id;
  final String       orderNumber;
  final String       buyerId;
  final String       vendorId;
  final String       productId;
  final OrderStatus  status;
  final int          quantity;
  final int          unitPrice;
  final int          shippingCost;
  final int          platformFee;
  final int          totalCoins;
  final bool         escrowReleased;
  final DateTime?    escrowReleasedAt;
  final String?      trackingNumber;
  final String?      trackingCarrier;
  final DateTime?    shippedAt;
  final DateTime?    deliveredAt;
  final DateTime?    deliveryConfirmedAt;
  final String?      notes;
  final DateTime     createdAt;
  final DateTime     updatedAt;
  // Joined
  final String?      productTitle;
  final List<String>? productImages;
  final String?      shopName;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.buyerId,
    required this.vendorId,
    required this.productId,
    required this.status,
    required this.quantity,
    required this.unitPrice,
    required this.shippingCost,
    required this.platformFee,
    required this.totalCoins,
    this.escrowReleased      = false,
    this.escrowReleasedAt,
    this.trackingNumber,
    this.trackingCarrier,
    this.shippedAt,
    this.deliveredAt,
    this.deliveryConfirmedAt,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.productTitle,
    this.productImages,
    this.shopName,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => _$OrderModelFromJson(json);
  Map<String, dynamic> toJson() => _$OrderModelToJson(this);

  bool get canConfirmDelivery => status == OrderStatus.shipped;
  bool get canRequestRefund   => [OrderStatus.in_escrow, OrderStatus.shipped].contains(status);
  bool get isInEscrow         => status == OrderStatus.in_escrow;
}
