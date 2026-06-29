import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/glass_card.dart';
import 'product_detail_view.dart';

class WishlistView extends StatelessWidget {
  const WishlistView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final width = MediaQuery.of(context).size.width;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF070412),
        body: Center(
          child: Text(
            'Please log in to view your wishlist.',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: const Text('My Wishlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
      ),
      body: StreamBuilder<List<String>>(
        stream: DatabaseService.getUserWishlistStream(user.uid),
        builder: (context, wishlistSnapshot) {
          if (wishlistSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)),
              ),
            );
          }
          final wishlistIds = wishlistSnapshot.data ?? [];
          if (wishlistIds.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.favorite_border_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Your wishlist is empty',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Tap the heart icon on any product to save it here.',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Fetch products catalog using searchProductsStream with empty query (returns all products)
          return StreamBuilder<List<ProductModel>>(
            stream: DatabaseService.searchProductsStream(''),
            builder: (context, productsSnapshot) {
              if (productsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)),
                  ),
                );
              }
              final allProducts = productsSnapshot.data ?? [];
              final wishlistProducts = allProducts.where((p) => wishlistIds.contains(p.id)).toList();

              if (wishlistProducts.isEmpty) {
                return const Center(
                  child: Text(
                    'No matching products found in catalog.',
                    style: TextStyle(color: Colors.white38),
                  ),
                );
              }

              return GridView.builder(
                padding: const EdgeInsets.all(24),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: width > 1200
                      ? 4
                      : width > 800
                          ? 3
                          : 2,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: 0.72,
                ),
                itemCount: wishlistProducts.length,
                itemBuilder: (context, index) {
                  final prod = wishlistProducts[index];
                  final hasDiscount = prod.discountPrice > 0 && prod.discountPrice < prod.price;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailView(product: prod),
                        ),
                      );
                    },
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Image.network(
                                  prod.imageUrls.isNotEmpty ? prod.imageUrls.first : '',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.white30),
                                  ),
                                ),
                                // Remove button
                                Positioned(
                                  top: 10,
                                  right: 10,
                                  child: IconButton(
                                    style: IconButton.styleFrom(
                                      backgroundColor: Colors.black54,
                                      padding: const EdgeInsets.all(6),
                                    ),
                                    icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                                    onPressed: () => DatabaseService.toggleWishlist(user.uid, prod.id),
                                  ),
                                ),
                                if (hasDiscount)
                                  Positioned(
                                    top: 10,
                                    left: 10,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFDA1B60),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'SALE',
                                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  prod.brand.toUpperCase(),
                                  style: TextStyle(
                                    color: const Color(0xFFFF8A00).withValues(alpha: 0.8),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  prod.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '₹${hasDiscount ? prod.discountPrice : prod.price}',
                                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    IconButton(
                                      constraints: const BoxConstraints(),
                                      padding: EdgeInsets.zero,
                                      icon: const Icon(
                                        Icons.add_shopping_cart_rounded,
                                        color: Color(0xFFFF8A00),
                                        size: 20,
                                      ),
                                      onPressed: () {
                                        CartService.instance.addToCart(prod);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('${prod.name} added to cart!'),
                                            backgroundColor: Colors.green,
                                            duration: const Duration(seconds: 1),
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
