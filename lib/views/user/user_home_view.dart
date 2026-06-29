import 'dart:async';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../models/app_settings.dart';
import '../../models/product.dart';
import '../../models/banner_hero.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import '../../widgets/glass_card.dart';
import 'product_detail_view.dart';
import 'search_view.dart';

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  AppSettingsModel _settings = AppSettingsModel.empty();
  StoreAddressModel _address = StoreAddressModel.empty();
  bool _isMetaLoading = true;

  int _heroPageIndex = 0;
  Timer? _heroTimer;
  final PageController _heroPageController = PageController();
  int _heroCount = 0;

  @override
  void initState() {
    super.initState();
    _loadStoreMeta();
  }

  @override
  void dispose() {
    _heroTimer?.cancel();
    _heroPageController.dispose();
    super.dispose();
  }

  Future<void> _loadStoreMeta() async {
    setState(() => _isMetaLoading = true);
    try {
      // Prepopulate check first
      await DatabaseService.checkAndPrepopulateDatabase();
      final results = await Future.wait([
        DatabaseService.getAppSettings(),
        DatabaseService.getStoreAddress(),
      ]);

      setState(() {
        _settings = results[0] as AppSettingsModel;
        _address = results[1] as StoreAddressModel;
        _isMetaLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isMetaLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load store profile: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _startHeroTimer(int count) {
    if (count <= 1 || _heroTimer != null) return;
    _heroCount = count;
    _heroTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_heroPageController.hasClients) {
        final nextPage = (_heroPageIndex + 1) % _heroCount;
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
    mapboxgl.accessToken = 'pk.eyJ1IjoicGF2YW5rdW1hcnN3YW15IiwiYSI6ImNtNnc1c3ZpdTBkdGgyanM5b25rN2ZqcncifQ.Ls1e2W6rx3apoBsStWa5Ow';
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

  @override
  Widget build(BuildContext context) {
    if (_isMetaLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070412),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)))),
      );
    }

    final width = MediaQuery.of(context).size.width;

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
            icon: const Icon(Icons.search_rounded, color: Colors.white70),
            tooltip: 'Search Products',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchView()),
              );
            },
          ),
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
            // 1. Hero Image Slider (StreamBuilder)
            StreamBuilder<List<HeroImageModel>>(
              stream: DatabaseService.getHeroImagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const SizedBox.shrink();
                }
                final heroes = snapshot.data!;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _startHeroTimer(heroes.length);
                });

                return SizedBox(
                  height: width > 800 ? 360 : 200,
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      PageView.builder(
                        controller: _heroPageController,
                        itemCount: heroes.length,
                        onPageChanged: (idx) => setState(() => _heroPageIndex = idx),
                        itemBuilder: (context, index) {
                          return Image.network(
                            heroes[index].imageUrl,
                            fit: BoxFit.cover,
                            width: double.infinity,
                          );
                        },
                      ),
                      Positioned(
                        bottom: 16,
                        child: Row(
                          children: List.generate(heroes.length, (index) {
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
                );
              },
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

                  // 2. Promotional Banners (StreamBuilder)
                  StreamBuilder<List<BannerModel>>(
                    stream: DatabaseService.getBannersStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final banners = snapshot.data!.where((b) => b.isEnabled).toList();
                      if (banners.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hot Deals', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 140,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: banners.length,
                              itemBuilder: (context, index) {
                                return Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  width: 280,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(banners[index].imageUrl, fit: BoxFit.cover),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 36),
                        ],
                      );
                    },
                  ),

                  // 3. Featured Products Grid (StreamBuilder)
                  const Text('Featured Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  StreamBuilder<List<ProductModel>>(
                    stream: DatabaseService.getFeaturedProductsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
                        ));
                      }
                      final featured = snapshot.data ?? [];
                      if (featured.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No featured products right now.', style: TextStyle(color: Colors.white38, fontSize: 14)),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: width > 1200 ? 4 : width > 800 ? 3 : 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: featured.length,
                        itemBuilder: (context, index) => _ProductCard(product: featured[index]),
                      );
                    },
                  ),
                  const SizedBox(height: 36),

                  // 4. Trending Products Grid (StreamBuilder)
                  const Text('Trending Now', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 16),
                  StreamBuilder<List<ProductModel>>(
                    stream: DatabaseService.getTrendingProductsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24.0),
                          child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
                        ));
                      }
                      final trending = snapshot.data ?? [];
                      if (trending.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No trending products right now.', style: TextStyle(color: Colors.white38, fontSize: 14)),
                        );
                      }

                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: width > 1200 ? 4 : width > 800 ? 3 : 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: trending.length,
                        itemBuilder: (context, index) => _ProductCard(product: trending[index]),
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

class _ProductCard extends StatelessWidget {
  final ProductModel product;

  const _ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPrice > 0 && product.discountPrice < product.price;

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
            // Product image
            Expanded(
              child: Stack(
                children: [
                  Image.network(
                    product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40)),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
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
                            isWishlisted ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isWishlisted ? Colors.redAccent : Colors.white70,
                            size: 18,
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
                    product.brand,
                    style: TextStyle(color: const Color(0xFFFF8A00).withValues(alpha: 0.8), fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Prices Row
                  Row(
                    children: [
                      Text(
                        '₹${hasDiscount ? product.discountPrice : product.price}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (hasDiscount) ...[
                        const SizedBox(width: 8),
                        Text(
                          '₹${product.price}',
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
                        product.isAvailable ? 'In Stock' : 'Out of Stock',
                        style: TextStyle(
                          color: product.isAvailable ? Colors.green : Colors.redAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'SKU: ${product.sku}',
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
  }
}
