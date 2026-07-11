import 'package:flutter/material.dart';
import '../../models/order.dart';
import '../../models/address.dart';
import '../../models/payment.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/glass_card.dart';
import 'address_book_view.dart';
import 'payment_processing_view.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import '../../services/location_service.dart';
import '../../models/promo_code.dart';
class CheckoutView extends StatefulWidget {
  const CheckoutView({super.key});

  @override
  State<CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<CheckoutView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _couponController = TextEditingController();

  String _paymentMethod = 'Cash on Delivery';
  UserAddressModel? _selectedAddress;
  bool _isLoading = true;
  bool _isLoadingLocation = false;
  bool _isSubmitting = false;
  PaymentSettingsModel? _paymentSettings;
  PromoCodeModel? _appliedPromo;
  double _discountAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndProfile() async {
    final user = AuthService.currentUser;
    if (user != null) {
      try {
        final profile = await AuthService.getUserProfile(user.uid);
        if (profile != null) {
          _nameController.text = profile.name;
          _phoneController.text = profile.phone;
          _addressController.text = profile.address;
        }

        // Load Gateway settings
        final settings = await DatabaseService.getPaymentSettings();
        setState(() {
          _paymentSettings = settings;
          if (!settings.codEnabled) {
            // Find first enabled gateway
            if (settings.walletEnabled) _paymentMethod = 'Wallet';
            else if (settings.upiEnabled) _paymentMethod = 'UPI';
            else if (settings.razorpay.isEnabled) _paymentMethod = 'Razorpay';
            else if (settings.stripe.isEnabled) _paymentMethod = 'Stripe';
            else if (settings.phonepe.isEnabled) _paymentMethod = 'PhonePe';
            else if (settings.cashfree.isEnabled) _paymentMethod = 'Cashfree';
          }
        });
      } catch (_) {}
    }
    setState(() => _isLoading = false);
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showErrorSnackBar('Location services are disabled. Please enable them.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorSnackBar('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorSnackBar('Location permissions are permanently denied.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final addressDetails = await LocationService.instance.reverseGeocode(position.latitude, position.longitude);

      setState(() {
        _addressController.text = addressDetails.fullAddress;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location found!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      _showErrorSnackBar('Error getting location: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingLocation = false);
      }
    }
  }

  Future<void> _applyPromoCode() async {
    final codeText = _couponController.text.trim();
    if (codeText.isEmpty) return;

    try {
      final promoCodes = await DatabaseService.getPromoCodes();
      final subtotal = CartService.instance.totalAmount;
      final promo = promoCodes.firstWhere(
        (p) => p.code.toLowerCase() == codeText.toLowerCase(),
        orElse: () => PromoCodeModel(code: '', discountPercentage: 0, minOrderAmount: 0, isActive: false),
      );

      if (promo.code.isEmpty) {
        _showErrorSnackBar('Invalid promo code');
        return;
      }
      if (!promo.isActive) {
        _showErrorSnackBar('This promo code is no longer active');
        return;
      }
      if (subtotal < promo.minOrderAmount) {
        _showErrorSnackBar('Minimum order amount of ₹${promo.minOrderAmount.toInt()} required for this code');
        return;
      }

      setState(() {
        _appliedPromo = promo;
        _discountAmount = (subtotal * promo.discountPercentage) / 100.0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Promo code applied! Discount: ${promo.discountPercentage.toInt()}%'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      _showErrorSnackBar('Failed to apply promo code: $e');
    }
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    final user = AuthService.currentUser;
    if (user == null) return;

    final cartItems = CartService.instance.items;
    if (cartItems.isEmpty) return;

    final subtotal = CartService.instance.totalAmount;
    final totalAmount = subtotal - _discountAmount;
    final orderId = 'order_${DateTime.now().millisecondsSinceEpoch}';

    final orderItems = cartItems.map((c) {
      final hasDiscount = c.product.discountPrice > 0 && c.product.discountPrice < c.product.price;
      final price = hasDiscount ? c.product.discountPrice : c.product.price;
      return OrderItemModel(
        productId: c.product.id,
        name: c.product.name,
        quantity: c.quantity,
        price: price,
      );
    }).toList();

    final deliveryAddress = _addressController.text.trim();
    final recipientName = _nameController.text.trim();
    final recipientPhone = _phoneController.text.trim();

    final newOrder = OrderModel(
      id: orderId,
      customerId: user.uid,
      customerName: recipientName,
      customerEmail: user.email ?? '',
      customerPhone: recipientPhone,
      items: orderItems,
      totalAmount: totalAmount,
      deliveryAddress: '$recipientName, $recipientPhone\n$deliveryAddress',
      paymentMethod: _paymentMethod,
      paymentStatus: 'Pending',
      status: 'Pending',
      createdDate: DateTime.now(),
      timeline: [
        OrderTimelineEvent(
          status: 'Pending',
          timestamp: DateTime.now(),
          notes: _appliedPromo != null
              ? 'Order placed successfully. Applied promo: ${_appliedPromo!.code} (${_appliedPromo!.discountPercentage}% off)'
              : 'Order placed successfully.',
        ),
      ],
    );

    // Check if COD or Online gateway
    if (_paymentMethod == 'Cash on Delivery') {
      setState(() => _isSubmitting = true);
      try {
        await DatabaseService.addOrder(newOrder);
        CartService.instance.clearCart();
        _showSuccessAnimation();
      } catch (e) {
        _showErrorSnackBar('Failed to place order: $e');
      } finally {
        setState(() => _isSubmitting = false);
      }
    } else {
      // Trigger Online Gateway simulator
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentProcessingView(
            gatewayName: _paymentMethod,
            amount: totalAmount,
            orderId: orderId,
            onPaymentSuccess: (txnId) async {
              if (mounted) {
                Navigator.pop(context); // Close simulator immediately
              }
              setState(() => _isSubmitting = true); // Show loading spinner on checkout page

              try {
                // 1. Save Transaction Log
                try {
                  final tx = PaymentTransactionModel(
                    id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                    orderId: orderId,
                    customerName: recipientName,
                    gateway: _paymentMethod,
                    amount: totalAmount,
                    status: 'Success',
                    transactionId: txnId,
                    timestamp: DateTime.now(),
                  );
                  await DatabaseService.addTransaction(tx);
                } catch (txEx) {
                  debugPrint('Failed to save transaction log: $txEx');
                  // We continue because payment succeeded anyway!
                }

                // 2. Place Paid Order
                final paidOrder = OrderModel(
                  id: orderId,
                  customerId: newOrder.customerId,
                  customerName: newOrder.customerName,
                  customerEmail: newOrder.customerEmail,
                  customerPhone: newOrder.customerPhone,
                  items: newOrder.items,
                  totalAmount: newOrder.totalAmount,
                  deliveryAddress: newOrder.deliveryAddress,
                  paymentMethod: newOrder.paymentMethod,
                  paymentStatus: 'Paid',
                  status: 'Confirmed',
                  createdDate: newOrder.createdDate,
                  timeline: [
                    OrderTimelineEvent(
                      status: 'Pending',
                      timestamp: DateTime.now(),
                      notes: _appliedPromo != null
                          ? 'Order placed online. Applied promo: ${_appliedPromo!.code} (${_appliedPromo!.discountPercentage}% off)'
                          : 'Order placed online.',
                    ),
                    OrderTimelineEvent(
                      status: 'Confirmed',
                      timestamp: DateTime.now(),
                      notes: 'Payment confirmed via $_paymentMethod. Transaction Ref: $txnId',
                    ),
                  ],
                );
                await DatabaseService.addOrder(paidOrder);

                // 3. Clear cart and return
                CartService.instance.clearCart();
                _showSuccessAnimation();
              } catch (e) {
                _showErrorSnackBar('Failed to save order details: $e');
              } finally {
                if (mounted) {
                  setState(() => _isSubmitting = false);
                }
              }
            },
            onPaymentFailure: (errMsg) async {
              if (mounted) {
                Navigator.pop(context); // Close simulator immediately
              }
              _showErrorSnackBar('Payment Failed: $errMsg');

              try {
                // Save failed transaction log in the background
                final tx = PaymentTransactionModel(
                  id: 'tx_${DateTime.now().millisecondsSinceEpoch}',
                  orderId: orderId,
                  customerName: recipientName,
                  gateway: _paymentMethod,
                  amount: totalAmount,
                  status: 'Failed',
                  transactionId: '',
                  timestamp: DateTime.now(),
                  errorMessage: errMsg,
                );
                await DatabaseService.addTransaction(tx);
              } catch (_) {}
            },
          ),
        ),
      );
    }
  }

  void _showSuccessAnimation() {
    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: const Color(0xFF070412),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const _CheckoutSuccessAnimation();
      },
    );

    // Auto-dismiss after 2.5 seconds and pop checkout page
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.pop(context); // Pop animation
        Navigator.pop(context); // Pop Checkout page
      }
    });
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF070412),
        body: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)))),
      );
    }

    final user = AuthService.currentUser;
    final cartItems = CartService.instance.items;
    final subtotal = CartService.instance.totalAmount;
    final totalAmount = subtotal - _discountAmount;

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: const Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. SAVED ADDRESS SELECTOR
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AddressBookView()),
                      );
                    },
                    icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF8A00)),
                    label: const Text('Manage', style: TextStyle(color: Color(0xFFFF8A00), fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (user != null)
                StreamBuilder<List<UserAddressModel>>(
                  stream: DatabaseService.getUserAddressesStream(user.uid),
                  builder: (context, snapshot) {
                    final addresses = snapshot.data ?? [];
                    if (addresses.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: GlassCard(
                          padding: const EdgeInsets.all(16),
                          child: const Column(
                            children: [
                              Text(
                                'No saved addresses found.',
                                style: TextStyle(color: Colors.white38, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 90,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: addresses.length,
                        itemBuilder: (context, index) {
                          final addr = addresses[index];
                          final isSelected = _selectedAddress?.id == addr.id;

                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAddress = addr;
                                _nameController.text = addr.recipientName;
                                _phoneController.text = addr.phone;
                                _addressController.text = addr.fullAddress;
                              });
                            },
                            child: Container(
                              width: 180,
                              margin: const EdgeInsets.only(right: 12, bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFF8A00).withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.02),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: isSelected ? const Color(0xFFFF8A00) : Colors.white10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    addr.title,
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? const Color(0xFFFF8A00) : Colors.white70, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    addr.fullAddress,
                                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              const SizedBox(height: 12),

              // Inputs details
              GlassCard(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Recipient Name',
                        labelStyle: TextStyle(color: Colors.white54),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter recipient name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Contact Phone Number',
                        labelStyle: TextStyle(color: Colors.white54),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter phone number' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _addressController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Address',
                        labelStyle: TextStyle(color: Colors.white54),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                      ),
                      style: const TextStyle(color: Colors.white),
                      validator: (val) => val == null || val.trim().isEmpty ? 'Please enter shipping address' : null,
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                        icon: _isLoadingLocation
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8A00)))
                            : const Icon(Icons.my_location, size: 16, color: Color(0xFFFF8A00)),
                        label: Text(
                          _isLoadingLocation ? 'Locating...' : 'Use Current Location',
                          style: const TextStyle(color: Color(0xFFFF8A00), fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          backgroundColor: const Color(0xFFFF8A00).withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 2. DYNAMIC PAYMENT METHOD SELECTION
              const Text('Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    if (_paymentSettings?.codEnabled ?? true)
                      RadioListTile<String>(
                        title: const Text('Cash on Delivery (COD)', style: TextStyle(color: Colors.white)),
                        value: 'Cash on Delivery',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    if (_paymentSettings?.walletEnabled ?? true)
                      RadioListTile<String>(
                        title: const Text('Digital Wallet Balance', style: TextStyle(color: Colors.white)),
                        value: 'Wallet',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    if (_paymentSettings?.upiEnabled ?? true)
                      RadioListTile<String>(
                        title: const Text('Direct UPI (GPay/PhonePe/Paytm)', style: TextStyle(color: Colors.white)),
                        value: 'UPI',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    if (_paymentSettings?.razorpay.isEnabled ?? false)
                      RadioListTile<String>(
                        title: const Text('Razorpay Secure (UPI/Cards)', style: TextStyle(color: Colors.white)),
                        value: 'Razorpay',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    if (_paymentSettings?.stripe.isEnabled ?? false)
                      RadioListTile<String>(
                        title: const Text('Stripe Credit/Debit Gateway', style: TextStyle(color: Colors.white)),
                        value: 'Stripe',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    if (_paymentSettings?.phonepe.isEnabled ?? false)
                      RadioListTile<String>(
                        title: const Text('PhonePe Gateway (UPI)', style: TextStyle(color: Colors.white)),
                        value: 'PhonePe',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    if (_paymentSettings?.cashfree.isEnabled ?? false)
                      RadioListTile<String>(
                        title: const Text('Cashfree Payments', style: TextStyle(color: Colors.white)),
                        value: 'Cashfree',
                        groupValue: _paymentMethod,
                        activeColor: const Color(0xFFFF8A00),
                        onChanged: (val) => setState(() => _paymentMethod = val!),
                      ),
                    if (_paymentSettings != null &&
                        !_paymentSettings!.codEnabled &&
                        !_paymentSettings!.walletEnabled &&
                        !_paymentSettings!.upiEnabled &&
                        !_paymentSettings!.razorpay.isEnabled &&
                        !_paymentSettings!.stripe.isEnabled &&
                        !_paymentSettings!.phonepe.isEnabled &&
                        !_paymentSettings!.cashfree.isEnabled)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text(
                          'No payment methods are currently configured by the admin.',
                          style: TextStyle(color: Colors.redAccent, fontSize: 13),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // 3. PROMO CODE FIELD
              const Text('Promo Code', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GlassCard(
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _couponController,
                        decoration: const InputDecoration(
                          hintText: 'Enter coupon code (e.g. COOKING10)',
                          hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _applyPromoCode,
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
                      child: const Text('APPLY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Summary
              const Text('Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 12),
              GlassCard(
                child: Column(
                  children: [
                    ...cartItems.map((c) {
                      final hasDiscount = c.product.discountPrice > 0 && c.product.discountPrice < c.product.price;
                      final price = hasDiscount ? c.product.discountPrice : c.product.price;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${c.product.name} (x${c.quantity})',
                                style: const TextStyle(color: Colors.white70, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text('₹${(price * c.quantity).toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ],
                        ),
                      );
                    }),
                    const Divider(color: Colors.white10, height: 20),
                    if (_appliedPromo != null) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal', style: TextStyle(color: Colors.white70, fontSize: 13)),
                          Text('₹${subtotal.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount (${_appliedPromo!.code})', style: const TextStyle(color: Colors.green, fontSize: 13)),
                          Text('-₹${_discountAmount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontSize: 13)),
                        ],
                      ),
                      const Divider(color: Colors.white10, height: 20),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFF8A00), fontSize: 16),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _placeOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size.fromHeight(56),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        _paymentMethod == 'Cash on Delivery' ? 'PLACE COD ORDER' : 'PAY WITH $_paymentMethod',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.0),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckoutSuccessAnimation extends StatefulWidget {
  const _CheckoutSuccessAnimation();

  @override
  State<_CheckoutSuccessAnimation> createState() => _CheckoutSuccessAnimationState();
}

class _CheckoutSuccessAnimationState extends State<_CheckoutSuccessAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 40),
    ]).animate(_controller);

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.4, curve: Curves.easeIn)),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacityAnimation.value,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8A00).withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFF8A00), width: 4),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_rounded, color: Color(0xFFFF8A00), size: 60),
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Text(
                      'Order Confirmed!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Your food is being prepared...',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
