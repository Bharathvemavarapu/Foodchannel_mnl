import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../models/category.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_card.dart';
import 'product_detail_view.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final _searchController = TextEditingController();
  String _query = '';
  String _selectedCategoryId = 'all';
  double _maxPrice = 10000;
  String _sortBy = 'name'; // 'name', 'priceLow', 'priceHigh', 'newest'
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await DatabaseService.getCategories();
      setState(() {
        _categories = cats;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: const Text('Search Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search frying pans, chef tools, cookware...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white54),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white54),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.04),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _query = val;
                    });
                  },
                ),
                const SizedBox(height: 12),

                // Filters Row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterBadge(
                        label: 'Category: ${_getCategoryName(_selectedCategoryId)}',
                        icon: Icons.category_outlined,
                        onTap: _showCategoryFilter,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterBadge(
                        label: 'Sort: ${_getSortLabel(_sortBy)}',
                        icon: Icons.sort_rounded,
                        onTap: _showSortFilter,
                      ),
                      const SizedBox(width: 8),
                      _buildFilterBadge(
                        label: 'Max Price: ₹${_maxPrice.toInt()}',
                        icon: Icons.currency_rupee_rounded,
                        onTap: _showPriceFilter,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Search Results Grid
          Expanded(
            child: StreamBuilder<List<ProductModel>>(
              stream: DatabaseService.searchProductsStream(_query),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)),
                    ),
                  );
                }
                final allProducts = snapshot.data ?? [];

                // Filter in memory based on current options
                var filtered = allProducts.where((p) {
                  final matchesCategory = _selectedCategoryId == 'all' || p.categoryId == _selectedCategoryId;
                  final hasDiscount = p.discountPrice > 0 && p.discountPrice < p.price;
                  final price = hasDiscount ? p.discountPrice : p.price;
                  final matchesPrice = price <= _maxPrice;
                  return matchesCategory && matchesPrice;
                }).toList();

                // Sort in memory
                if (_sortBy == 'name') {
                  filtered.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                } else if (_sortBy == 'priceLow') {
                  filtered.sort((a, b) {
                    final priceA = a.discountPrice > 0 && a.discountPrice < a.price ? a.discountPrice : a.price;
                    final priceB = b.discountPrice > 0 && b.discountPrice < b.price ? b.discountPrice : b.price;
                    return priceA.compareTo(priceB);
                  });
                } else if (_sortBy == 'priceHigh') {
                  filtered.sort((a, b) {
                    final priceA = a.discountPrice > 0 && a.discountPrice < a.price ? a.discountPrice : a.price;
                    final priceB = b.discountPrice > 0 && b.discountPrice < b.price ? b.discountPrice : b.price;
                    return priceB.compareTo(priceA);
                  });
                } else if (_sortBy == 'newest') {
                  filtered.sort((a, b) => b.createdDate.compareTo(a.createdDate));
                }

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No products found matching filters.',
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: width > 1200 ? 4 : width > 800 ? 3 : 2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final prod = filtered[index];
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
                                    children: [
                                      Text(
                                        '₹${hasDiscount ? prod.discountPrice : prod.price}',
                                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                      if (hasDiscount) ...[
                                        const SizedBox(width: 6),
                                        Text(
                                          '₹${prod.price}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.white30,
                                            decoration: TextDecoration.lineThrough,
                                          ),
                                        ),
                                      ],
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

  Widget _buildFilterBadge({required String label, required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFF8A00).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFF8A00).withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF8A00), size: 14),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }

  String _getCategoryName(String id) {
    if (id == 'all') return 'All';
    final found = _categories.firstWhere(
      (c) => c.id == id,
      orElse: () => CategoryModel(id: '', name: '', imageUrl: '', createdDate: DateTime.now()),
    );
    return found.name.isNotEmpty ? found.name : 'All';
  }

  String _getSortLabel(String val) {
    switch (val) {
      case 'name':
        return 'Name';
      case 'priceLow':
        return 'Price: Low to High';
      case 'priceHigh':
        return 'Price: High to Low';
      case 'newest':
        return 'Newest';
      default:
        return 'Name';
    }
  }

  void _showCategoryFilter() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF0E0724),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Filter by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const Divider(color: Colors.white10, height: 24),
              ListTile(
                title: const Text('All Categories', style: TextStyle(color: Colors.white)),
                trailing: _selectedCategoryId == 'all' ? const Icon(Icons.check, color: Color(0xFFFF8A00)) : null,
                onTap: () {
                  setState(() => _selectedCategoryId = 'all');
                  Navigator.pop(context);
                },
              ),
              ..._categories.map((c) => ListTile(
                    title: Text(c.name, style: const TextStyle(color: Colors.white)),
                    trailing: _selectedCategoryId == c.id ? const Icon(Icons.check, color: Color(0xFFFF8A00)) : null,
                    onTap: () {
                      setState(() => _selectedCategoryId = c.id);
                      Navigator.pop(context);
                    },
                  )),
            ],
          ),
        );
      },
    );
  }

  void _showSortFilter() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF0E0724),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Sort Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const Divider(color: Colors.white10, height: 24),
              _buildSortOption('name', 'Name'),
              _buildSortOption('priceLow', 'Price: Low to High'),
              _buildSortOption('priceHigh', 'Price: High to Low'),
              _buildSortOption('newest', 'Newest Arrivals'),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String code, String label) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      trailing: _sortBy == code ? const Icon(Icons.check, color: Color(0xFFFF8A00)) : null,
      onTap: () {
        setState(() => _sortBy = code);
        Navigator.pop(context);
      },
    );
  }

  void _showPriceFilter() {
    showModalBottomSheet(
      backgroundColor: const Color(0xFF0E0724),
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        double tempPrice = _maxPrice;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Price Limit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                      Text('Max: ₹${tempPrice.toInt()}', style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  Slider(
                    value: tempPrice,
                    min: 100,
                    max: 10000,
                    divisions: 99,
                    activeColor: const Color(0xFFFF8A00),
                    inactiveColor: Colors.white12,
                    onChanged: (val) {
                      setModalState(() {
                        tempPrice = val;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _maxPrice = tempPrice;
                      });
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('APPLY LIMIT', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
