import 'dart:math' as math;

class RestaurantModel {
  final String id;
  final String name;
  final double rating;
  final String cuisine;
  final String imageUrl;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final int deliveryTimeMins;
  final bool isOpen;

  RestaurantModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.cuisine,
    required this.imageUrl,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    required this.deliveryTimeMins,
    required this.isOpen,
  });
}

class RestaurantService {
  static final RestaurantService instance = RestaurantService._internal();
  RestaurantService._internal();

  // Cached list of dynamic restaurants centered around the last generated center
  List<RestaurantModel> _cachedRestaurants = [];
  double? _lastGenLat;
  double? _lastGenLng;

  final List<Map<String, dynamic>> _restaurantTemplates = [
    {
      "name": "The Culinary Lounge",
      "rating": 4.8,
      "cuisine": "North Indian • Chinese • Tandoori",
      "imageUrl": "https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=400",
      "latOffset": 0.008,
      "lngOffset": -0.009,
      "isOpen": true
    },
    {
      "name": "Coastal Delicacies",
      "rating": 4.6,
      "cuisine": "Seafood • Andhra Special Biryani",
      "imageUrl": "https://images.unsplash.com/photo-1552566626-52f8b828add9?w=400",
      "latOffset": -0.015,
      "lngOffset": 0.012,
      "isOpen": true
    },
    {
      "name": "The Gourmet Bistro",
      "rating": 4.7,
      "cuisine": "Continental • Italian • Desserts",
      "imageUrl": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=400",
      "latOffset": 0.025,
      "lngOffset": 0.021,
      "isOpen": true
    },
    {
      "name": "Spice Route Restaurant",
      "rating": 4.5,
      "cuisine": "Mughlai • Dum Biryani • Kebabs",
      "imageUrl": "https://images.unsplash.com/photo-1590846406792-0adc7f938f1d?w=400",
      "latOffset": -0.005,
      "lngOffset": -0.025,
      "isOpen": false
    },
    {
      "name": "Green Garden Cafe",
      "rating": 4.4,
      "cuisine": "Healthy Food • Salads • Juices",
      "imageUrl": "https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=400",
      "latOffset": 0.018,
      "lngOffset": -0.031,
      "isOpen": true
    },
    {
      "name": "Pizza Planet",
      "rating": 4.9,
      "cuisine": "Pizzas • Garlic Bread • Pasta",
      "imageUrl": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=400",
      "latOffset": -0.032,
      "lngOffset": -0.018,
      "isOpen": true
    },
    {
      "name": "Burger Junction",
      "rating": 4.3,
      "cuisine": "Burgers • Shakes • Fries",
      "imageUrl": "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400",
      "latOffset": -0.022,
      "lngOffset": 0.042,
      "isOpen": true
    },
    {
      "name": "Royal Waffle & Shake",
      "rating": 4.7,
      "cuisine": "Waffles • Ice Creams • Bakery",
      "imageUrl": "https://images.unsplash.com/photo-1563729784474-d77dbb933a9e?w=400",
      "latOffset": 0.038,
      "lngOffset": -0.015,
      "isOpen": true
    }
  ];

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var c = math.cos;
    var a = 0.5 - c((lat2 - lat1) * p)/2 + 
          c(lat1 * p) * c(lat2 * p) * 
          (1 - c((lon2 - lon1) * p))/2;
    return 12742 * math.asin(math.sqrt(a)); // 2 * R; R = 6371 km
  }

  int _getDeliveryTimeFor(double distanceKm) {
    return (distanceKm * 8).round() + 10;
  }

  List<RestaurantModel> getNearbyRestaurants({
    required double userLat,
    required double userLng,
    double maxDistanceKm = 15.0,
    String sortBy = 'nearest', // 'nearest', 'rating', 'speed', 'open'
    String searchQuery = '',
  }) {
    // Generate or update coordinate offsets relative to the user's location
    // To prevent list flickering on every tiny GPS jitter, only regenerate base list
    // if the user has moved more than 200 meters since the last generation.
    bool shouldRegenerate = _cachedRestaurants.isEmpty ||
        _lastGenLat == null ||
        _lastGenLng == null ||
        _calculateDistance(userLat, userLng, _lastGenLat!, _lastGenLng!) > 0.2;

    if (shouldRegenerate) {
      _cachedRestaurants = _restaurantTemplates.map((template) {
        final double lat = userLat + (template['latOffset'] as double);
        final double lng = userLng + (template['lngOffset'] as double);
        final double dist = _calculateDistance(userLat, userLng, lat, lng);
        
        return RestaurantModel(
          id: template['name'].toString().toLowerCase().replaceAll(' ', '_'),
          name: template['name'] as String,
          rating: template['rating'] as double,
          cuisine: template['cuisine'] as String,
          imageUrl: template['imageUrl'] as String,
          latitude: lat,
          longitude: lng,
          distanceKm: dist,
          deliveryTimeMins: _getDeliveryTimeFor(dist),
          isOpen: template['isOpen'] as bool,
        );
      }).toList();
      _lastGenLat = userLat;
      _lastGenLng = userLng;
    } else {
      // Re-calculate distance and delivery time based on current user position
      _cachedRestaurants = _cachedRestaurants.map((res) {
        final double dist = _calculateDistance(userLat, userLng, res.latitude, res.longitude);
        return RestaurantModel(
          id: res.id,
          name: res.name,
          rating: res.rating,
          cuisine: res.cuisine,
          imageUrl: res.imageUrl,
          latitude: res.latitude,
          longitude: res.longitude,
          distanceKm: dist,
          deliveryTimeMins: _getDeliveryTimeFor(dist),
          isOpen: res.isOpen,
        );
      }).toList();
    }

    // Apply filtering
    List<RestaurantModel> filtered = _cachedRestaurants.where((res) {
      final matchesDistance = res.distanceKm <= maxDistanceKm;
      final matchesSearch = searchQuery.isEmpty || 
          res.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          res.cuisine.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesDistance && matchesSearch;
    }).toList();

    // Apply sorting
    if (sortBy == 'nearest') {
      filtered.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (sortBy == 'rating') {
      filtered.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (sortBy == 'speed') {
      filtered.sort((a, b) => a.deliveryTimeMins.compareTo(b.deliveryTimeMins));
    } else if (sortBy == 'open') {
      filtered.sort((a, b) {
        if (a.isOpen && !b.isOpen) return -1;
        if (!a.isOpen && b.isOpen) return 1;
        return a.distanceKm.compareTo(b.distanceKm);
      });
    }

    return filtered;
  }
}
