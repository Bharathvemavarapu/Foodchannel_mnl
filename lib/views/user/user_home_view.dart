import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../models/app_settings.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../models/banner_hero.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import '../../../widgets/glass_card.dart';

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  AppSettingsModel _settings = AppSettingsModel.empty();
  StoreAddressModel _address = StoreAddressModel.empty();
  List<CategoryModel> _categories = [];
  List<SubCategoryModel> _subCategories = [];
  List<ProductModel> _products = [];
  List<BannerModel> _banners = [];
  List<HeroImageModel> _heroImages = [];

  String _selectedCategoryId = 'all';
  bool _isLoading = true;
  int _heroPageIndex = 0;
  Timer? _heroTimer;
  final PageController _heroPageController = PageController();

  @override
  void initState() {
    super.initState();
    _loadStoreData();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreData() async {
    setState(() => _isLoading = true);
    try {
      await DatabaseService.checkAndPrepopulateDatabase();
      final results = await Future.wait([
        DatabaseService.getAppSettings(),
        DatabaseService.getStoreAddress(),
        DatabaseService.getCategories(),
        DatabaseService.getSubCategories(),
        DatabaseService.getProducts(),
        DatabaseService.getBanners(),
        DatabaseService.getHeroImages(),
      ]);

      setState(() {
        _settings = results[0] as AppSettingsModel;
        _address = results[1] as StoreAddressModel;
        _categories = results[2] as List<CategoryModel>;
        _subCategories = results[3] as List<SubCategoryModel>;
        _products = results[4] as List<ProductModel>;
        _banners = results[5] as List<BannerModel>;
        _heroImages = results[6] as List<HeroImageModel>;
        _isLoading = false;
      });

      _startHeroTimer();
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load storefront data: $e'), backgroundColor: Colors.redAccent),
      );
    }
  }

  void _startHeroTimer() {
    if (_heroImages.isEmpty) return;
    _heroTimer?.cancel();
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_heroPageController.hasClients) {
        final nextPage = (_heroPageIndex + 1) % _heroImages.length;
        _heroPageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  String _getMapboxViewType(double lat, double lng) {
    final viewType = 'user-mapbox-map-${lat.toStringAsFixed(5)}-${lng.toStringAsFixed(5)}';
    ui_web.platformViewRegistry.registerViewFactory(
      viewType,
      (int viewId) {
        final mapHtml = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <link href="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.css" rel="stylesheet">
  <script src="https://api.mapbox.com/mapbox-gl-js/v3.1.2/mapbox-gl.js"></script>
  <style>
    body { margin: 0; padding: 0; }
    #map { position: absolute; top: 0; bottom: 0; width: 100%; height: 100%; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    mapboxgl.accessToken = 'YOUR_MAPBOX_TOKEN';
    const map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/streets-v12',
      center: [$lng, $lat],
      zoom: 14
    });
    new mapboxgl.Marker({ color: '#FF8A00' }).setLngLat([$lng, $lat]).addTo(map);
  </script>
</body>
</html>
''';
        final encodedHtml = 'data:text/html;charset=utf-8,${Uri.encodeComponent(mapHtml)}';
        final element = web.HTMLIFrameElement()
          ..src = encodedHtml
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';
        return element;
      },
    );
    return viewType;
  }

  void _showProductDetails(ProductModel prod) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => _ProductDetailsDialog(product: prod),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070412),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)))),
      );
    }

    final width = MediaQuery.of(context).size.width;
    final filteredProducts = _selectedCategoryId == 'all'
        ? _products
        : _products.where((p) => p.categoryId == _selectedCategoryId).toList();

    final activeBanners = _banners.where((b) => b.isEnabled).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: Row(
          children: [
            if (_settings.logoUrl.isNotEmpty) ...[
              ClipOval(
                child: Image.network(_settings.logoUrl, width: 36, height: 36, fit: BoxFit.cover),
              ),
              const SizedBox(width: 12),
            ],
            Text(
              _settings.name.isNotEmpty ? _settings.name : 'FoodChannel MNL',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
            tooltip: 'Logout',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Hero Image Slider
            if (_heroImages.isNotEmpty)
              Container(
                height: width > 800 ? 360 : 200,
                child: Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    PageView.builder(
                      controller: _heroPageController,
                      itemCount: _heroImages.length,
                      onPageChanged: (idx) => setState(() => _heroPageIndex = idx),
                      itemBuilder: (context, index) {
                        return Image.network(
                          _heroImages[index].imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        );
                      },
                    ),
                    Positioned(
                      bottom: 16,
                      child: Row(
                        children: List.generate(_heroImages.length, (index) {
                          final isSelected = _heroPageIndex == index;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isSelected ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFF8A00) : Colors.white54,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 28.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Store
                  if (_settings.description.isNotEmpty) ...[
                    const Text('About Store', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      _settings.description,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 28),
                  ],

                  // 2. Promotional Banners
                  if (activeBanners.isNotEmpty) ...[
                    const Text('Hot Deals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: activeBanners.length,
                        itemBuilder: (context, index) {
                          return Container(
                            margin: const EdgeInsets.only(right: 16),
                            width: 280,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(activeBanners[index].imageUrl, fit: BoxFit.cover),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],

                  // 3. Category Horizontal list
                  const Text('Shop Categories', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 48,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _categories.length + 1,
                      itemBuilder: (context, index) {
                        final isAll = index == 0;
                        final catName = isAll ? 'All Products' : _categories[index - 1].name;
                        final catId = isAll ? 'all' : _categories[index - 1].id;
                        final isSelected = _selectedCategoryId == catId;

                        return Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: ChoiceChip(
                            label: Text(catName),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedCategoryId = catId;
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
                  ),
                  const SizedBox(height: 28),

                  // 4. Products Grid
                  const Text('Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  filteredProducts.isEmpty
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40.0),
                            child: Text('No products available in this category.', style: TextStyle(color: Colors.white38)),
                          ),
                        )
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
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
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final prod = filteredProducts[index];
                            final hasDiscount = prod.discountPrice > 0 && prod.discountPrice < prod.price;

                            return GestureDetector(
                              onTap: () => _showProductDetails(prod),
                              child: GlassCard(
                                padding: EdgeInsets.zero,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product image
                                    Expanded(
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            prod.imageUrls.isNotEmpty ? prod.imageUrls.first : '',
                                            width: double.infinity,
                                            height: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40)),
                                          ),
                                          if (hasDiscount)
                                            Positioned(
                                              top: 10,
                                              left: 10,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                decoration: BoxDecoration(color: const Color(0xFFDA1B60), borderRadius: BorderRadius.circular(6)),
                                                child: const Text('SALE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                                            style: TextStyle(color: const Color(0xFFFF8A00).withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
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
                                                  style: const TextStyle(fontSize: 12, color: Colors.white30, decoration: TextDecoration.lineThrough),
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
                        ),
                  
                  const SizedBox(height: 48),
                  
                  // 5. Store Map Section
                  if (_address.latitude != 0 && _address.longitude != 0) ...[
                    const Text('Find Our Store', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 8),
                    Text(
                      _address.fullAddress,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: HtmlElementView(
                          key: ValueKey('user-map-${_address.latitude}-${_address.longitude}'),
                          viewType: _getMapboxViewType(_address.latitude, _address.longitude),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductDetailsDialog extends StatefulWidget {
  final ProductModel product;

  const _ProductDetailsDialog({required this.product});

  @override
  State<_ProductDetailsDialog> createState() => _ProductDetailsDialogState();
}

class _ProductDetailsDialogState extends State<_ProductDetailsDialog> {
  int _activeImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final prod = widget.product;
    final hasDiscount = prod.discountPrice > 0 && prod.discountPrice < prod.price;

    return Dialog(
      backgroundColor: const Color(0xFF150A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 580,
        padding: const EdgeInsets.all(28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      prod.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white60),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Main Image
              if (prod.imageUrls.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.network(
                      prod.imageUrls[_activeImageIndex],
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Thumbnail Selector
              if (prod.imageUrls.length > 1)
                SizedBox(
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: prod.imageUrls.length,
                    itemBuilder: (context, index) {
                      final isSelected = _activeImageIndex == index;
                      return GestureDetector(
                        onTap: () => setState(() => _activeImageIndex = index),
                        child: Container(
                          margin: const EdgeInsets.only(right: 10),
                          width: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF8A00) : Colors.white12,
                              width: 1.8,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.network(prod.imageUrls[index], fit: BoxFit.cover),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Brand: ${prod.brand}',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8A00)),
                  ),
                  Text(
                    'SKU: ${prod.sku}',
                    style: const TextStyle(color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Text(
                    'Price: ₹${hasDiscount ? prod.discountPrice : prod.price}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  if (hasDiscount) ...[
                    const SizedBox(width: 12),
                    Text(
                      '₹${prod.price}',
                      style: const TextStyle(fontSize: 14, color: Colors.white30, decoration: TextDecoration.lineThrough),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              const SizedBox(height: 8),
              Text(
                prod.description,
                style: const TextStyle(color: Colors.white70, height: 1.4, fontSize: 14),
              ),
              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    prod.isAvailable ? 'In Stock (${prod.stock} items)' : 'Out of Stock',
                    style: TextStyle(
                      color: prod.isAvailable ? Colors.green : Colors.redAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: prod.isAvailable ? () {} : null,
                    icon: const Icon(Icons.shopping_cart_outlined),
                    label: const Text('ADD TO CART'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
