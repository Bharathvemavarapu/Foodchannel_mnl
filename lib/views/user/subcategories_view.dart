import 'package:flutter/material.dart';
import '../../services/database_service.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/persistent_cart_bar.dart';
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
      bottomNavigationBar: const PersistentCartBar(),
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
                    return ProductCard(product: products[index]);
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
