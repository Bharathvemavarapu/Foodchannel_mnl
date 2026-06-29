import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../services/database_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../models/user.dart';
import '../../../models/order.dart';
import '../../../models/payment.dart';
import '../../../models/support_ticket.dart';
import '../../../models/product.dart';

class DashboardTab extends StatefulWidget {
  final Function(int)? onTabChanged;
  const DashboardTab({super.key, this.onTabChanged});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  int _categoryCount = 0;
  int _productCount = 0;
  int _outOfStockProductsCount = 0;

  int _totalUsers = 0;
  int _activeUsers = 0;
  int _blockedUsers = 0;

  int _totalOrders = 0;
  int _pendingOrders = 0;
  int _completedOrders = 0;

  double _totalRevenue = 0.0;
  double _todayRevenue = 0.0;
  double _monthlyRevenue = 0.0;

  int _pendingSupportTickets = 0;
  int _totalSupportTickets = 0;
  int _failedTransactions = 0;

  List<OrderModel> _recentOrders = [];
  List<UserModel> _recentUsers = [];
  List<PaymentTransactionModel> _recentPayments = [];
  List<SupportTicketModel> _recentSupportTickets = [];

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMetrics();
  }

  Future<void> _loadMetrics() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await DatabaseService.checkAndPrepopulateDatabase();
      final results = await Future.wait([
        DatabaseService.getCategories(),
        DatabaseService.getSubCategories(),
        DatabaseService.getProducts(),
        DatabaseService.getBanners(),
        DatabaseService.getHeroImages(),
        DatabaseService.getUsers(),
        DatabaseService.getOrders(),
        DatabaseService.getTransactions(),
        DatabaseService.getSupportTickets(),
      ]);

      if (mounted) {
        final categories = results[0] as List;
        final products = results[2] as List<ProductModel>;
        final users = results[5] as List<UserModel>;
        final orders = results[6] as List<OrderModel>;
        final transactions = results[7] as List<PaymentTransactionModel>;
        final tickets = results[8] as List<SupportTicketModel>;

        setState(() {
          _categoryCount = categories.length;
          _productCount = products.length;
          _outOfStockProductsCount = products.where((p) => p.stock <= 0).length;

          _totalUsers = users.length;
          _activeUsers = users.where((u) => u.isActive).length;
          _blockedUsers = users.where((u) => !u.isActive).length;

          _totalOrders = orders.length;
          _pendingOrders = orders.where((o) => o.status == 'Pending' || o.status == 'Confirmed' || o.status == 'Packed').length;
          _completedOrders = orders.where((o) => o.status == 'Delivered').length;

          double totRev = 0.0;
          double todRev = 0.0;
          double monRev = 0.0;
          final now = DateTime.now();

          for (var o in orders) {
            if (o.status != 'Cancelled' && o.status != 'Refunded') {
              totRev += o.totalAmount;
              if (o.createdDate.year == now.year && o.createdDate.month == now.month && o.createdDate.day == now.day) {
                todRev += o.totalAmount;
              }
              if (o.createdDate.year == now.year && o.createdDate.month == now.month) {
                monRev += o.totalAmount;
              }
            }
          }
          _totalRevenue = totRev;
          _todayRevenue = todRev;
          _monthlyRevenue = monRev;

          _totalSupportTickets = tickets.length;
          _pendingSupportTickets = tickets.where((t) => t.status == 'Open' || t.status == 'In Progress').length;
          _failedTransactions = transactions.where((t) => t.status == 'Failed').length;

          final sortedOrders = List<OrderModel>.from(orders)
            ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
          _recentOrders = sortedOrders.take(5).toList();

          final sortedUsers = List<UserModel>.from(users)
            ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
          _recentUsers = sortedUsers.take(5).toList();

          final sortedTxs = List<PaymentTransactionModel>.from(transactions)
            ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
          _recentPayments = sortedTxs.take(5).toList();

          final sortedTickets = List<SupportTicketModel>.from(tickets)
            ..sort((a, b) => b.createdDate.compareTo(a.createdDate));
          _recentSupportTickets = sortedTickets.take(5).toList();

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load metrics: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
      );
    }

    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dashboard Header Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin Overview',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Live statistics from your Foodchannel_mnl platform.',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFFFF8A00)),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _loadMetrics,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('REFRESH STATS', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00).withValues(alpha: 0.15),
                  foregroundColor: const Color(0xFFFF8A00),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  side: const BorderSide(color: Color(0xFFFF8A00), width: 1.0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Row 1 Statistics Grid
          const Text(
            'Row 1: Platform Catalog & Activity',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: width > 1200 ? 4 : width > 768 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: width > 1200 ? 1.6 : 2.0,
            children: [
              _buildMetricCard('Total Users', '$_totalUsers', Icons.people_rounded, Colors.purpleAccent,
                  onTap: () => widget.onTabChanged?.call(8)),
              _buildMetricCard('Active Users', '$_activeUsers', Icons.person_add_alt_1_rounded, Colors.pinkAccent,
                  onTap: () => widget.onTabChanged?.call(8)),
              _buildMetricCard('Total Categories', '$_categoryCount', Icons.category_rounded, const Color(0xFFDA1B60),
                  onTap: () => widget.onTabChanged?.call(1)),
              _buildMetricCard('Total Products', '$_productCount', Icons.shopping_basket_rounded, const Color(0xFFFF8A00),
                  onTap: () => widget.onTabChanged?.call(3)),
            ],
          ),
          const SizedBox(height: 28),

          // Row 2 Statistics Grid
          const Text(
            'Row 2: Sales & Financial Overview',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: width > 1200 ? 4 : width > 768 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: width > 1200 ? 1.6 : 2.0,
            children: [
              _buildMetricCard('Total Orders', '$_totalOrders', Icons.shopping_cart_rounded, Colors.blueAccent,
                  onTap: () => widget.onTabChanged?.call(9)),
              _buildMetricCard('Pending Orders', '$_pendingOrders', Icons.hourglass_empty_rounded, Colors.orangeAccent,
                  onTap: () => widget.onTabChanged?.call(9)),
              _buildMetricCard('Completed Orders', '$_completedOrders', Icons.check_circle_outline_rounded, Colors.lightGreenAccent,
                  onTap: () => widget.onTabChanged?.call(9)),
              _buildMetricCard('Total Revenue', '₹${_totalRevenue.toStringAsFixed(0)}', Icons.currency_rupee_rounded, Colors.greenAccent,
                  onTap: () => widget.onTabChanged?.call(10)),
            ],
          ),
          const SizedBox(height: 28),

          // Row 3: Advanced Cards & Widgets
          const Text(
            'Row 3: Advanced Dashboard Panels',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = width > 1100;
              return isWide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 4, child: _buildCalendarAndEventsCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: _buildSupportServiceCard()),
                        const SizedBox(width: 20),
                        Expanded(flex: 3, child: _buildAlertsWarningsCard()),
                      ],
                    )
                  : Column(
                      children: [
                        _buildCalendarAndEventsCard(),
                        const SizedBox(height: 20),
                        _buildSupportServiceCard(),
                        const SizedBox(height: 20),
                        _buildAlertsWarningsCard(),
                      ],
                    );
            },
          ),
          const SizedBox(height: 28),

          // Row 4: Detailed Revenues Grid
          const Text(
            'Row 4: Additional Detailed Metrics',
            style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: width > 1200 ? 2 : 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: width > 1200 ? 3.0 : 4.0,
            children: [
              _buildMetricCard('Today\'s Revenue', '₹${_todayRevenue.toStringAsFixed(0)}', Icons.today_rounded, Colors.amberAccent,
                  onTap: () => widget.onTabChanged?.call(10)),
              _buildMetricCard('Monthly Revenue', '₹${_monthlyRevenue.toStringAsFixed(0)}', Icons.trending_up_rounded, Colors.tealAccent,
                  onTap: () => widget.onTabChanged?.call(10)),
            ],
          ),
          const SizedBox(height: 40),

          // Recent Activities Section (Recent Orders & Support Tickets)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Orders
              Expanded(
                flex: 5,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Orders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Icon(Icons.shopping_cart_checkout_rounded, color: Colors.blueAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_recentOrders.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No orders recorded.',
                              style: TextStyle(color: Colors.white24, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentOrders.length,
                          itemBuilder: (context, idx) {
                            final ord = _recentOrders[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(ord.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text(
                                'ID: ${ord.id.substring(0, ord.id.length > 8 ? 8 : ord.id.length)}... • Status: ${ord.status}',
                                style: const TextStyle(fontSize: 11),
                              ),
                              trailing: Text(
                                '₹${ord.totalAmount.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.greenAccent, fontSize: 13),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Recent Support Tickets
              Expanded(
                flex: 5,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Support Tickets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Icon(Icons.support_agent_rounded, color: Colors.redAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_recentSupportTickets.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No tickets open.',
                              style: TextStyle(color: Colors.white24, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentSupportTickets.length,
                          itemBuilder: (context, idx) {
                            final ticket = _recentSupportTickets[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                ticket.subject,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text('${ticket.customerName} • ${ticket.type}', style: const TextStyle(fontSize: 11)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  ticket.status,
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Row for Recent Users & Recent Transactions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Recent Users
              Expanded(
                flex: 5,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Users', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Icon(Icons.people_alt_rounded, color: Colors.purpleAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_recentUsers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No registered users.',
                              style: TextStyle(color: Colors.white24, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentUsers.length,
                          itemBuilder: (context, idx) {
                            final u = _recentUsers[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(u.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                              subtitle: Text('${u.email} • Role: ${u.role}', style: const TextStyle(fontSize: 11)),
                              trailing: Text(
                                u.isActive ? 'Active' : 'Blocked',
                                style: TextStyle(
                                  color: u.isActive ? Colors.greenAccent : Colors.redAccent,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),

              // Recent Transactions
              Expanded(
                flex: 5,
                child: GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Recent Transactions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Icon(Icons.monetization_on_rounded, color: Colors.greenAccent, size: 20),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_recentPayments.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'No transaction logs.',
                              style: TextStyle(color: Colors.white24, fontSize: 13),
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentPayments.length,
                          itemBuilder: (context, idx) {
                            final tx = _recentPayments[idx];
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                'Tx: ${tx.transactionId.substring(0, tx.transactionId.length > 8 ? 8 : tx.transactionId.length)}...',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              subtitle: Text('${tx.customerName} • ${tx.gateway}', style: const TextStyle(fontSize: 11)),
                              trailing: Text(
                                tx.status,
                                style: TextStyle(
                                  color: tx.status == 'Success' ? Colors.greenAccent : Colors.redAccent,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                ],
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Row 3 Components ---

  Widget _buildCalendarAndEventsCard() {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstDayOffset = DateTime(now.year, now.month, 1).weekday % 7;
    final weekDays = ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa'];

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Calendar & Events', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(
                DateFormat('MMMM yyyy').format(now),
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFFFF8A00)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Day initials header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekDays
                .map((d) => SizedBox(
                      width: 24,
                      child: Text(
                        d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white30, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 6),
          // Calendar Grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              childAspectRatio: 1.0,
            ),
            itemCount: daysInMonth + firstDayOffset,
            itemBuilder: (context, index) {
              if (index < firstDayOffset) {
                return const SizedBox();
              }
              final day = index - firstDayOffset + 1;
              final isToday = day == now.day;

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isToday ? const Color(0xFFFF8A00) : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$day',
                  style: TextStyle(
                    color: isToday ? Colors.white : Colors.white70,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    fontSize: 11,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          const Text('Upcoming Schedules', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 8),
          _buildEventItem('Farmer Harvest Pickups', '09:00 AM • Batch #14', Colors.purpleAccent),
          _buildEventItem('Category Sale Campaign Start', '12:00 PM • Marketing', Colors.greenAccent),
          _buildEventItem('Platform Weekly Server Sync', 'Tomorrow • Operations', Colors.orangeAccent),
        ],
      ),
    );
  }

  Widget _buildEventItem(String title, String subtitle, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white70)),
                Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportServiceCard() {
    final double resolveRate = _totalSupportTickets > 0
        ? ((_totalSupportTickets - _pendingSupportTickets) / _totalSupportTickets) * 100
        : 100.0;

    return GestureDetector(
      onTap: () => widget.onTabChanged?.call(11),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Support & Service', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.support_agent_rounded, color: Colors.redAccent, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: resolveRate / 100,
                    strokeWidth: 8,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    valueColor: const AlwaysStoppedAnimation(Colors.redAccent),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${resolveRate.toStringAsFixed(0)}%',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text('Resolved', style: TextStyle(fontSize: 9, color: Colors.white38)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildStatRow('Total Inquiries', '$_totalSupportTickets', Colors.white70),
          const SizedBox(height: 8),
          _buildStatRow('Pending Actions', '$_pendingSupportTickets', Colors.orangeAccent),
          const SizedBox(height: 8),
          _buildStatRow('Avg. Response Time', '14 mins', Colors.greenAccent),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          const Text(
            'Admins are advised to respond to support tickets within 24 hours to keep high ratings.',
            style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildStatRow(String label, String val, Color valColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white54)),
        Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: valColor)),
      ],
    );
  }

  Widget _buildAlertsWarningsCard() {
    final hasAlerts = _outOfStockProductsCount > 0 || _blockedUsers > 0 || _failedTransactions > 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Alerts & Warnings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Icon(Icons.warning_amber_rounded, color: Colors.amberAccent, size: 18),
            ],
          ),
          const SizedBox(height: 20),
          if (!hasAlerts)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(Icons.check_circle_outline_rounded, color: Colors.greenAccent, size: 36),
                    SizedBox(height: 10),
                    Text('System status normal.', style: TextStyle(fontSize: 12, color: Colors.white60)),
                  ],
                ),
              ),
            )
          else
            Column(
              children: [
                if (_outOfStockProductsCount > 0)
                  _buildAlertTile(
                    '$_outOfStockProductsCount Products Out of Stock',
                    'Replenish inventory to restore sales.',
                    Icons.inventory_2_outlined,
                    Colors.orangeAccent,
                    onTap: () => widget.onTabChanged?.call(3),
                  ),
                if (_blockedUsers > 0)
                  _buildAlertTile(
                    '$_blockedUsers Accounts Deactivated',
                    'Users currently blocked from login.',
                    Icons.block_outlined,
                    Colors.redAccent,
                    onTap: () => widget.onTabChanged?.call(8),
                  ),
                if (_failedTransactions > 0)
                  _buildAlertTile(
                    '$_failedTransactions Failed Payments',
                    'Failed gateways logs require checking.',
                    Icons.error_outline_rounded,
                    Colors.amberAccent,
                    onTap: () => widget.onTabChanged?.call(10),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white10),
          const SizedBox(height: 8),
          const Text(
            'Click on Products or Users tabs in the sidebar to review warnings and resolve alerts.',
            style: TextStyle(color: Colors.white24, fontSize: 10, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertTile(String title, String description, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text(description, style: const TextStyle(fontSize: 10, color: Colors.white38)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
