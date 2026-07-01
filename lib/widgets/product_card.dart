import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'glass_card.dart';
import 'add_to_cart_button.dart';
import '../views/user/product_detail_view.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final bool showWishlistButton;
  final bool isWishlistPage;

  const ProductCard({
    super.key,
    required this.product,
    this.showWishlistButton = true,
    this.isWishlistPage = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPrice > 0 && product.discountPrice < product.price;
    final displayPrice = hasDiscount ? product.discountPrice : product.price;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailView(product: product),
          ),
        );
      },
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image section
            Expanded(
              child: Stack(
                children: [
                  Image.network(
                    product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image, size: 40, color: Colors.white30),
                    ),
                  ),
                  // Wishlist overlay
                  if (showWishlistButton)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: StreamBuilder<List<String>>(
                        stream: DatabaseService.getUserWishlistStream(AuthService.currentUser?.uid ?? ''),
                        builder: (context, snapshot) {
                          final wishlist = snapshot.data ?? [];
                          final isWishlisted = wishlist.contains(product.id);
                          return IconButton(
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.black54,
                              padding: const EdgeInsets.all(6),
                            ),
                            icon: Icon(
                              isWishlistPage || isWishlisted
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isWishlistPage || isWishlisted ? Colors.redAccent : Colors.white70,
                              size: 16,
                            ),
                            onPressed: () {
                              final uid = AuthService.currentUser?.uid;
                              if (uid != null) {
                                DatabaseService.toggleWishlist(uid, product.id);
                              }
                            },
                          );
                        },
                      ),
                    ),
                  // Discount badge
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDA1B60),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'SALE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Details section
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.brand.toUpperCase(),
                    style: TextStyle(
                      color: const Color(0xFFFF8A00).withValues(alpha: 0.8),
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),

                  // Prices & ADD Button Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '₹$displayPrice',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            if (hasDiscount)
                              Text(
                                '₹${product.price}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Colors.white30,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                          ],
                        ),
                      ),
                      AddToCartButton(product: product),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
