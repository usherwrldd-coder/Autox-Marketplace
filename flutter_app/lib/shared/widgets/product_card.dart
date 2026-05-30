import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../models/product_model.dart';
import 'auction_timer.dart';
import 'coin_badge.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  const ProductCard({super.key, required this.product});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _hovered = false;
  bool _wishlisted = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:        AppTheme.bgCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppTheme.borderHover : AppTheme.borderColor,
          ),
          boxShadow: _hovered ? [
            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8)),
            BoxShadow(color: AppTheme.goldPrimary.withOpacity(0.08), blurRadius: 30),
          ] : [],
        ),
        child: InkWell(
          onTap:        () => context.push('/product/${p.slug}'),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  children: [
                    SizedBox(
                      height: 160, width: double.infinity,
                      child: p.images.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl:  p.images.first,
                              fit:       BoxFit.cover,
                              errorWidget: (_, __, ___) => _placeholderImage(),
                            )
                          : _placeholderImage(),
                    ),
                    // Badges
                    Positioned(
                      top: 8, left: 8,
                      child: _typeBadge(p.productType),
                    ),
                    if (p.isFeatured)
                      Positioned(
                        top: 8, right: 40,
                        child: _badge('Featured', AppTheme.goldPrimary),
                      ),
                    // Wishlist
                    Positioned(
                      top: 4, right: 4,
                      child: IconButton(
                        icon: Icon(
                          _wishlisted ? Icons.favorite : Icons.favorite_border,
                          color: _wishlisted ? AppTheme.colorRed : Colors.white,
                          size: 18,
                        ),
                        onPressed: () => setState(() => _wishlisted = !_wishlisted),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withOpacity(0.4),
                          padding:         EdgeInsets.zero,
                          minimumSize:     const Size(32, 32),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p.brand ?? ""}  •  ${p.condition.name.toUpperCase()}',
                      style: const TextStyle(fontSize: 10, color: AppTheme.goldPrimary, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(p.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), maxLines: 2, overflow: TextOverflow.ellipsis),
                    if (p.vehicleCompatibility.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('🚗 ${p.vehicleCompatibility}', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                    const SizedBox(height: 8),
                    // Rating
                    Row(children: [
                      ...List.generate(5, (i) => Icon(
                        i < p.avgRating.floor() ? Icons.star : Icons.star_border,
                        size: 12, color: AppTheme.goldLight,
                      )),
                      const SizedBox(width: 4),
                      Text('${p.avgRating} (${p.reviewCount})', style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
                    ]),
                    if (p.isAuctionActive) ...[
                      const SizedBox(height: 6),
                      Row(children: [
                        AuctionTimer(endTime: p.auctionEnd!),
                        const SizedBox(width: 8),
                        Text('${p.bidCount} bids', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
                      ]),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: CoinBadge(amount: p.currentBid ?? p.priceCoins, fontSize: 15, showUsd: true)),
                        _actionButton(p),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Divider(height: 1),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Text('🏪 ', style: TextStyle(fontSize: 11)),
                      Expanded(child: Text(p.shopName ?? 'Vendor', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted), overflow: TextOverflow.ellipsis)),
                      const Text('✓ Escrow', style: TextStyle(fontSize: 10, color: AppTheme.colorGreen)),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderImage() => Container(
    color: AppTheme.bgCard,
    child: const Center(child: Text('⚙️', style: TextStyle(fontSize: 48))),
  );

  Widget _typeBadge(ProductType type) {
    switch (type) {
      case ProductType.auction:    return _badge('🔨 Auction',   AppTheme.colorRed);
      case ProductType.negotiable: return _badge('💬 Offer',     AppTheme.colorBlue);
      default:                     return const SizedBox.shrink();
    }
  }

  Widget _badge(String label, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withOpacity(0.4)),
    ),
    child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
  );

  Widget _actionButton(ProductModel p) {
    String label;
    switch (p.productType) {
      case ProductType.auction:    label = 'Bid'; break;
      case ProductType.negotiable: label = 'Offer'; break;
      default:                     label = 'Buy';
    }
    return ElevatedButton(
      onPressed: () => context.push('/product/${p.slug}'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: Text(label),
    );
  }
}
