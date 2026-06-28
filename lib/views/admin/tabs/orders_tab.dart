import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import '../../../models/order.dart';
import '../../../services/database_service.dart';
import '../../../widgets/glass_card.dart';

class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab> {
  List<OrderModel> _orders = [];
  List<OrderModel> _filteredOrders = [];
  bool _isLoading = true;

  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Pending', 'Confirmed', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled', 'Refunded'

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      await _prepopulateMockOrders();
      final list = await DatabaseService.getOrders();
      setState(() {
        _orders = list;
        _applyFilters();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load orders: $e');
    }
  }

  Future<void> _prepopulateMockOrders() async {
    final list = await DatabaseService.getOrders();
    if (list.isNotEmpty) return;
    
    final mockOrder1 = OrderModel(
      id: 'ORD-98432-849',
      customerId: 'cust_01',
      customerName: 'Bharath Vemavarapu',
      customerEmail: 'bharath@example.com',
      customerPhone: '+91 98765 43210',
      items: [
        OrderItemModel(productId: 'prod_1', name: 'Premium Cast Iron Skillet', quantity: 1, price: 2499.0),
        OrderItemModel(productId: 'prod_2', name: 'Stainless Steel Whisk', quantity: 2, price: 299.0),
      ],
      totalAmount: 3097.0,
      deliveryAddress: 'Flat 402, Signature Towers, Visakhapatnam, Andhra Pradesh, 530017',
      paymentMethod: 'Razorpay',
      paymentStatus: 'Paid',
      status: 'Delivered',
      createdDate: DateTime.now().subtract(const Duration(days: 2)),
      timeline: [
        OrderTimelineEvent(status: 'Pending', timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 4)), notes: 'Order placed online.'),
        OrderTimelineEvent(status: 'Confirmed', timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 3)), notes: 'Order verified and payment confirmed.'),
        OrderTimelineEvent(status: 'Packed', timestamp: DateTime.now().subtract(const Duration(days: 2)), notes: 'Order packed in bubblewrap.'),
        OrderTimelineEvent(status: 'Shipped', timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 6)), notes: 'Handed over to Bluedart logistics courier.'),
        OrderTimelineEvent(status: 'Delivered', timestamp: DateTime.now().subtract(const Duration(hours: 12)), notes: 'Delivered to customer doorstep.'),
      ],
    );

    final mockOrder2 = OrderModel(
      id: 'ORD-12948-439',
      customerId: 'cust_02',
      customerName: 'Anil Kumar',
      customerEmail: 'anil.k@example.com',
      customerPhone: '+91 87654 32109',
      items: [
        OrderItemModel(productId: 'prod_3', name: 'Non-stick Frying Pan 28cm', quantity: 1, price: 1899.0),
      ],
      totalAmount: 1899.0,
      deliveryAddress: 'Sector 5, MVP Colony, Visakhapatnam, Andhra Pradesh, 530017',
      paymentMethod: 'Cash on Delivery',
      paymentStatus: 'Pending',
      status: 'Confirmed',
      createdDate: DateTime.now().subtract(const Duration(hours: 4)),
      timeline: [
        OrderTimelineEvent(status: 'Pending', timestamp: DateTime.now().subtract(const Duration(hours: 4)), notes: 'Order created with COD delivery option.'),
        OrderTimelineEvent(status: 'Confirmed', timestamp: DateTime.now().subtract(const Duration(hours: 3)), notes: 'Logistics confirmed via phone verification.'),
      ],
    );

    await DatabaseService.addOrder(mockOrder1);
    await DatabaseService.addOrder(mockOrder2);
  }

  void _applyFilters() {
    setState(() {
      _filteredOrders = _orders.where((order) {
        final matchesQuery = order.id.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            order.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _statusFilter == 'All' || order.status == _statusFilter;
        return matchesQuery && matchesStatus;
      }).toList();
    });
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.green));
  }

  Future<void> _updateStatus(String orderId, String newStatus) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF150A2E),
        title: Text('Update Order to: $newStatus'),
        content: TextField(
          controller: noteController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: 'Status Update Notes (Optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF8A00)),
            child: const Text('UPDATE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final notes = noteController.text.trim().isNotEmpty ? noteController.text.trim() : 'Status changed to $newStatus.';
        await DatabaseService.updateOrderStatus(orderId, newStatus, notes);
        _showSuccessSnackBar('Order status updated.');
        _loadOrders();
      } catch (e) {
        _showErrorSnackBar('Failed to update status: $e');
      }
    }
  }

  Future<void> _cancelOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: const Text('Are you sure you want to cancel this order? This will mark it as cancelled on customer apps.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('CANCEL ORDER'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.cancelOrder(order.id);
        _showSuccessSnackBar('Order cancelled.');
        _loadOrders();
      } catch (e) {
        _showErrorSnackBar('Failed to cancel order: $e');
      }
    }
  }

  Future<void> _refundOrder(OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Refund'),
        content: const Text('Are you sure you want to approve a full refund? The payment status will be marked as Refunded.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.greenAccent),
            child: const Text('APPROVE REFUND'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await DatabaseService.approveRefund(order.id);
        _showSuccessSnackBar('Refund approved successfully.');
        _loadOrders();
      } catch (e) {
        _showErrorSnackBar('Failed to process refund: $e');
      }
    }
  }

  void _showOrderDetails(OrderModel order) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => Dialog(
          backgroundColor: const Color(0xFF150A2E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Container(
            width: 780,
            padding: const EdgeInsets.all(28),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Order details: ${order.id}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                      IconButton(icon: const Icon(Icons.close, color: Colors.white60), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Row of Details Panels
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 6,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Items Purchased', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFF8A00))),
                            const SizedBox(height: 12),
                            Table(
                              columnWidths: const {
                                0: FlexColumnWidth(4),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(2),
                              },
                              children: order.items.map((item) {
                                return TableRow(
                                  children: [
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(item.name, style: const TextStyle(fontSize: 13))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('x${item.quantity}', style: const TextStyle(fontSize: 13))),
                                    Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text('₹${item.price.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold))),
                                  ],
                                );
                              }).toList(),
                            ),
                            const Divider(color: Colors.white10, height: 28),
                            
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                Text('₹${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.greenAccent)),
                              ],
                            ),
                            const Divider(color: Colors.white10, height: 28),
                            
                            const Text('Delivery Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF8A00))),
                            const SizedBox(height: 8),
                            Text('Customer: ${order.customerName} (${order.customerEmail})', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Phone: ${order.customerPhone}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Address: ${order.deliveryAddress}', style: const TextStyle(fontSize: 13, height: 1.4)),
                            
                            const SizedBox(height: 24),
                            const Text('Payment Info', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF8A00))),
                            const SizedBox(height: 8),
                            Text('Method: ${order.paymentMethod}', style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Text('Status: ${order.paymentStatus}', style: TextStyle(color: order.paymentStatus == 'Paid' ? Colors.greenAccent : Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 28),
                      
                      Expanded(
                        flex: 4,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text('Order Timeline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFFF8A00))),
                            const SizedBox(height: 16),
                            
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: order.timeline.length,
                              itemBuilder: (context, idx) {
                                final event = order.timeline[idx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.circle, size: 8, color: Color(0xFFFF8A00)),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(event.status, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                            const SizedBox(height: 4),
                                            Text(event.notes, style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11)),
                                            const SizedBox(height: 2),
                                            Text(DateFormat('MMM d, h:mm a').format(event.timestamp), style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 9)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const Divider(color: Colors.white10, height: 40),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quick Update dropdown
                      Row(
                        children: [
                          const Text('Quick Update Status: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          DropdownButton<String>(
                            value: order.status,
                            dropdownColor: const Color(0xFF150A2E),
                            style: const TextStyle(color: Colors.white),
                            items: const [
                              DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                              DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                              DropdownMenuItem(value: 'Packed', child: Text('Packed')),
                              DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                              DropdownMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery')),
                              DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                Navigator.pop(context);
                                _updateStatus(order.id, val);
                              }
                            },
                          ),
                        ],
                      ),
                      
                      Row(
                        children: [
                          if (order.status != 'Cancelled' && order.status != 'Refunded')
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _cancelOrder(order);
                              },
                              icon: const Icon(Icons.cancel_rounded, size: 16),
                              label: const Text('CANCEL ORDER'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
                            ),
                          if (order.paymentStatus == 'Paid' && order.status != 'Refunded') ...[
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _refundOrder(order);
                              },
                              icon: const Icon(Icons.assignment_return_rounded, size: 16),
                              label: const Text('REFUND'),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.greenAccent, side: const BorderSide(color: Colors.greenAccent)),
                            ),
                          ],
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            onPressed: () => _printInvoice(order),
                            icon: const Icon(Icons.print_rounded, size: 16),
                            label: const Text('PRINT INVOICE'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00), foregroundColor: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _printInvoice(OrderModel order) {
    // Standard Javascript print triggers printing the screen contents
    // To make it look extremely premium, browser printing displays the window contents cleanly.
    web.window.print();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Order Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 6),
          Text('Process client order log workflows, adjust timeline events, process refund payouts, and print invoices', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
          const SizedBox(height: 28),
          
          // Filters
          Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                      _applyFilters();
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search by Order ID or Customer Name...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF8A00)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  dropdownColor: const Color(0xFF150A2E),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Status Filter',
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'All', child: Text('All Statuses')),
                    DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                    DropdownMenuItem(value: 'Confirmed', child: Text('Confirmed')),
                    DropdownMenuItem(value: 'Packed', child: Text('Packed')),
                    DropdownMenuItem(value: 'Shipped', child: Text('Shipped')),
                    DropdownMenuItem(value: 'Out for Delivery', child: Text('Out for Delivery')),
                    DropdownMenuItem(value: 'Delivered', child: Text('Delivered')),
                    DropdownMenuItem(value: 'Cancelled', child: Text('Cancelled')),
                    DropdownMenuItem(value: 'Refunded', child: Text('Refunded')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _statusFilter = val;
                        _applyFilters();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))))
                : _filteredOrders.isEmpty
                    ? const Center(child: Text('No orders matching the status found.', style: TextStyle(color: Colors.white38)))
                    : GlassCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                cardColor: Colors.transparent,
                                dividerColor: Colors.white10,
                              ),
                              child: DataTable(
                                columns: const [
                                  DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _filteredOrders.map((ord) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(ord.id)),
                                      DataCell(Text(ord.customerName)),
                                      DataCell(Text('₹${ord.totalAmount.toStringAsFixed(2)}')),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: ord.status == 'Delivered'
                                                ? Colors.green.withValues(alpha: 0.15)
                                                : ord.status == 'Cancelled' || ord.status == 'Refunded'
                                                    ? Colors.red.withValues(alpha: 0.15)
                                                    : Colors.orange.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            ord.status,
                                            style: TextStyle(
                                              color: ord.status == 'Delivered'
                                                  ? Colors.greenAccent
                                                  : ord.status == 'Cancelled' || ord.status == 'Refunded'
                                                      ? Colors.redAccent
                                                      : Colors.orangeAccent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(ord.paymentStatus, style: TextStyle(fontWeight: FontWeight.bold, color: ord.paymentStatus == 'Paid' ? Colors.greenAccent : Colors.orangeAccent))),
                                      DataCell(Text(DateFormat('yMMMd').format(ord.createdDate))),
                                      DataCell(
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.visibility_rounded, color: Colors.blueAccent, size: 18),
                                              onPressed: () => _showOrderDetails(ord),
                                              tooltip: 'View details',
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.print_rounded, color: Colors.white70, size: 18),
                                              onPressed: () => _printInvoice(ord),
                                              tooltip: 'Print Invoice',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
