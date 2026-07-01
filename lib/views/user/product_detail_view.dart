import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/review.dart';
import '../../services/cart_service.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/persistent_cart_bar.dart';
import 'package:intl/intl.dart';

class ProductDetailView extends StatefulWidget {
  final ProductModel product;

  const ProductDetailView({super.key, required this.product});

  @override
  State<ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends State<ProductDetailView> {
  int _activeImageIndex = 0;
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final prod = widget.product;
    final hasDiscount = prod.discountPrice > 0 && prod.discountPrice < prod.price;
    final displayPrice = hasDiscount ? prod.discountPrice : prod.price;

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      bottomNavigationBar: const PersistentCartBar(),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: const Text('Product Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Product Main Image
              if (prod.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: AspectRatio(
                    aspectRatio: 1.33,
                    child: Image.network(
                      prod.imageUrls[_activeImageIndex],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image, size: 60, color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // Thumbnail Selector
              if (prod.imageUrls.length > 1)
                SizedBox(
                  height: 70,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: prod.imageUrls.length,
                    itemBuilder: (context, index) {
                      final isSelected = _activeImageIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _activeImageIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 12),
                          width: 70,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF8A00) : Colors.white12,
                              width: 2.0,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(prod.imageUrls[index], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),

              // Name, Brand, SKU Card
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prod.brand.toUpperCase(),
                          style: const TextStyle(
                            color: Color(0xFFFF8A00),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            letterSpacing: 1.0,
                          ),
                        ),
                        Text(
                          'SKU: ${prod.sku}',
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prod.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: Colors.white),
                    ),
                    const SizedBox(height: 16),

                    // Pricing
                    Row(
                      children: [
                        Text(
                          '₹$displayPrice',
                          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 12),
                          Text(
                            '₹${prod.price}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white30,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDA1B60).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Save ₹${(prod.price - prod.discountPrice).toStringAsFixed(0)}',
                              style: const TextStyle(color: Color(0xFFDA1B60), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Description',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prod.description,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.7), height: 1.5, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Actions Panel
              GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          prod.isAvailable ? 'In Stock (${prod.stock} items)' : 'Out of Stock',
                          style: TextStyle(
                            color: prod.isAvailable ? Colors.green : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        if (prod.isAvailable)
                          Row(
                            children: [
                              IconButton(
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _quantity.toString(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _quantity < prod.stock
                                    ? () => setState(() => _quantity++)
                                    : null,
                                icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: prod.isAvailable
                          ? () {
                              CartService.instance.addToCart(prod, quantity: _quantity);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${prod.name} added to cart!'),
                                  backgroundColor: Colors.green,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.shopping_cart_outlined),
                      label: const Text(
                        'ADD TO CART',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        disabledBackgroundColor: Colors.white10,
                        disabledForegroundColor: Colors.white24,
                        minimumSize: const Size.fromHeight(56),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(color: Colors.white10),
                    const SizedBox(height: 16),

                    // Reviews Header StreamBuilder
                    StreamBuilder<List<ProductReviewModel>>(
                      stream: DatabaseService.getProductReviewsStream(prod.id),
                      builder: (context, snapshot) {
                        final reviews = snapshot.data ?? [];
                        final avgRating = reviews.isEmpty
                            ? 5.0
                            : reviews.fold(0.0, (sum, r) => sum + r.rating) / reviews.length;

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Customer Reviews',
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.star_rounded, color: Colors.amber[700], size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${avgRating.toStringAsFixed(1)} (${reviews.length} reviews)',
                                          style: const TextStyle(color: Colors.white70, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () => _showWriteReviewBottomSheet(context, prod.id),
                                  icon: const Icon(Icons.rate_review_rounded, size: 16, color: Color(0xFFFF8A00)),
                                  label: const Text(
                                    'Write Review',
                                    style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            if (reviews.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 24.0),
                                child: Center(
                                  child: Text(
                                    'No reviews for this product yet. Be the first to review!',
                                    style: TextStyle(color: Colors.white30, fontSize: 13),
                                  ),
                                ),
                              )
                            else
                              Column(
                                children: reviews.map((review) {
                                  final reviewDate = DateFormat('dd MMM yyyy').format(review.createdDate);
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: GlassCard(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                review.userName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70, fontSize: 13),
                                              ),
                                              Text(
                                                reviewDate,
                                                style: const TextStyle(color: Colors.white38, fontSize: 11),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: List.generate(5, (starIndex) {
                                              return Icon(
                                                Icons.star_rounded,
                                                color: starIndex < review.rating ? Colors.amber[700] : Colors.white12,
                                                size: 14,
                                              );
                                            }),
                                          ),
                                          if (review.comment.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              review.comment,
                                              style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.3),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showWriteReviewBottomSheet(BuildContext context, String productId) {
    final user = AuthService.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to submit a review.'), backgroundColor: Colors.redAccent),
      );
      return;
    }

    double tempRating = 5.0;
    final commentController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      backgroundColor: const Color(0xFF0E0724),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Submit Review & Rating',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final starVal = index + 1.0;
                          return IconButton(
                            icon: Icon(
                              starVal <= tempRating ? Icons.star_rounded : Icons.star_border_rounded,
                              color: starVal <= tempRating ? Colors.amber[700] : Colors.white24,
                              size: 36,
                            ),
                            onPressed: () {
                              setModalState(() {
                                tempRating = starVal;
                              });
                            },
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.center,
                        child: Text(
                          '${tempRating.toInt()} / 5 Stars',
                          style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: commentController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Review Comments',
                          labelStyle: TextStyle(color: Colors.white54),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () async {
                          final id = 'rev_${DateTime.now().millisecondsSinceEpoch}';
                          final profile = await AuthService.getUserProfile(user.uid);
                          final userName = profile?.name ?? user.displayName ?? 'Customer';

                          final newReview = ProductReviewModel(
                            id: id,
                            productId: productId,
                            userId: user.uid,
                            userName: userName,
                            rating: tempRating,
                            comment: commentController.text.trim(),
                            createdDate: DateTime.now(),
                          );

                          try {
                            await DatabaseService.submitProductReview(productId, newReview);
                            if (mounted) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Review submitted successfully!'), backgroundColor: Colors.green),
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to submit review: $e'), backgroundColor: Colors.redAccent),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF8A00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('SUBMIT REVIEW', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
