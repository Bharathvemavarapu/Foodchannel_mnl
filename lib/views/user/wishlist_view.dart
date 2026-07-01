import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/product_card.dart';

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
                  return ProductCard(
                    product: wishlistProducts[index],
                    isWishlistPage: true,
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
