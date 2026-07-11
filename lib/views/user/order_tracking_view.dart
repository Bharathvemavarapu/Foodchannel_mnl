import 'dart:convert';
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import '../../models/order.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_card.dart';
import '../../utils/constants.dart';

class OrderTrackingView extends StatefulWidget {
  final String orderId;

  const OrderTrackingView({super.key, required this.orderId});

  @override
  State<OrderTrackingView> createState() => _OrderTrackingViewState();
}

class _OrderTrackingViewState extends State<OrderTrackingView> {
  bool _isCancelling = false;

  Stream<OrderModel?> _getOrderStream(String orderId) async* {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    final url = Uri.parse('https://foodchannelmnl-default-rtdb.firebaseio.com/orders/$orderId.json?auth=$token');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200 && response.body != 'null') {
        yield OrderModel.fromJson(orderId, jsonDecode(response.body));
      }
    } catch (_) {
      yield null;
    }

    yield* Stream.periodic(const Duration(seconds: 15)).asyncMap((_) async {
      try {
        final response = await http.get(url);
        if (response.statusCode == 200 && response.body != 'null') {
          return OrderModel.fromJson(orderId, jsonDecode(response.body));
        }
      } catch (_) {}
      return null;
    });
  }

  int _getStatusStepIndex(String status) {
    switch (status) {
      case 'Pending':
        return 0;
      case 'Confirmed':
        return 1;
      case 'Packed':
        return 2;
      case 'Shipped':
      case 'Out for Delivery':
        return 3;
      case 'Delivered':
        return 4;
      case 'Cancelled':
      case 'Refunded':
        return -1;
      default:
        return 0;
    }
  }

  String _getMapboxViewType(double customerLat, double customerLng, double restaurantLat, double restaurantLng) {
    final viewType = 'rider-mapbox-map-${widget.orderId}-${customerLat.toStringAsFixed(4)}-${restaurantLat.toStringAsFixed(4)}';
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
    mapboxgl.accessToken = '${Constants.mapboxToken}';
    const customer = [$customerLng, $customerLat];
    const restaurant = [$restaurantLng, $restaurantLat];
    
    const map = new mapboxgl.Map({
      container: 'map',
      style: 'mapbox://styles/mapbox/navigation-night-v1',
      center: [(customer[0] + restaurant[0]) / 2, (customer[1] + restaurant[1]) / 2],
      zoom: 13
    });

    const restMarkerEl = document.createElement('div');
    restMarkerEl.innerHTML = '🏢';
    restMarkerEl.style.fontSize = '24px';
    new mapboxgl.Marker(restMarkerEl).setLngLat(restaurant).addTo(map);

    const custMarkerEl = document.createElement('div');
    custMarkerEl.innerHTML = '📍';
    custMarkerEl.style.fontSize = '24px';
    new mapboxgl.Marker(custMarkerEl).setLngLat(customer).addTo(map);

    const riderMarkerEl = document.createElement('div');
    riderMarkerEl.innerHTML = '🛵';
    riderMarkerEl.style.fontSize = '28px';
    const riderMarker = new mapboxgl.Marker(riderMarkerEl).setLngLat(restaurant).addTo(map);

    map.on('load', () => {
      map.addSource('route', {
        'type': 'geojson',
        'data': {
          'type': 'Feature',
          'properties': {},
          'geometry': {
            'type': 'LineString',
            'coordinates': [restaurant, customer]
          }
        }
      });

      map.addLayer({
        'id': 'route-line',
        'type': 'line',
        'source': 'route',
        'layout': {
          'line-join': 'round',
          'line-cap': 'round'
        },
        'paint': {
          'line-color': '#FF8A00',
          'line-width': 4,
          'line-dasharray': [2, 2]
        }
      });

      let progress = 0;
      const steps = 600;
      function animate() {
        progress = (progress + 1) % steps;
        const ratio = progress / steps;
        const currentLng = restaurant[0] + (customer[0] - restaurant[0]) * ratio;
        const currentLat = restaurant[1] + (customer[1] - restaurant[1]) * ratio;
        riderMarker.setLngLat([currentLng, currentLat]);
        requestAnimationFrame(animate);
      }
      animate();
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

  Future<void> _handleCancelOrder() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF150A2E),
        title: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
        content: const Text('Are you sure you want to cancel this order?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('NO', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('YES, CANCEL', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isCancelling = true);
      try {
        await DatabaseService.updateOrderStatus(widget.orderId, 'Cancelled', 'Cancelled by customer.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order cancelled successfully'), backgroundColor: Colors.green),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel order: $e'), backgroundColor: Colors.redAccent),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isCancelling = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: const Text('Track Order', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _getOrderStream(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
            );
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(
              child: Text('Order details loading or not found.', style: TextStyle(color: Colors.white70)),
            );
          }

          final stepIndex = _getStatusStepIndex(order.status);
          final dateString = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdDate);
          final isCancelled = order.status == 'Cancelled' || order.status == 'Refunded';

          double customerLat = 12.9716;
          double customerLng = 77.5946;
          
          final gpsRegex = RegExp(r"Lat:\s*([-\d.]+),\s*Lng:\s*([-\d.]+)");
          final match = gpsRegex.firstMatch(order.deliveryAddress);
          if (match != null) {
            customerLat = double.tryParse(match.group(1) ?? '') ?? customerLat;
            customerLng = double.tryParse(match.group(2) ?? '') ?? customerLng;
          }

          final restaurantName = order.items.isNotEmpty ? order.items.first.name : 'FoodChannel';
          final latOffset = (restaurantName.hashCode % 10 + 5) / 1000.0;
          final lngOffset = (restaurantName.hashCode % 8 + 5) / 1000.0;
          
          final restaurantLat = customerLat + latOffset;
          final restaurantLng = customerLng + lngOffset;

          final latDiff = (customerLat - restaurantLat).abs();
          final lngDiff = (customerLng - restaurantLng).abs();
          final distance = (latDiff + lngDiff) * 100.0;
          final deliveryTime = (distance * 8).round() + 8;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header details
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ORDER ID: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Placed on $dateString', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          Text('₹${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Payment Mode', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          Text(order.paymentMethod, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Delivery Distance', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          Text('${distance.toStringAsFixed(1)} km', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Estimated Delivery Time', style: TextStyle(color: Colors.white60, fontSize: 13)),
                          Text('$deliveryTime mins', style: const TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (!isCancelled) ...[
                  const Text('Live Delivery Route 🛵', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 12),
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: HtmlElementView(
                        key: ValueKey('order-map-${order.id}-${order.status}'),
                        viewType: _getMapboxViewType(customerLat, customerLng, restaurantLat, restaurantLng),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Tracker Status Timeline
                const Text('Delivery Status', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),

                if (isCancelled) ...[
                  GlassCard(
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, color: Colors.redAccent, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Order ${order.status}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              const Text('This order was cancelled and cannot be tracked further.', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GlassCard(
                    child: Column(
                      children: [
                        _buildTrackerStep(0, stepIndex, 'Order Placed', 'Your order has been recorded.'),
                        _buildTrackerStep(1, stepIndex, 'Confirmed', 'Seller accepted your order request.'),
                        _buildTrackerStep(2, stepIndex, 'Packed', 'Your kitchen tools are packed and sealed.'),
                        _buildTrackerStep(3, stepIndex, 'On The Way', 'Courier partner dispatched the shipping box.'),
                        _buildTrackerStep(4, stepIndex, 'Delivered', 'Enjoy your new kitchenware items!', isLast: true),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // History logs timeline
                const Text('Activity Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: order.timeline.map((event) {
                      final time = DateFormat('dd MMM, hh:mm a').format(event.timestamp);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, color: Color(0xFFFF8A00), size: 16),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(event.status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 13)),
                                      Text(time, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                    ],
                                  ),
                                  if (event.notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(event.notes, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.3)),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 32),

                // Cancel Order Option
                if (order.status == 'Pending')
                  ElevatedButton(
                    onPressed: _isCancelling ? null : _handleCancelOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                      foregroundColor: Colors.redAccent,
                      side: const BorderSide(color: Colors.redAccent, width: 1.2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: _isCancelling
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.redAccent)),
                          )
                        : const Text('CANCEL ORDER', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrackerStep(int stepKey, int activeIndex, String title, String subtitle, {bool isLast = false}) {
    final isDone = activeIndex >= stepKey;
    final isCurrent = activeIndex == stepKey;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isDone ? const Color(0xFFFF8A00) : Colors.white12,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCurrent ? Colors.white : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.check,
                color: isDone ? Colors.white : Colors.white24,
                size: 14,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 40,
                color: isDone ? const Color(0xFFFF8A00) : Colors.white12,
              ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDone ? Colors.white : Colors.white38,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  color: isDone ? Colors.white54 : Colors.white24,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }
}
