import 'dart:ui_web' as ui_web;
import 'dart:js_interop';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web/web.dart' as web;
import 'package:geolocator/geolocator.dart';
import '../../models/app_settings.dart';
import '../../models/product.dart';
import '../../models/address.dart';
import '../../models/promo_code.dart';
import '../../services/database_service.dart';
import '../../services/auth_service.dart';
import '../../services/location_service.dart';
import '../../services/restaurant_service.dart';
import '../../utils/constants.dart';
import '../auth/login_view.dart';
import '../../widgets/product_card.dart';
import '../../widgets/add_to_cart_button.dart';
import 'order_tracking_view.dart';
import 'user_bottom_nav.dart';
import '../../widgets/cart_icon_button.dart';

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

  final ScrollController _hotDealsScrollController = ScrollController();
  String _selectedLocationLabel = 'Work';
  List<UserAddressModel> _savedAddresses = [];

  // New location service integration state variables
  bool _isLoadingLocation = false;
  String? _locationError;
  double? _userLat;
  double? _userLng;
  AddressDetails _addressDetails = AddressDetails.empty();
  double _filterDistance = 15.0; // Default max distance
  String _restaurantSortBy = 'nearest'; // Default sorting mode

  @override
  void initState() {
    super.initState();
    _loadStoreMeta();
    _loadUserAddresses();
    _initUserLocation();
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    _scrollController.dispose();
    _hotDealsScrollController.dispose();
    super.dispose();
  }

  Future<void> _initUserLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      final isServiceEnabled = await LocationService.instance.checkAndRequestPermissions();
      if (!isServiceEnabled) {
        setState(() {
          _locationError = LocationService.instance.errorMessage;
          _isLoadingLocation = false;
        });
        return;
      }

      await LocationService.instance.initLocationUpdates(onUpdate: (Position position) {
        if (mounted) {
          setState(() {
            _userLat = position.latitude;
            _userLng = position.longitude;
            _isLoadingLocation = false;
            _locationError = null;
            _addressDetails = LocationService.instance.currentAddress;
            _locationSearchController.text = _addressDetails.fullAddress;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _locationError = e.toString();
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _performLocationSearch(String text) async {
    final query = text.trim();
    if (query.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a location or food search query!'),
          backgroundColor: Color(0xFFFF8A00),
        ),
      );
      return;
    }

    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final pos = await LocationService.instance.forwardGeocode(query);
      if (pos != null) {
        final addrDetails = await LocationService.instance.reverseGeocode(pos.latitude, pos.longitude);
        setState(() {
          _userLat = pos.latitude;
          _userLng = pos.longitude;
          _addressDetails = addrDetails;
          _locationSearchController.text = addrDetails.fullAddress;
          _searchQuery = ''; // Clear food filter on location update to show all nearby restaurants
          _locationError = null;
        });
      } else {
        setState(() {
          _searchQuery = query; // Treat as food query search filter if geocoding fails
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Searching menus and restaurants for: "$query"'),
              backgroundColor: const Color(0xFFFF8A00),
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _searchQuery = query;
      });
    } finally {
      setState(() {
        _isLoadingLocation = false;
      });
      _scrollToFeatured();
    }

    // Persist to user profile database if location changed
    final user = AuthService.currentUser;
    if (user != null && _searchQuery.isEmpty) {
      try {
        await DatabaseService.updateUserProfileFields(user.uid, {
          'address': query,
        });
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delivery location updated to: $query'),
          backgroundColor: const Color(0xFFFF8A00),
        ),
      );
    }
  }

  Future<void> _loadUserAddresses() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        final addresses = await DatabaseService.getUserAddresses(user.uid);
        if (mounted) {
          setState(() {
            _savedAddresses = addresses;
            final match = _savedAddresses.firstWhere(
              (a) => a.title.toLowerCase() == _selectedLocationLabel.toLowerCase(),
              orElse: () => UserAddressModel(id: '', title: '', recipientName: '', phone: '', fullAddress: ''),
            );
            if (match.fullAddress.isNotEmpty) {
              _locationSearchController.text = match.fullAddress;
            }
          });
        }
      } catch (_) {}
    }
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

  void _detectCurrentLocation() {
    _initUserLocation();
  }

  Future<void> _handleLogout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginView()),
    );
  }

  String _getMapboxViewType(double lat, double lng, List<RestaurantModel> restaurants) {
    final token = Constants.mapboxToken;
    final viewType = 'user-mapbox-map-${lat.toStringAsFixed(5)}-${lng.toStringAsFixed(5)}-${restaurants.length}';
    
    final restaurantsJson = jsonEncode(restaurants.map((r) => {
      'name': r.name,
      'rating': r.rating,
      'cuisine': r.cuisine,
      'lat': r.latitude,
      'lng': r.longitude,
      'distance': r.distanceKm.toStringAsFixed(1),
    }).toList());
    
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
    
    /* Animated User Location Marker */
    .user-marker {
      width: 15px;
      height: 15px;
      background: #007cff;
      border: 3px solid #fff;
      border-radius: 50%;
      box-shadow: 0 0 10px rgba(0, 0, 0, 0.4);
      position: relative;
    }
    .user-marker::after {
      content: '';
      position: absolute;
      width: 45px;
      height: 45px;
      border-radius: 50%;
      background: rgba(0, 124, 255, 0.25);
      top: -18px;
      left: -18px;
      animation: pulse 2s infinite ease-out;
    }
    @keyframes pulse {
      0% { transform: scale(0.5); opacity: 1; }
      100% { transform: scale(1.8); opacity: 0; }
    }
    
    /* Restaurant Marker style */
    .restaurant-marker {
      font-size: 26px;
      cursor: pointer;
      filter: drop-shadow(0 2px 4px rgba(0,0,0,0.5));
      transition: transform 0.2s;
    }
    .restaurant-marker:hover {
      transform: scale(1.2);
    }
    
    /* Custom Popup styling */
    .mapboxgl-popup-content {
      background: #140A28 !important;
      color: #FFFFFF !important;
      border-radius: 12px;
      border: 1px solid rgba(255,255,255,0.1);
      padding: 10px 14px;
      font-family: 'Outfit', sans-serif;
    }
    .mapboxgl-popup-anchor-top .mapboxgl-popup-tip { border-bottom-color: #140A28 !important; }
    .mapboxgl-popup-anchor-bottom .mapboxgl-popup-tip { border-top-color: #140A28 !important; }
    .mapboxgl-popup-anchor-left .mapboxgl-popup-tip { border-right-color: #140A28 !important; }
    .mapboxgl-popup-anchor-right .mapboxgl-popup-tip { border-left-color: #140A28 !important; }
  </style>
</head>
<body>
  <div id="map"></div>
  <script>
    mapboxgl.accessToken = '$token';
    const map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/navigation-night-v1',
      center: [$lng, $lat],
      zoom: 12
    });
    
    map.on('load', () => {
      map.flyTo({
        center: [$lng, $lat],
        zoom: 15.5,
        essential: true,
        duration: 2500
      });
    });

    const userMarkerEl = document.createElement('div');
    userMarkerEl.className = 'user-marker';
    new mapboxgl.Marker(userMarkerEl).setLngLat([$lng, $lat]).addTo(map);

    const restaurants = $restaurantsJson;
    restaurants.forEach(r => {
      const el = document.createElement('div');
      el.className = 'restaurant-marker';
      el.innerHTML = '🍔';
      
      const popup = new mapboxgl.Popup({ offset: 25 })
        .setHTML(`
          <div style="font-size: 13px; font-weight: bold; color: #FFFF8A00;">\${r.name}</div>
          <div style="font-size: 11px; margin-top: 4px; color: #e0e0e0;">\${r.cuisine}</div>
          <div style="font-size: 10px; margin-top: 4px; color: #a0a0a0;">⭐ \${r.rating} • \${r.distance} km away</div>
        `);
        
      new mapboxgl.Marker(el)
        .setLngLat([r.lng, r.lat])
        .setPopup(popup)
        .addTo(map);
    });
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
                    const CartIconButton(),
                    const SizedBox(width: 12),
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
                                onSubmitted: (val) => _performLocationSearch(val),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.my_location_rounded, color: Color(0xFFFF8A00), size: 20),
                              tooltip: 'Use Current Location',
                              onPressed: _detectCurrentLocation,
                            ),
                            PopupMenuButton<String>(
                              tooltip: 'Select Location Label',
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: const BoxDecoration(
                                  border: Border(left: BorderSide(color: Colors.black12, width: 1)),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      _selectedLocationLabel,
                                      style: const TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const Icon(Icons.keyboard_arrow_down, color: Colors.black54, size: 18),
                                  ],
                                ),
                              ),
                              onSelected: (String label) async {
                                String selectedAddressText = '';
                                setState(() {
                                  _selectedLocationLabel = label;
                                  final match = _savedAddresses.firstWhere(
                                    (a) => a.title.toLowerCase() == label.toLowerCase(),
                                    orElse: () => UserAddressModel(id: '', title: '', recipientName: '', phone: '', fullAddress: ''),
                                  );
                                  if (match.fullAddress.isNotEmpty) {
                                    selectedAddressText = match.fullAddress;
                                  } else {
                                    if (label == 'Home') {
                                      selectedAddressText = '123 Main Street, Sector 4, Bangalore';
                                    } else if (label == 'Work') {
                                      selectedAddressText = 'Office Complex Phase 2, Whitefield, Bangalore';
                                    }
                                  }
                                  _locationSearchController.text = selectedAddressText;
                                });
                                if (selectedAddressText.isNotEmpty) {
                                  await _performLocationSearch(selectedAddressText);
                                }
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(value: 'Home', child: Text('Home')),
                                const PopupMenuItem<String>(value: 'Work', child: Text('Work')),
                                const PopupMenuItem<String>(value: 'Office', child: Text('Office')),
                                const PopupMenuItem<String>(value: 'Other', child: Text('Other')),
                              ],
                            ),
                            ElevatedButton(
                              onPressed: () => _performLocationSearch(_locationSearchController.text),
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
                              onTap: () {
                                Clipboard.setData(const ClipboardData(text: "FIRST50"));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Promo code "FIRST50" copied to clipboard! Apply it at checkout for 50% off.'),
                                    backgroundColor: Color(0xFFFF8A00),
                                  ),
                                );
                                _scrollToOffers();
                              },
                            ),
                            const SizedBox(width: 12),
                            _buildPromoBadge(
                              icon: Icons.electric_moped_rounded,
                              title: "Fast Delivery",
                              subtitle: "In 30-45 mins",
                              color: const Color(0xFFFFB300),
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
                            const SizedBox(width: 12),
                            _buildPromoBadge(
                              icon: Icons.verified_rounded,
                              title: "Best Offers",
                              subtitle: "On All Orders",
                              color: const Color(0xFFDA1B60),
                              onTap: _showPromoCodesDialog,
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
                        const Expanded(
                          flex: 12,
                          child: _HoverAnimatedHeroImage(
                            key: ValueKey('hero-image-desktop'),
                            aspectRatio: 1.25,
                            showGradient: true,
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
                      const _HoverAnimatedHeroImage(
                        key: ValueKey('hero-image-mobile'),
                        aspectRatio: 1.4,
                        showGradient: false,
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Hot Deals 🔥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFF8A00), size: 18),
                                    onPressed: () {
                                      _hotDealsScrollController.animateTo(
                                        _hotDealsScrollController.offset - 320,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFFFF8A00), size: 18),
                                    onPressed: () {
                                      _hotDealsScrollController.animateTo(
                                        _hotDealsScrollController.offset + 320,
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 180,
                            child: ListView.builder(
                              controller: _hotDealsScrollController,
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

                  // A. Nearby Top Restaurants Section
                  const Text('Top Restaurants Near Your Location 📍', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  if (_isLoadingLocation) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24.0),
                      child: Center(
                        child: Column(
                          children: [
                            CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
                            SizedBox(height: 12),
                            Text("Detecting your live coordinates...", style: TextStyle(color: Colors.white54, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ] else if (_locationError != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, color: Colors.redAccent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _locationError!,
                                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    await Geolocator.openAppSettings();
                                  },
                                  icon: const Icon(Icons.settings, size: 16, color: Color(0xFFFF8A00)),
                                  label: const Text("Device Settings", style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  onPressed: _initUserLocation,
                                  icon: const Icon(Icons.my_location, size: 16),
                                  label: const Text("Try Again", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      _addressDetails.fullAddress.isNotEmpty 
                          ? 'Showing popular restaurants near: ${_addressDetails.fullAddress}'
                          : 'Please use location detection or search to find restaurants near you',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    
                    // Filter & Sort UI
                    Row(
                      children: [
                        // Distance Filter
                        PopupMenuButton<double>(
                          tooltip: 'Filter Distance',
                          onSelected: (double val) {
                            setState(() {
                              _filterDistance = val;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFF8A00).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.radar_rounded, color: Color(0xFFFF8A00), size: 14),
                                const SizedBox(width: 6),
                                Text('Within ${_filterDistance.toInt()} km', style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 5.0, child: Text('Within 5 km')),
                            const PopupMenuItem(value: 10.0, child: Text('Within 10 km')),
                            const PopupMenuItem(value: 15.0, child: Text('Within 15 km')),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Sort selector
                        PopupMenuButton<String>(
                          tooltip: 'Sort Restaurants',
                          onSelected: (String val) {
                            setState(() {
                              _restaurantSortBy = val;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF8A00).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFFF8A00).withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.sort_rounded, color: Color(0xFFFF8A00), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  _restaurantSortBy == 'nearest' ? 'Nearest First' :
                                  _restaurantSortBy == 'rating' ? 'Highest Rated' :
                                  _restaurantSortBy == 'speed' ? 'Fastest Delivery' : 'Open Now',
                                  style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)
                                ),
                                const SizedBox(width: 4),
                                const Icon(Icons.arrow_drop_down, color: Colors.white54, size: 16),
                              ],
                            ),
                          ),
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'nearest', child: Text('Nearest First')),
                            const PopupMenuItem(value: 'rating', child: Text('Highest Rated')),
                            const PopupMenuItem(value: 'speed', child: Text('Fastest Delivery')),
                            const PopupMenuItem(value: 'open', child: Text('Open Now')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Neighborhood Interactive Mapbox Map
                    if (_userLat != null && _userLng != null) ...[
                      const Text('Live Neighborhood Map 🗺️', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white70)),
                      const SizedBox(height: 8),
                      Container(
                        height: 240,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1.5),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: HtmlElementView(
                            key: ValueKey('user-live-map-$_userLat-$_userLng-${_getRestaurantsForLocation().length}'),
                            viewType: _getMapboxViewType(_userLat!, _userLng!, _getRestaurantsForLocation()),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    SizedBox(
                      height: 140,
                      child: Builder(
                        builder: (context) {
                          final restaurants = _getRestaurantsForLocation();
                          if (restaurants.isEmpty) {
                            return const Center(
                              child: Text('No nearby restaurants match the filters/search.', style: TextStyle(color: Colors.white38, fontSize: 13)),
                            );
                          }
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: restaurants.length,
                            itemBuilder: (context, index) {
                              final rest = restaurants[index];
                              return _buildRestaurantCard(rest);
                            },
                          );
                        }
                      ),
                    ),
                  ],
                  const SizedBox(height: 36),

                  // B. Active Offers & Promo Coupons Section
                  const Text('Exclusive Active Offers 🏷️', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 8),
                  const Text('Tap on any code to copy and apply discount at checkout', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  const SizedBox(height: 16),
                  FutureBuilder<List<PromoCodeModel>>(
                    future: DatabaseService.getPromoCodes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        // Return a default couple of attractive mock offers if database is empty
                        return SizedBox(
                          height: 100,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              _buildPromoCard("FIRST50", "50% OFF on your first order", "Min Order: ₹200"),
                              _buildPromoCard("FREEDEL", "Free delivery on premium food", "Min Order: ₹500"),
                              _buildPromoCard("CHEFSPECIAL", "₹100 discount on chef recommendations", "Min Order: ₹400"),
                            ],
                          ),
                        );
                      }

                      final promos = snapshot.data!;
                      return SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: promos.length,
                          itemBuilder: (context, idx) {
                            final promo = promos[idx];
                            return _buildPromoCard(
                              promo.code,
                              "${promo.discountPercentage.toStringAsFixed(0)}% OFF Discount Coupon",
                              "Min Order: ₹${promo.minOrderAmount.toStringAsFixed(0)}",
                            );
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),

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
                          viewType: _getMapboxViewType(_address.latitude, _address.longitude, []),
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
  Widget _buildPromoBadge({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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

  List<RestaurantModel> _getRestaurantsForLocation() {
    if (_userLat == null || _userLng == null) return [];
    return RestaurantService.instance.getNearbyRestaurants(
      userLat: _userLat!,
      userLng: _userLng!,
      maxDistanceKm: _filterDistance,
      sortBy: _restaurantSortBy,
      searchQuery: _searchQuery,
    );
  }

  Widget _buildRestaurantCard(RestaurantModel rest) {
    final distance = rest.distanceKm;
    final deliveryTime = rest.deliveryTimeMins;
    final name = rest.name;
    final rating = "${rest.rating.toStringAsFixed(1)} ★";
    final cuisine = rest.cuisine;
    final imageUrl = rest.imageUrl;

    return GestureDetector(
      onTap: () {
        setState(() {
          _searchQuery = name;
        });
        _scrollToFeatured();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Showing menus from $name! Distance: ${distance.toStringAsFixed(1)} km, Delivery Time: $deliveryTime mins.'),
            backgroundColor: const Color(0xFFFF8A00),
          ),
        );
      },
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF140A28),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Background Image
              Positioned.fill(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.white10),
                ),
              ),
              // Black transparent gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.black87, Colors.black.withValues(alpha: 0.3)],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              // Details
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF8A00),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(rating, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                        const SizedBox(width: 8),
                        Text('$deliveryTime mins', style: const TextStyle(color: Color(0xFFFF8A00), fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(cuisine, style: const TextStyle(color: Colors.white38, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPromoCard(String code, String desc, String minOrder) {
    return GestureDetector(
      onTap: () {
        Clipboard.setData(ClipboardData(text: code));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Coupon "$code" copied to clipboard! Apply at checkout.'),
            backgroundColor: const Color(0xFFFF8A00),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3E1F5F), Color(0xFF230D3A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFFF8A00).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFFF8A00),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_offer_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(code, style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.0)),
                  const SizedBox(height: 4),
                  Text(desc, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  Text(minOrder, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HoverAnimatedHeroImage extends StatefulWidget {
  final double aspectRatio;
  final bool showGradient;

  const _HoverAnimatedHeroImage({
    super.key,
    required this.aspectRatio,
    required this.showGradient,
  });

  @override
  State<_HoverAnimatedHeroImage> createState() => _HoverAnimatedHeroImageState();
}

class _HoverAnimatedHeroImageState extends State<_HoverAnimatedHeroImage> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned.fill(
                child: AnimatedScale(
                  scale: _isHovered ? 1.08 : 1.0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                  child: Image.asset(
                    'assets/hero_mockup.jpg',
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                  ),
                ),
              ),
              if (widget.showGradient)
                Positioned.fill(
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF070412).withValues(alpha: 0.65),
                            Colors.transparent,
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
