import 'dart:convert';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;
import '../../../models/app_settings.dart';
import '../../../services/database_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../utils/constants.dart';

class StoreAddressTab extends StatefulWidget {
  const StoreAddressTab({super.key});

  @override
  State<StoreAddressTab> createState() => _StoreAddressTabState();
}

class _StoreAddressTabState extends State<StoreAddressTab> {
  static const String mapboxToken = Constants.mapboxToken;

  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();

  List<dynamic> _suggestions = [];
  bool _isLoading = true;
  bool _isSearching = false;
  bool _isSaving = false;

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadAddress();
  }

  Future<void> _loadAddress() async {
    setState(() => _isLoading = true);
    try {
      final addr = await DatabaseService.getStoreAddress();
      setState(() {
        _addressController.text = addr.fullAddress;
        _latitude = addr.latitude;
        _longitude = addr.longitude;
        _latController.text = addr.latitude.toString();
        _lngController.text = addr.longitude.toString();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load store address: $e');
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) return;
    setState(() => _isSearching = true);
    try {
      final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/${Uri.encodeComponent(query)}.json?access_token=$mapboxToken&limit=5',
      );
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _suggestions = data['features'] ?? [];
        });
      }
    } catch (e) {
      _showErrorSnackBar('Geocoding search error: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  void _selectSuggestion(dynamic feature) {
    final placeName = feature['place_name'] as String;
    final List<dynamic> center = feature['center'] as List<dynamic>;
    final double lng = (center[0] as num).toDouble();
    final double lat = (center[1] as num).toDouble();

    setState(() {
      _addressController.text = placeName;
      _latitude = lat;
      _longitude = lng;
      _latController.text = lat.toString();
      _lngController.text = lng.toString();
      _suggestions = [];
      _searchController.clear();
    });
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);
    
    if (lat == null || lng == null) {
      _showErrorSnackBar('Please enter valid coordinates.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final addr = StoreAddressModel(
        fullAddress: _addressController.text.trim(),
        latitude: lat,
        longitude: lng,
      );
      await DatabaseService.saveStoreAddress(addr);
      _showSuccessSnackBar('Store address saved successfully!');
      _loadAddress();
    } catch (e) {
      _showErrorSnackBar('Failed to save address: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String _getMapboxViewType(double lat, double lng) {
    final viewType = 'store-mapbox-map-${lat.toStringAsFixed(5)}-${lng.toStringAsFixed(5)}';
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
    mapboxgl.accessToken = '$mapboxToken';
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
  void dispose() {
    _searchController.dispose();
    _addressController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Store Address', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 6),
            Text('Pinpoint e-commerce store logistics hub location via Mapbox Geocoder', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
            const SizedBox(height: 28),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 5,
                  child: GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Geocoding Address Search', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 16),
                        
                        TextField(
                          controller: _searchController,
                          style: const TextStyle(color: Colors.white),
                          onSubmitted: _searchAddress,
                          decoration: InputDecoration(
                            hintText: 'Search for address (e.g. Visakhapatnam)...',
                            prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8A00)),
                            suffixIcon: _isSearching
                                ? const Padding(
                                    padding: EdgeInsets.all(12.0),
                                    child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
                                  )
                                : IconButton(
                                    icon: const Icon(Icons.arrow_forward_rounded, color: Color(0xFFFF8A00)),
                                    onPressed: () => _searchAddress(_searchController.text),
                                  ),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.02),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                          ),
                        ),
                        
                        if (_suggestions.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF150A2E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _suggestions.length,
                              itemBuilder: (context, index) {
                                final s = _suggestions[index];
                                return ListTile(
                                  title: Text(s['place_name'] ?? '', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                                  onTap: () => _selectSuggestion(s),
                                );
                              },
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),
                        const Divider(color: Colors.white10),
                        const SizedBox(height: 16),
                        
                        TextFormField(
                          controller: _addressController,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 2,
                          decoration: const InputDecoration(labelText: 'Full Address', prefixIcon: Icon(Icons.pin_drop_rounded, color: Color(0xFFFF8A00))),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter address' : null,
                        ),
                        const SizedBox(height: 16),
                        
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _latController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(labelText: 'Latitude', prefixIcon: Icon(Icons.explore_outlined, color: Color(0xFFFF8A00))),
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                                onChanged: (val) {
                                  final numVal = double.tryParse(val);
                                  if (numVal != null) {
                                    setState(() {
                                      _latitude = numVal;
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: _lngController,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(labelText: 'Longitude', prefixIcon: Icon(Icons.explore_outlined, color: Color(0xFFFF8A00))),
                                validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid' : null,
                                onChanged: (val) {
                                  final numVal = double.tryParse(val);
                                  if (numVal != null) {
                                    setState(() {
                                      _longitude = numVal;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        ElevatedButton(
                          onPressed: _isSaving ? null : _saveAddress,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSaving
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
                              : const Text('SAVE ADDRESS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(width: 24),
                
                Expanded(
                  flex: 5,
                  child: GlassCard(
                    child: Column(
                      children: [
                        const Text('Map Live Preview', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 20),
                        
                        Container(
                          height: 340,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: _latitude != null && _longitude != null
                                ? HtmlElementView(
                                     key: ValueKey('map-$_latitude-$_longitude'),
                                     viewType: _getMapboxViewType(_latitude!, _longitude!),
                                  )
                                : const Center(child: Text('Map coordinates not set.', style: TextStyle(color: Colors.white38))),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
