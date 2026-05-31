import 'package:json_annotation/json_annotation.dart';
part 'product_model.g.dart';

enum ProductType  { buy_now, negotiable, auction }
enum ProductCondition { new_, used_excellent, used_good, used_fair, refurbished }

@JsonSerializable()
class ProductModel {
  final String              id;
  final String              vendorId;
  final String              categoryId;
  final String              title;
  final String              slug;
  final String?             description;
  final String?             brand;
  final String?             sku;
  final ProductCondition    condition;
  final ProductType         productType;
  final int                 priceCoins;
  final bool                isNegotiable;
  final bool                isAuction;
  final DateTime?           auctionStart;
  final DateTime?           auctionEnd;
  final int?                reservePrice;
  final int?                currentBid;
  final int                 bidCount;
  final int                 quantity;
  final int                 soldCount;
  final List<String>        images;
  final String?             videoUrl;
  final List<String>        tags;
  final String?             warrantyInfo;
  final String?             vehicleMake;
  final String?             vehicleModel;
  final int?                vehicleYearFrom;
  final int?                vehicleYearTo;
  final bool                isActive;
  final bool                isApproved;
  final bool                isFeatured;
  final int                 viewCount;
  final int                 wishlistCount;
  final double              avgRating;
  final int                 reviewCount;
  final String?             shippingFrom;
  final bool                shipsWorldwide;
  final DateTime            createdAt;
  final DateTime            updatedAt;
  // Joined fields
  final String?             shopName;
  final bool?               isVerified;

  const ProductModel({
    required this.id,
    required this.vendorId,
    required this.categoryId,
    required this.title,
    required this.slug,
    this.description,
    this.brand,
    this.sku,
    required this.condition,
    required this.productType,
    required this.priceCoins,
    this.isNegotiable  = false,
    this.isAuction     = false,
    this.auctionStart,
    this.auctionEnd,
    this.reservePrice,
    this.currentBid,
    this.bidCount      = 0,
    this.quantity      = 1,
    this.soldCount     = 0,
    this.images        = const [],
    this.videoUrl,
    this.tags          = const [],
    this.warrantyInfo,
    this.vehicleMake,
    this.vehicleModel,
    this.vehicleYearFrom,
    this.vehicleYearTo,
    this.isActive      = true,
    this.isApproved    = false,
    this.isFeatured    = false,
    this.viewCount     = 0,
    this.wishlistCount = 0,
    this.avgRating     = 0.0,
    this.reviewCount   = 0,
    this.shippingFrom,
    this.shipsWorldwide = false,
    required this.createdAt,
    required this.updatedAt,
    this.shopName,
    this.isVerified,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);
  Map<String, dynamic> toJson() => _$ProductModelToJson(this);

  bool get isAuctionActive =>
    isAuction && auctionEnd != null && auctionEnd!.isAfter(DateTime.now());

  Duration? get auctionTimeLeft =>
    auctionEnd?.difference(DateTime.now());

  String get vehicleCompatibility {
    final parts = [vehicleMake, vehicleModel,
      if (vehicleYearFrom != null && vehicleYearTo != null) '$vehicleYearFrom–$vehicleYearTo'];
    return parts.whereType<String>().join(' ');
  }
}
