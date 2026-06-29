import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../widgets/glass_card.dart';
import '../../services/auth_service.dart';
import 'product_detail_view.dart';
import 'search_view.dart';

class SubcategoriesView extends StatefulWidget {
  final CategoryModel category;

  const SubcategoriesView({super.key, required this.category});

  @override
  State<SubcategoriesView> createState() => _SubcategoriesViewState();
}

class _SubcategoriesViewState extends State<SubcategoriesView> {
  String _selectedSubCategoryId = 'all';

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: Text(
          widget.category.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white70),
            tooltip: 'Search Products',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchView()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Subcategories Horizontal List
          StreamBuilder<List<SubCategoryModel>>(
            stream: DatabaseService.getSubCategoriesStream(widget.category.id),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final subcats = snapshot.data!;
              return Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                color: const Color(0xFF0D0622).withValues(alpha: 0.5),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subcats.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final name = isAll ? 'All' : subcats[index - 1].name;
                    final id = isAll ? 'all' : subcats[index - 1].id;
                    final isSelected = _selectedSubCategoryId == id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(name),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedSubCategoryId = id;
                            });
                          }
                        },
                        selectedColor: const Color(0xFFFF8A00),
                        backgroundColor: Colors.white.withValues(alpha: 0.04),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.white60,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // Products List Grid
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: _selectedSubCategoryId == 'all'
                  ? DatabaseService.getProductsByCategoryStream(widget.category.id)
                  : DatabaseService.getProductsBySubCategoryStream(_selectedSubCategoryId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)),
                    ),
                  );
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found.',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
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
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final prod = products[index];
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
                            // Product Image
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
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: StreamBuilder<List<String>>(
                                      stream: DatabaseService.getUserWishlistStream(AuthService.currentUser?.uid ?? ''),
                                      builder: (context, snapshot) {
                                        final wishlist = snapshot.data ?? [];
                                        final isWishlisted = wishlist.contains(prod.id);
                                        return IconButton(
                                          style: IconButton.styleFrom(
                                            backgroundColor: Colors.black54,
                                            padding: const EdgeInsets.all(6),
                                          ),
                                          icon: Icon(
                                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                            color: isWishlisted ? Colors.redAccent : Colors.white70,
                                            size: 18,
                                          ),
                                          onPressed: () {
                                            final uid = AuthService.currentUser?.uid;
                                            if (uid != null) {
                                              DatabaseService.toggleWishlist(uid, prod.id);
                                            }
                                          },
                                        );
                                      },
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

                            // Details
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    prod.brand,
                                    style: TextStyle(
                                      color: const Color(0xFFFF8A00).withValues(alpha: 0.8),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    prod.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 10),

                                  // Prices Row
                                  Row(
                                    children: [
                                      Text(
                                        '₹${hasDiscount ? prod.discountPrice : prod.price}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          '₹${prod.price}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.white30,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        prod.isAvailable ? 'In Stock' : 'Out of Stock',
                                        style: TextStyle(
                                          color: prod.isAvailable ? Colors.green : Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        'SKU: ${prod.sku}',
                                        style: const TextStyle(color: Colors.white30, fontSize: 10),
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
            ),
          ),
        ],
      ),
    );
  }
}
