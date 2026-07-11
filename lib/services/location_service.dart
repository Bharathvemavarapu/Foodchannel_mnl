import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../utils/constants.dart';

class AddressDetails {
  final String fullAddress;
  final String area;
  final String city;
  final String state;
  final String country;

  AddressDetails({
    required this.fullAddress,
    required this.area,
    required this.city,
    required this.state,
    required this.country,
  });

  factory AddressDetails.empty() {
    return AddressDetails(
      fullAddress: '',
      area: '',
      city: '',
      state: '',
      country: '',
    );
  }
}

class LocationService {
  static final LocationService instance = LocationService._internal();
  LocationService._internal();

  Position? _currentPosition;
  AddressDetails _currentAddress = AddressDetails.empty();
  bool _isLoading = false;
  String? _errorMessage;

  final _locationController = StreamController<Position>.broadcast();
  Stream<Position> get onLocationChanged => _locationController.stream;

  Position? get currentPosition => _currentPosition;
  AddressDetails get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  StreamSubscription<Position>? _positionSubscription;

  Future<bool> checkAndRequestPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage = "Location services are disabled. Please enable them in settings.";
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = "Location permissions are denied.";
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage = "Location permissions are permanently denied. Please enable them in device settings.";
      return false;
    }

    _errorMessage = null;
    return true;
  }

  Future<void> initLocationUpdates({required Function(Position) onUpdate}) async {
    final hasPermission = await checkAndRequestPermissions();
    if (!hasPermission) return;

    _isLoading = true;
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      _updatePosition(position);
      onUpdate(position);
    } catch (e) {
      _errorMessage = "Failed to get current location: $e";
    } finally {
      _isLoading = false;
    }

    // Subscribe to live changes
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // Update when user moves 10 meters
      ),
    ).listen((Position position) {
      _updatePosition(position);
      onUpdate(position);
    }, onError: (error) {
      _errorMessage = "Location stream error: $error";
    });
  }

  void _updatePosition(Position position) {
    _currentPosition = position;
    _locationController.add(position);
    reverseGeocode(position.latitude, position.longitude);
  }

  Future<AddressDetails> reverseGeocode(double lat, double lng) async {
    try {
      final token = Constants.mapboxToken;
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$lng,$lat.json?access_token=$token&limit=1',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final first = features[0];
          final placeName = first['place_name'] as String? ?? '';
          
          String area = '';
          String city = '';
          String state = '';
          String country = '';

          final contextList = first['context'] as List?;
          if (contextList != null) {
            for (var ctx in contextList) {
              final id = ctx['id'] as String? ?? '';
              final text = ctx['text'] as String? ?? '';
              if (id.startsWith('neighborhood') || id.startsWith('locality')) {
                area = text;
              } else if (id.startsWith('place')) {
                city = text;
              } else if (id.startsWith('region')) {
                state = text;
              } else if (id.startsWith('country')) {
                country = text;
              }
            }
          }

          // Fallbacks
          if (city.isEmpty && first['text'] != null) {
            city = first['text'];
          }

          _currentAddress = AddressDetails(
            fullAddress: placeName,
            area: area.isNotEmpty ? area : "Nearby Area",
            city: city.isNotEmpty ? city : "Unknown City",
            state: state,
            country: country,
          );
          return _currentAddress;
        }
      }
    } catch (_) {}
    
    return AddressDetails(
      fullAddress: "Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}",
      area: "GPS Location",
      city: "Current Coordinates",
      state: "",
      country: "",
    );
  }

  Future<Position?> forwardGeocode(String address) async {
    try {
      final token = Constants.mapboxToken;
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(address)}.json?access_token=$token&limit=1',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final features = data['features'] as List?;
        if (features != null && features.isNotEmpty) {
          final first = features[0];
          final center = first['center'] as List?;
          if (center != null && center.length >= 2) {
            final double lng = (center[0] as num).toDouble();
            final double lat = (center[1] as num).toDouble();
            return Position(
              latitude: lat,
              longitude: lng,
              timestamp: DateTime.now(),
              accuracy: 0.0,
              altitude: 0.0,
              heading: 0.0,
              speed: 0.0,
              speedAccuracy: 0.0,
              altitudeAccuracy: 0.0,
              headingAccuracy: 0.0,
            );
          }
        }
      }
    } catch (_) {}
    return null;
  }

  void dispose() {
    _positionSubscription?.cancel();
    _locationController.close();
  }
}
