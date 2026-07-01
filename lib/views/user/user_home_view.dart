import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;
import '../../models/app_settings.dart';
import '../../models/product.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../auth/login_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/add_to_cart_button.dart';
import 'order_tracking_view.dart';
import 'user_bottom_nav.dart';

class UserHomeView extends StatefulWidget {
  const UserHomeView({super.key});

  @override
  State<UserHomeView> createState() => _UserHomeViewState();
}

class _UserHomeViewState extends State<UserHomeView> {
  AppSettingsModel _settings = AppSettingsModel.empty();
  StoreAddressModel _address = StoreAddressModel.empty();
  bool _isMetaLoading = true;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _locationSearchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadStoreMeta();
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    _scrollController.dispose();
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          color: const Color(0xFF070412),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logo exactly like reference image
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: Color(0xFFFF8A00), size: 28),
                    const SizedBox(width: 6),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "FoodChannel",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          "GOOD FOOD. GREAT MOOD.",
                          style: TextStyle(
                            color: const Color(0xFFFF8A00).withValues(alpha: 0.8),
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Center Navigation Links
                LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = MediaQuery.of(context).size.width;
                    if (screenWidth < 850) return const SizedBox.shrink();

                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildHeaderLink("Home", onTap: _scrollToTop),
                        const SizedBox(width: 24),
                        _buildHeaderLink("Restaurants", onTap: _scrollToFeatured),
                        const SizedBox(width: 24),
                        _buildHeaderLink("Offers", onTap: _scrollToOffers),
                        const SizedBox(width: 24),
                        _buildHeaderLink("Track Order", onTap: _handleTrackOrder),
                        const SizedBox(width: 24),
                        _buildHeaderLink("About Us", onTap: _scrollToAbout),
                      ],
                    );
                  },
                ),

                // Login & Sign Up style buttons acting as Logout & Profile
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    OutlinedButton.icon(
                      onPressed: _handleLogout,
                      icon: const Icon(Icons.logout_rounded, color: Colors.white, size: 14),
                      label: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white24, width: 1.2),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        UserBottomNav.activeTabNotifier.value = 4; // Profile index
                      },
                      icon: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
                      label: const Text(
                        "Profile",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mockup-style Premium Hero Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF070412), Color(0xFF140A28)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth > 900;
                  
                  final heroTextContent = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Craving something delicious?",
                        style: TextStyle(
                          color: Color(0xFFFF8A00),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Good Food\nDelivered\nTo You",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "Order from your favorite restaurants and enjoy fast delivery at your doorstep.",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Location Search Bar
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(36),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: Color(0xFFFF8A00), size: 22),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: _locationSearchController,
                                style: const TextStyle(color: Colors.black87, fontSize: 14),
                                decoration: const InputDecoration(
                                  hintText: "Enter your delivery location",
                                  hintStyle: TextStyle(color: Colors.black38),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: const BoxDecoration(
                                border: Border(left: BorderSide(color: Colors.black12, width: 1)),
                              ),
                              child: const Row(
                                children: [
                                  Text("Work", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 13)),
                                  Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 18),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                final text = _locationSearchController.text.trim();
                                if (text.isNotEmpty) {
                                  setState(() {
                                    _searchQuery = text;
                                  });
                                  _scrollToFeatured();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please enter a location or food search query!'),
                                      backgroundColor: Color(0xFFFF8A00),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF8A00),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: const Text("Find Food", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Promo Badges
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildPromoBadge(
                              icon: Icons.local_offer_rounded,
                              title: "50% OFF",
                              subtitle: "On First Order",
                              color: const Color(0xFFFF8A00),
                            ),
                            const SizedBox(width: 12),
                            _buildPromoBadge(
                              icon: Icons.electric_moped_rounded,
                              title: "Fast Delivery",
                              subtitle: "In 30-45 mins",
                              color: const Color(0xFFFFB300),
                            ),
                            const SizedBox(width: 12),
                            _buildPromoBadge(
                              icon: Icons.verified_rounded,
                              title: "Best Offers",
                              subtitle: "On All Orders",
                              color: const Color(0xFFDA1B60),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );

                  if (isDesktop) {
                    return Row(
                      children: [
                        Expanded(flex: 11, child: heroTextContent),
                        const SizedBox(width: 48),
                        Expanded(
                          flex: 12,
                          child: AspectRatio(
                            aspectRatio: 1.25,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/hero_mockup.jpg',
                                      fit: BoxFit.cover,
                                      alignment: Alignment.center,
                                    ),
                                  ),
                                  // Subtle dark overlay gradient
                                  Positioned.fill(
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            const Color(0xFF070412).withValues(alpha: 0.6),
                                            Colors.transparent,
                                          ],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  // Mobile Layout
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      heroTextContent,
                      const SizedBox(height: 32),
                      AspectRatio(
                        aspectRatio: 1.4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Image.asset(
                            'assets/hero_mockup.jpg',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Overlapping Rounded Features Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 700;
                    if (isWide) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: _buildFeatureItem(
                              Icons.restaurant_menu_rounded,
                              "Top Restaurants",
                              "From your favorite places",
                              onTap: _scrollToFeatured,
                            ),
                          ),
                          _buildDivider(),
                          Expanded(
                            child: _buildFeatureItem(
                              Icons.electric_moped_rounded,
                              "Fast Delivery",
                              "Quick delivery to your doorstep",
                              onTap: () {
                                setState(() {
                                  _searchQuery = "KFC";
                                  _locationSearchController.text = "KFC";
                                });
                                _scrollToFeatured();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Filtering by Fast Delivery (KFC, Pizza Hut, Burger King)!'),
                                    backgroundColor: Color(0xFFFF8A00),
                                  ),
                                );
                              },
                            ),
                          ),
                          _buildDivider(),
                          Expanded(
                            child: _buildFeatureItem(
                              Icons.security_rounded,
                              "Safe & Secure",
                              "100% safe packaging and delivery",
                              onTap: _showSafeAndSecureDialog,
                            ),
                          ),
                          _buildDivider(),
                          Expanded(
                            child: _buildFeatureItem(
                              Icons.local_offer_rounded,
                              "Exciting Offers",
                              "Enjoy deals and exclusive offers",
                              onTap: _showPromoCodesDialog,
                            ),
                          ),
                        ],
                      );
                    }
                    return Column(
                      children: [
                        _buildFeatureItem(
                          Icons.restaurant_menu_rounded,
                          "Top Restaurants",
                          "From your favorite places",
                          onTap: _scrollToFeatured,
                        ),
                        const Divider(height: 24, color: Colors.black12),
                        _buildFeatureItem(
                          Icons.electric_moped_rounded,
                          "Fast Delivery",
                          "Quick delivery to your doorstep",
                          onTap: () {
                            setState(() {
                              _searchQuery = "KFC";
                              _locationSearchController.text = "KFC";
                            });
                            _scrollToFeatured();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Filtering by Fast Delivery (KFC, Pizza Hut, Burger King)!'),
                                backgroundColor: Color(0xFFFF8A00),
                              ),
                            );
                          },
                        ),
                        const Divider(height: 24, color: Colors.black12),
                        _buildFeatureItem(
                          Icons.security_rounded,
                          "Safe & Secure",
                          "100% safe packaging and delivery",
                          onTap: _showSafeAndSecureDialog,
                        ),
                        const Divider(height: 24, color: Colors.black12),
                        _buildFeatureItem(
                          Icons.local_offer_rounded,
                          "Exciting Offers",
                          "Enjoy deals and exclusive offers",
                          onTap: _showPromoCodesDialog,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

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

                  // 2. Hot Deals Sections - Filtered discounted products with prices to order (StreamBuilder)
                  StreamBuilder<List<ProductModel>>(
                    stream: DatabaseService.getFeaturedProductsStream(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final deals = snapshot.data!.where((p) => p.discountPrice < p.price && p.discountPrice > 0.0).toList();
                      if (deals.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Hot Deals 🔥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: deals.length,
                              itemBuilder: (context, index) {
                                final product = deals[index];
                                return Container(
                                  margin: const EdgeInsets.only(right: 16),
                                  width: 320,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFF1B0E3D), Color(0xFF0F0826)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                                  ),
                                  padding: const EdgeInsets.all(12),
                                  child: Row(
                                    children: [
                                      // Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          product.imageUrls.isNotEmpty ? product.imageUrls.first : 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=200',
                                          width: 100,
                                          height: 100,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) => Container(
                                            width: 100,
                                            height: 100,
                                            color: Colors.white10,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.broken_image, color: Colors.white30, size: 28),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      // Text Details
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              product.name,
                                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              product.brand,
                                              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
                                              maxLines: 1,
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text(
                                                  "₹${product.discountPrice.toStringAsFixed(0)}",
                                                  style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  "₹${product.price.toStringAsFixed(0)}",
                                                  style: const TextStyle(
                                                    color: Colors.white38,
                                                    decoration: TextDecoration.lineThrough,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 8),
                                            // Add to Cart Button
                                            Align(
                                              alignment: Alignment.centerRight,
                                              child: SizedBox(
                                                height: 34,
                                                width: 100,
                                                child: AddToCartButton(product: product),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      );
                    },
                  ),

                  // 3. Featured Products Grid (StreamBuilder)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Featured Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      if (_searchQuery.isNotEmpty)
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                              _locationSearchController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFFFF8A00), size: 16),
                          label: const Text('Clear Filter', style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
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
                      var featured = snapshot.data ?? [];
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        featured = featured.where((p) =>
                          p.name.toLowerCase().contains(query) ||
                          p.brand.toLowerCase().contains(query) ||
                          p.description.toLowerCase().contains(query)
                        ).toList();
                      }

                      if (featured.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('No products match your search/location.', style: TextStyle(color: Colors.white38, fontSize: 14)),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _searchQuery = '';
                                    _locationSearchController.clear();
                                  });
                                },
                                icon: const Icon(Icons.clear_all_rounded, color: Color(0xFFFF8A00)),
                                label: const Text('Clear search filter', style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
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
                        itemBuilder: (context, index) => ProductCard(product: featured[index]),
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
                      var trending = snapshot.data ?? [];
                      if (_searchQuery.isNotEmpty) {
                        final query = _searchQuery.toLowerCase();
                        trending = trending.where((p) =>
                          p.name.toLowerCase().contains(query) ||
                          p.brand.toLowerCase().contains(query) ||
                          p.description.toLowerCase().contains(query)
                        ).toList();
                      }

                      if (trending.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          child: Text('No trending products match your search/location.', style: TextStyle(color: Colors.white38, fontSize: 14)),
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
                        itemBuilder: (context, index) => ProductCard(product: trending[index]),
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
  Widget _buildPromoBadge({required IconData icon, required String title, required String subtitle, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
              ),
              Text(
                subtitle,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFF8A00).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: const Color(0xFFFF8A00), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black45, fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 48,
      color: Colors.black12,
      margin: const EdgeInsets.symmetric(horizontal: 12),
    );
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToOffers() {
    _scrollController.animateTo(
      150.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToFeatured() {
    _scrollController.animateTo(
      380.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _scrollToAbout() {
    _scrollController.animateTo(
      120.0,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _handleTrackOrder() async {
    final user = AuthService.currentUser;
    if (user == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)),
        ),
      ),
    );

    try {
      final ordersList = await DatabaseService.getOrders();
      final userOrders = ordersList.where((o) => o.customerId == user.uid).toList();

      if (!mounted) return;
      Navigator.pop(context); // Dismiss loader

      if (userOrders.isEmpty) {
        _showNoOrdersDialog();
      } else {
        userOrders.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        final latestOrder = userOrders.first;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderTrackingView(orderId: latestOrder.id),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to retrieve orders: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  void _showNoOrdersDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF150A2E),
        title: const Text("Track Order", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text("You have no active or past orders to track. Place an order first!", style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK", style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderLink(String label, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showSafeAndSecureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF150A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Color(0xFFFF8A00)),
            SizedBox(width: 10),
            Text("Safe & Secure Delivery", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSafetyPoint(Icons.clean_hands_rounded, "Contactless Delivery", "All orders are delivered with zero-contact handovers."),
            const SizedBox(height: 12),
            _buildSafetyPoint(Icons.thermostat_rounded, "Temperature Checks", "Daily temp screening for all kitchen staff and riders."),
            const SizedBox(height: 12),
            _buildSafetyPoint(Icons.sanitizer_rounded, "Sanitized Packaging", "Double-sealed bags to ensure freshness and complete hygiene."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got It", style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyPoint(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFFFF8A00), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _showPromoCodesDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)),
        ),
      ),
    );

    try {
      final promos = await DatabaseService.getPromoCodes();
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loader

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF150A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.local_offer_rounded, color: Color(0xFFFF8A00)),
              SizedBox(width: 10),
              Text("Active Promo Codes", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          content: promos.isEmpty
              ? const Text("No active promo codes available right now. Check back soon!", style: TextStyle(color: Colors.white70))
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: promos.length,
                    separatorBuilder: (_, __) => const Divider(color: Colors.white10),
                    itemBuilder: (context, index) {
                      final promo = promos[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(promo.code, style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          "${promo.discountPercentage.toStringAsFixed(0)}% OFF on orders above ₹${promo.minOrderAmount.toStringAsFixed(0)}",
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFFFF8A00)),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text("ACTIVE", style: TextStyle(color: Color(0xFFFF8A00), fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close", style: TextStyle(color: Colors.white60, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load promo codes: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }
}


