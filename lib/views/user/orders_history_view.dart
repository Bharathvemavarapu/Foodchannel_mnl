import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/order.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../widgets/glass_card.dart';
import 'order_tracking_view.dart';
import '../../services/cart_service.dart';
import 'user_bottom_nav.dart';

class OrdersHistoryView extends StatelessWidget {
  const OrdersHistoryView({super.key});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orangeAccent;
      case 'Confirmed':
      case 'Packed':
        return Colors.blueAccent;
      case 'Shipped':
      case 'Out for Delivery':
        return Colors.purpleAccent;
      case 'Delivered':
        return Colors.greenAccent;
      case 'Cancelled':
      case 'Refunded':
        return Colors.redAccent;
      default:
        return Colors.white54;
    }
  }

  Future<void> _handleReorder(BuildContext context, OrderModel order) async {
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
      final catalog = await DatabaseService.getProducts();

      int addedCount = 0;
      for (var item in order.items) {
        final productIndex = catalog.indexWhere((p) => p.id == item.productId);
        if (productIndex >= 0) {
          final product = catalog[productIndex];
          if (product.isAvailable && product.stock > 0) {
            CartService.instance.addToCart(product, quantity: item.quantity);
            addedCount++;
          }
        }
      }

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        if (addedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully added $addedCount item(s) to your cart!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'VIEW CART',
                textColor: Colors.white,
                onPressed: () {
                  UserBottomNav.activeTabNotifier.value = 3;
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not reorder. Some items might be out of stock or unavailable.'),
              backgroundColor: Colors.orangeAccent,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;

    if (user == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF070412),
        body: Center(
          child: Text(
            'Please log in to view order history.',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: const Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: StreamBuilder<List<OrderModel>>(
        stream: DatabaseService.getUserOrdersStream(user.uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)),
              ),
            );
          }
          final orders = snapshot.data ?? [];
          if (orders.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_rounded,
                      size: 80,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'No orders placed yet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white70),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Once you place an order, it will appear here for tracking.',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }

          // Sort orders by newest first
          final sortedOrders = List<OrderModel>.from(orders)
            ..sort((a, b) => b.createdDate.compareTo(a.createdDate));

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: sortedOrders.length,
            itemBuilder: (context, index) {
              final order = sortedOrders[index];
              final dateString = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdDate);
              final itemsCount = order.items.fold(0, (sum, item) => sum + item.quantity);

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GlassCard(
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ID: ${order.id}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(dateString, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(order.status).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: _getStatusColor(order.status).withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              order.status.toUpperCase(),
                              style: TextStyle(
                                color: _getStatusColor(order.status),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          '$itemsCount items  •  ₹${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: Color(0xFFFF8A00),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      children: [
                        const Divider(color: Colors.white10, height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Order Status Tracking',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _handleReorder(context, order),
                                  icon: const Icon(Icons.replay_rounded, size: 14, color: Color(0xFFFF8A00)),
                                  label: const Text('REORDER', style: TextStyle(color: Color(0xFFFF8A00), fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => OrderTrackingView(orderId: order.id),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.map_rounded, size: 14, color: Color(0xFFFF8A00)),
                                  label: const Text('TRACK STATUS', style: TextStyle(color: Color(0xFFFF8A00), fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Items list
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Items Ordered',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...order.items.map((item) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.name} x${item.quantity}',
                                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    '₹${(item.price * item.quantity).toStringAsFixed(2)}',
                                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                                  ),
                                ],
                              ),
                            )),

                        const SizedBox(height: 16),
                        // Delivery Address
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Delivery Address',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            order.deliveryAddress,
                            style: const TextStyle(color: Colors.white60, fontSize: 12),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Timeline Log
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Order Timeline',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...order.timeline.map((event) {
                          final eventTime = DateFormat('dd MMM, hh:mm a').format(event.timestamp);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.circle, size: 8, color: _getStatusColor(event.status)),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            event.status,
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                              color: _getStatusColor(event.status),
                                            ),
                                          ),
                                          Text(eventTime, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                                        ],
                                      ),
                                      if (event.notes.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Text(event.notes, style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
