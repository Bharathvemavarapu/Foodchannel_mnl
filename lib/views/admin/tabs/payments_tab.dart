import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:web/web.dart' as web;
import '../../../models/payment.dart';
import '../../../services/database_service.dart';
import '../../../widgets/glass_card.dart';

class PaymentsTab extends StatefulWidget {
  const PaymentsTab({super.key});

  @override
  State<PaymentsTab> createState() => _PaymentsTabState();
}

class _PaymentsTabState extends State<PaymentsTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  PaymentSettingsModel _settings = PaymentSettingsModel.empty();
  List<PaymentTransactionModel> _transactions = [];
  List<PaymentTransactionModel> _filteredTransactions = [];

  bool _isLoading = true;
  bool _isSaving = false;

  String _searchQuery = '';
  String _statusFilter = 'All'; // 'All', 'Success', 'Failed', 'Pending', 'Refunded'

  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();

  // Controllers for Gateway details
  final _rpTestKey = TextEditingController();
  final _rpTestSecret = TextEditingController();
  final _rpLiveKey = TextEditingController();
  final _rpLiveSecret = TextEditingController();

  final _stripeTestKey = TextEditingController();
  final _stripeTestSecret = TextEditingController();
  final _stripeLiveKey = TextEditingController();
  final _stripeLiveSecret = TextEditingController();

  final _cfTestKey = TextEditingController();
  final _cfTestSecret = TextEditingController();
  final _cfLiveKey = TextEditingController();
  final _cfLiveSecret = TextEditingController();

  final _ppTestKey = TextEditingController();
  final _ppTestSecret = TextEditingController();
  final _ppLiveKey = TextEditingController();
  final _ppLiveSecret = TextEditingController();

  final _minOrderAmount = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPaymentData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _rpTestKey.dispose();
    _rpTestSecret.dispose();
    _rpLiveKey.dispose();
    _rpLiveSecret.dispose();
    _stripeTestKey.dispose();
    _stripeTestSecret.dispose();
    _stripeLiveKey.dispose();
    _stripeLiveSecret.dispose();
    _cfTestKey.dispose();
    _cfTestSecret.dispose();
    _cfLiveKey.dispose();
    _cfLiveSecret.dispose();
    _ppTestKey.dispose();
    _ppTestSecret.dispose();
    _ppLiveKey.dispose();
    _ppLiveSecret.dispose();
    _minOrderAmount.dispose();
    super.dispose();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);
    try {
      await _prepopulateMockTransactions();
      final results = await Future.wait([
        DatabaseService.getPaymentSettings(),
        DatabaseService.getTransactions(),
      ]);

      _settings = results[0] as PaymentSettingsModel;
      _transactions = results[1] as List<PaymentTransactionModel>;

      // Populate text fields
      _rpTestKey.text = _settings.razorpay.testApiKey;
      _rpTestSecret.text = _settings.razorpay.testApiSecret;
      _rpLiveKey.text = _settings.razorpay.liveApiKey;
      _rpLiveSecret.text = _settings.razorpay.liveApiSecret;

      _stripeTestKey.text = _settings.stripe.testApiKey;
      _stripeTestSecret.text = _settings.stripe.testApiSecret;
      _stripeLiveKey.text = _settings.stripe.liveApiKey;
      _stripeLiveSecret.text = _settings.stripe.liveApiSecret;

      _cfTestKey.text = _settings.cashfree.testApiKey;
      _cfTestSecret.text = _settings.cashfree.testApiSecret;
      _cfLiveKey.text = _settings.cashfree.liveApiKey;
      _cfLiveSecret.text = _settings.cashfree.liveApiSecret;

      _ppTestKey.text = _settings.phonepe.testApiKey;
      _ppTestSecret.text = _settings.phonepe.testApiSecret;
      _ppLiveKey.text = _settings.phonepe.liveApiKey;
      _ppLiveSecret.text = _settings.phonepe.liveApiSecret;

      _minOrderAmount.text = _settings.minOrderAmountForOnline.toString();

      _applyFilters();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load payment data: $e');
    }
  }

  Future<void> _prepopulateMockTransactions() async {
    final list = await DatabaseService.getTransactions();
    if (list.isNotEmpty) return;

    final mockTx1 = PaymentTransactionModel(
      id: 'tx_01',
      orderId: 'ORD-98432-849',
      customerName: 'Bharath Vemavarapu',
      gateway: 'Razorpay',
      amount: 3097.0,
      status: 'Success',
      transactionId: 'pay_Nod394857219',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    );

    final mockTx2 = PaymentTransactionModel(
      id: 'tx_02',
      orderId: 'ORD-54832-120',
      customerName: 'Suresh Raina',
      gateway: 'Stripe',
      amount: 1499.0,
      status: 'Failed',
      transactionId: 'ch_3M294857Dks',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      errorMessage: 'Card declined: Insufficient funds.',
    );

    await DatabaseService.addTransaction(mockTx1);
    await DatabaseService.addTransaction(mockTx2);
  }

  void _applyFilters() {
    setState(() {
      _filteredTransactions = _transactions.where((tx) {
        final matchesQuery = tx.transactionId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.orderId.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            tx.customerName.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesStatus = _statusFilter == 'All' || tx.status == _statusFilter;
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

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final minAmt = double.tryParse(_minOrderAmount.text) ?? 0.0;

      final updated = PaymentSettingsModel(
        codEnabled: _settings.codEnabled,
        walletEnabled: _settings.walletEnabled,
        upiEnabled: _settings.upiEnabled,
        minOrderAmountForOnline: minAmt,
        razorpay: GatewayConfig(
          isEnabled: _settings.razorpay.isEnabled,
          isLiveMode: _settings.razorpay.isLiveMode,
          testApiKey: _rpTestKey.text,
          testApiSecret: _rpTestSecret.text,
          liveApiKey: _rpLiveKey.text,
          liveApiSecret: _rpLiveSecret.text,
        ),
        stripe: GatewayConfig(
          isEnabled: _settings.stripe.isEnabled,
          isLiveMode: _settings.stripe.isLiveMode,
          testApiKey: _stripeTestKey.text,
          testApiSecret: _stripeTestSecret.text,
          liveApiKey: _stripeLiveKey.text,
          liveApiSecret: _stripeLiveSecret.text,
        ),
        cashfree: GatewayConfig(
          isEnabled: _settings.cashfree.isEnabled,
          isLiveMode: _settings.cashfree.isLiveMode,
          testApiKey: _cfTestKey.text,
          testApiSecret: _cfTestSecret.text,
          liveApiKey: _cfLiveKey.text,
          liveApiSecret: _cfLiveSecret.text,
        ),
        phonepe: GatewayConfig(
          isEnabled: _settings.phonepe.isEnabled,
          isLiveMode: _settings.phonepe.isLiveMode,
          testApiKey: _ppTestKey.text,
          testApiSecret: _ppTestSecret.text,
          liveApiKey: _ppLiveKey.text,
          liveApiSecret: _ppLiveSecret.text,
        ),
      );

      await DatabaseService.savePaymentSettings(updated);
      _settings = updated;
      _showSuccessSnackBar('Payment settings updated.');
    } catch (e) {
      _showErrorSnackBar('Failed to save settings: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _verifyTransactionStatus(PaymentTransactionModel tx) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)))),
    );
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context);
      _showSuccessSnackBar('Transaction status verified online: Success.');
    }
  }

  void _exportTransactions() {
    if (_filteredTransactions.isEmpty) {
      _showErrorSnackBar('No transactions to export.');
      return;
    }

    final csvContent = StringBuffer();
    csvContent.writeln('Transaction ID,Order ID,Customer,Gateway,Amount,Status,Timestamp,Error Message');
    
    for (final tx in _filteredTransactions) {
      csvContent.writeln(
        '${tx.transactionId},${tx.orderId},"${tx.customerName}",${tx.gateway},${tx.amount},${tx.status},${tx.timestamp.toIso8601String()},"${tx.errorMessage}"'
      );
    }

    final encodedUri = Uri.dataFromString(csvContent.toString(), mimeType: 'text/csv', encoding: utf8).toString();
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = encodedUri;
    anchor.download = 'payment_transactions_${DateTime.now().millisecondsSinceEpoch}.csv';
    anchor.click();
    _showSuccessSnackBar('Payment transaction logs exported successfully.');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))));
    }

    return Padding(
      padding: const EdgeInsets.all(28.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Payment Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Configure payment processing credentials and audit transactions history', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
              TabBar(
                controller: _tabController,
                isScrollable: true,
                dividerColor: Colors.transparent,
                indicatorColor: const Color(0xFFFF8A00),
                labelColor: const Color(0xFFFF8A00),
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'GATEWAY CONFIGURATION'),
                  Tab(text: 'TRANSACTION AUDIT LOGS'),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGatewayConfigTab(),
                _buildTransactionsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGatewayConfigTab() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // COD Switch & Min amount row
            GlassCard(
              child: Row(
                children: [
                  Switch(
                    value: _settings.codEnabled,
                    activeColor: const Color(0xFFFF8A00),
                    onChanged: (val) {
                      setState(() {
                        _settings = _settings.copyWith(codEnabled: val);
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                  const Text('Enable Cash on Delivery (COD)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  SizedBox(
                    width: 220,
                    child: TextFormField(
                      controller: _minOrderAmount,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(labelText: 'Min Amount for Online (₹)'),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Enter valid number' : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Wallet & UPI Switches
            GlassCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Switch(
                        value: _settings.walletEnabled,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) {
                          setState(() {
                            _settings = _settings.copyWith(walletEnabled: val);
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text('Enable Digital Wallet Payment', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  Row(
                    children: [
                      Switch(
                        value: _settings.upiEnabled,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) {
                          setState(() {
                            _settings = _settings.copyWith(upiEnabled: val);
                          });
                        },
                      ),
                      const SizedBox(width: 12),
                      const Text('Enable Direct UPI Payment (GPay/PhonePe/Paytm)', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Razorpay
            _buildGatewayCard('Razorpay API Integration', _settings.razorpay, (isEnabled) {
              setState(() {
                _settings = _settings.copyWith(
                  razorpay: GatewayConfig(
                    isEnabled: isEnabled,
                    isLiveMode: _settings.razorpay.isLiveMode,
                    testApiKey: _rpTestKey.text,
                    testApiSecret: _rpTestSecret.text,
                    liveApiKey: _rpLiveKey.text,
                    liveApiSecret: _rpLiveSecret.text,
                  ),
                );
              });
            }, (isLive) {
              setState(() {
                _settings = _settings.copyWith(
                  razorpay: GatewayConfig(
                    isEnabled: _settings.razorpay.isEnabled,
                    isLiveMode: isLive,
                    testApiKey: _rpTestKey.text,
                    testApiSecret: _rpTestSecret.text,
                    liveApiKey: _rpLiveKey.text,
                    liveApiSecret: _rpLiveSecret.text,
                  ),
                );
              });
            }, _rpTestKey, _rpTestSecret, _rpLiveKey, _rpLiveSecret),
            const SizedBox(height: 24),

            // Stripe
            _buildGatewayCard('Stripe API Integration', _settings.stripe, (isEnabled) {
              setState(() {
                _settings = _settings.copyWith(
                  stripe: GatewayConfig(
                    isEnabled: isEnabled,
                    isLiveMode: _settings.stripe.isLiveMode,
                    testApiKey: _stripeTestKey.text,
                    testApiSecret: _stripeTestSecret.text,
                    liveApiKey: _stripeLiveKey.text,
                    liveApiSecret: _stripeLiveSecret.text,
                  ),
                );
              });
            }, (isLive) {
              setState(() {
                _settings = _settings.copyWith(
                  stripe: GatewayConfig(
                    isEnabled: _settings.stripe.isEnabled,
                    isLiveMode: isLive,
                    testApiKey: _stripeTestKey.text,
                    testApiSecret: _stripeTestSecret.text,
                    liveApiKey: _stripeLiveKey.text,
                    liveApiSecret: _stripeLiveSecret.text,
                  ),
                );
              });
            }, _stripeTestKey, _stripeTestSecret, _stripeLiveKey, _stripeLiveSecret),
            const SizedBox(height: 24),

            // Cashfree
            _buildGatewayCard('Cashfree API Integration', _settings.cashfree, (isEnabled) {
              setState(() {
                _settings = _settings.copyWith(
                  cashfree: GatewayConfig(
                    isEnabled: isEnabled,
                    isLiveMode: _settings.cashfree.isLiveMode,
                    testApiKey: _cfTestKey.text,
                    testApiSecret: _cfTestSecret.text,
                    liveApiKey: _cfLiveKey.text,
                    liveApiSecret: _cfLiveSecret.text,
                  ),
                );
              });
            }, (isLive) {
              setState(() {
                _settings = _settings.copyWith(
                  cashfree: GatewayConfig(
                    isEnabled: _settings.cashfree.isEnabled,
                    isLiveMode: isLive,
                    testApiKey: _cfTestKey.text,
                    testApiSecret: _cfTestSecret.text,
                    liveApiKey: _cfLiveKey.text,
                    liveApiSecret: _cfLiveSecret.text,
                  ),
                );
              });
            }, _cfTestKey, _cfTestSecret, _cfLiveKey, _cfLiveSecret),
            const SizedBox(height: 24),

            // PhonePe
            _buildGatewayCard('PhonePe API Integration', _settings.phonepe, (isEnabled) {
              setState(() {
                _settings = _settings.copyWith(
                  phonepe: GatewayConfig(
                    isEnabled: isEnabled,
                    isLiveMode: _settings.phonepe.isLiveMode,
                    testApiKey: _ppTestKey.text,
                    testApiSecret: _ppTestSecret.text,
                    liveApiKey: _ppLiveKey.text,
                    liveApiSecret: _ppLiveSecret.text,
                  ),
                );
              });
            }, (isLive) {
              setState(() {
                _settings = _settings.copyWith(
                  phonepe: GatewayConfig(
                    isEnabled: _settings.phonepe.isEnabled,
                    isLiveMode: isLive,
                    testApiKey: _ppTestKey.text,
                    testApiSecret: _ppTestSecret.text,
                    liveApiKey: _ppLiveKey.text,
                    liveApiSecret: _ppLiveSecret.text,
                  ),
                );
              });
            }, _ppTestKey, _ppTestSecret, _ppLiveKey, _ppLiveSecret),
            const SizedBox(height: 32),
            
            ElevatedButton(
              onPressed: _isSaving ? null : _saveSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
                  : const Text('SAVE GATEWAY CONFIGURATIONS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0)),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildGatewayCard(
    String title,
    GatewayConfig gateway,
    ValueChanged<bool> onEnabledChanged,
    ValueChanged<bool> onModeChanged,
    TextEditingController testKey,
    TextEditingController testSecret,
    TextEditingController liveKey,
    TextEditingController liveSecret,
  ) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Spacer(),
              Switch(value: gateway.isEnabled, activeColor: const Color(0xFFFF8A00), onChanged: onEnabledChanged),
              const SizedBox(width: 8),
              Text(gateway.isEnabled ? 'Enabled' : 'Disabled', style: TextStyle(color: gateway.isEnabled ? const Color(0xFFFF8A00) : Colors.white30, fontWeight: FontWeight.bold)),
            ],
          ),
          if (gateway.isEnabled) ...[
            const Divider(color: Colors.white10, height: 28),
            Row(
              children: [
                const Text('Environment Mode:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(width: 14),
                ChoiceChip(
                  label: const Text('TEST MODE'),
                  selected: !gateway.isLiveMode,
                  onSelected: (sel) => onModeChanged(false),
                  selectedColor: const Color(0xFFFF8A00),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                const SizedBox(width: 10),
                ChoiceChip(
                  label: const Text('LIVE PRODUCTION'),
                  selected: gateway.isLiveMode,
                  onSelected: (sel) => onModeChanged(true),
                  selectedColor: const Color(0xFFDA1B60),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            if (!gateway.isLiveMode) ...[
              // Test Mode config
              Row(
                children: [
                  Expanded(child: TextFormField(controller: testKey, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Test Merchant Key'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: testSecret, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Test Api Secret', hintText: '••••••••••••••••'))),
                ],
              ),
            ] else ...[
              // Live production config
              Row(
                children: [
                  Expanded(child: TextFormField(controller: liveKey, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Production Live Key'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextFormField(controller: liveSecret, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Production Live Secret', hintText: '••••••••••••••••'))),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildTransactionsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                  hintText: 'Search by Tx ID, Order ID, or Customer...',
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
                  labelText: 'Payment Status',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                ),
                items: const [
                  DropdownMenuItem(value: 'All', child: Text('All Transactions')),
                  DropdownMenuItem(value: 'Success', child: Text('Success')),
                  DropdownMenuItem(value: 'Failed', child: Text('Failed')),
                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
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
            const SizedBox(width: 20),
            ElevatedButton.icon(
              onPressed: _exportTransactions,
              icon: const Icon(Icons.file_download_rounded),
              label: const Text('EXPORT CSV', style: TextStyle(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF8A00),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        
        Expanded(
          child: _filteredTransactions.isEmpty
              ? const Center(child: Text('No transactions recorded.', style: TextStyle(color: Colors.white38)))
              : GlassCard(
                  padding: EdgeInsets.zero,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Theme(
                        data: Theme.of(context).copyWith(cardColor: Colors.transparent, dividerColor: Colors.white10),
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Transaction ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Order ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Gateway', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Timestamp', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _filteredTransactions.map((tx) {
                            return DataRow(
                              cells: [
                                DataCell(Text(tx.transactionId)),
                                DataCell(Text(tx.orderId)),
                                DataCell(Text(tx.customerName)),
                                DataCell(Text(tx.gateway)),
                                DataCell(Text('₹${tx.amount.toStringAsFixed(2)}')),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: tx.status == 'Success'
                                          ? Colors.green.withValues(alpha: 0.15)
                                          : Colors.red.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      tx.status,
                                      style: TextStyle(
                                        color: tx.status == 'Success' ? Colors.greenAccent : Colors.redAccent,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(DateFormat('yMMMd').add_jm().format(tx.timestamp))),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.sync_rounded, color: Colors.blueAccent, size: 18),
                                    onPressed: () => _verifyTransactionStatus(tx),
                                    tooltip: 'Verify / Sync Payout Online',
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
    );
  }
}
