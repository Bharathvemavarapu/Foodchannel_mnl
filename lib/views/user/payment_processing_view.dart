import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';

class PaymentProcessingView extends StatefulWidget {
  final String gatewayName;
  final double amount;
  final String orderId;
  final Future<void> Function(String transactionId) onPaymentSuccess;
  final Future<void> Function(String errorMessage) onPaymentFailure;

  const PaymentProcessingView({
    super.key,
    required this.gatewayName,
    required this.amount,
    required this.orderId,
    required this.onPaymentSuccess,
    required this.onPaymentFailure,
  });

  @override
  State<PaymentProcessingView> createState() => _PaymentProcessingViewState();
}

class _PaymentProcessingViewState extends State<PaymentProcessingView> {
  int _currentStep = 0; // 0 = Loading config, 1 = Option Selection, 2 = Simulating Processing, 3 = OTP Prompt
  String _selectedMethod = 'Card'; // 'Card' or 'UPI'
  final _cardNumberController = TextEditingController(text: '4111 1111 1111 1111');
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startCheckoutLoading();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _startCheckoutLoading() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _currentStep = 1);
    }
  }

  Future<void> _handleSuccessFlow() async {
    setState(() {
      _currentStep = 2;
    });
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    if (_selectedMethod == 'Card') {
      setState(() {
        _currentStep = 3; // Prompts OTP
      });
    } else {
      _completePayment(success: true);
    }
  }

  Future<void> _handleFailureFlow() async {
    setState(() {
      _currentStep = 2;
    });
    await Future.delayed(const Duration(seconds: 2));
    _completePayment(success: false, error: 'User cancelled transaction or insufficient funds.');
  }

  Future<void> _completePayment({required bool success, String? error}) async {
    if (success) {
      final txnId = 'pay_${widget.gatewayName.toLowerCase()}_${DateTime.now().millisecondsSinceEpoch}';
      await widget.onPaymentSuccess(txnId);
    } else {
      await widget.onPaymentFailure(error ?? 'Payment failed.');
    }
  }

  Color _getGatewayThemeColor() {
    switch (widget.gatewayName.toLowerCase()) {
      case 'razorpay':
        return const Color(0xFF0F72E6);
      case 'stripe':
        return const Color(0xFF635BFF);
      case 'phonepe':
        return const Color(0xFF5F259F);
      default:
        return const Color(0xFFFF8A00);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = _getGatewayThemeColor();

    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        title: Text('${widget.gatewayName} Secure Checkout', style: const TextStyle(fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _completePayment(success: false, error: 'Payment checkout aborted.'),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Amount Header
              GlassCard(
                child: Column(
                  children: [
                    Text(
                      'PAYING TO FOODCHANNEL MNL',
                      style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${widget.amount.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order Ref: ${widget.orderId}',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              if (_currentStep == 0) ...[
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))),
                      SizedBox(height: 16),
                      Text('Initializing checkout window...', style: TextStyle(color: Colors.white60)),
                    ],
                  ),
                ),
              ] else if (_currentStep == 1) ...[
                // Payment Selection Methods
                const Text('Choose Mode', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = 'Card'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'Card' ? themeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _selectedMethod == 'Card' ? themeColor : Colors.white10),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.credit_card_rounded, color: _selectedMethod == 'Card' ? themeColor : Colors.white60),
                              const SizedBox(height: 8),
                              const Text('Card Payment', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedMethod = 'UPI'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedMethod == 'UPI' ? themeColor.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _selectedMethod == 'UPI' ? themeColor : Colors.white10),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.qr_code_2_rounded, color: _selectedMethod == 'UPI' ? themeColor : Colors.white60),
                              const SizedBox(height: 8),
                              const Text('UPI / Scan QR', style: TextStyle(color: Colors.white, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                if (_selectedMethod == 'Card') ...[
                  GlassCard(
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _cardNumberController,
                          enabled: false,
                          decoration: const InputDecoration(
                            labelText: 'Demo Card Number',
                            labelStyle: TextStyle(color: Colors.white54),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white30)),
                          ),
                          style: const TextStyle(color: Colors.white70),
                        ),
                        const SizedBox(height: 12),
                        const Row(
                          children: [
                            Expanded(
                              child: Text('Expiry: 12/32', style: TextStyle(color: Colors.white38, fontSize: 12)),
                            ),
                            Text('CVV: ***', style: TextStyle(color: Colors.white38, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  GlassCard(
                    child: Column(
                      children: [
                        Icon(Icons.qr_code_scanner_rounded, size: 80, color: themeColor),
                        const SizedBox(height: 12),
                        const Text(
                          'Scan this simulated UPI QR code from any app to complete payment.',
                          style: TextStyle(color: Colors.white38, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Simulator Toggles
                const Align(
                  alignment: Alignment.center,
                  child: Text('STAGING ENVIRONMENT SIMULATOR', style: TextStyle(color: Color(0xFFFF8A00), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.0)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleSuccessFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('MOCK SUCCESS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _handleFailureFlow,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('MOCK DECLINED', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
              ] else if (_currentStep == 2) ...[
                Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(themeColor)),
                      const SizedBox(height: 24),
                      Text('Processing via ${widget.gatewayName} secure networks...', style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ] else if (_currentStep == 3) ...[
                GlassCard(
                  child: Column(
                    children: [
                      const Text('Enter 3D-Secure OTP', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      const Text('We sent a simulated 6-digit OTP code to your registered mobile number.', style: TextStyle(color: Colors.white38, fontSize: 11), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 123456',
                          hintStyle: TextStyle(color: Colors.white24),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                        ),
                        style: const TextStyle(color: Colors.white, letterSpacing: 6.0, fontSize: 18),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          if (_otpController.text.trim().isEmpty) return;
                          setState(() {
                            _currentStep = 2;
                          });
                          Future.delayed(const Duration(milliseconds: 1500), () {
                            _completePayment(success: true);
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('SUBMIT OTP', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
