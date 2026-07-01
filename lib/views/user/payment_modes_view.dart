import 'package:flutter/material.dart';
import '../../widgets/glass_card.dart';

class PaymentModesView extends StatefulWidget {
  const PaymentModesView({super.key});

  @override
  State<PaymentModesView> createState() => _PaymentModesViewState();
}

class _PaymentModesViewState extends State<PaymentModesView> {
  final List<Map<String, String>> _cards = [
    {'type': 'Visa', 'number': '•••• •••• •••• 4321', 'expiry': '12/28', 'holder': 'Valued Customer'},
    {'type': 'Mastercard', 'number': '•••• •••• •••• 8765', 'expiry': '08/30', 'holder': 'Valued Customer'},
  ];

  final List<String> _upiIds = [
    'customer@okhdfcbank',
    'customer@paytm',
  ];

  final _cardFormKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderController = TextEditingController();

  final _upiFormKey = GlobalKey<FormState>();
  final _upiController = TextEditingController();

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _holderController.dispose();
    _upiController.dispose();
    super.dispose();
  }

  void _addCard() {
    _cardNumberController.clear();
    _expiryController.clear();
    _cvvController.clear();
    _holderController.text = 'Valued Customer';

    showModalBottomSheet(
      backgroundColor: const Color(0xFF0E0724),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _cardFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Credit/Debit Card',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  TextFormField(
                    controller: _cardNumberController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Card Number',
                      labelStyle: TextStyle(color: Colors.white54),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter card number';
                      if (val.trim().length < 16) return 'Invalid card number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _expiryController,
                          decoration: const InputDecoration(
                            labelText: 'Expiry (MM/YY)',
                            labelStyle: TextStyle(color: Colors.white54),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter expiry' : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _cvvController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'CVV',
                            labelStyle: TextStyle(color: Colors.white54),
                            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                          ),
                          style: const TextStyle(color: Colors.white),
                          validator: (val) => val == null || val.trim().isEmpty ? 'Enter CVV' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _holderController,
                    decoration: const InputDecoration(
                      labelText: 'Cardholder Name',
                      labelStyle: TextStyle(color: Colors.white54),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      if (_cardFormKey.currentState!.validate()) {
                        final numText = _cardNumberController.text.trim();
                        final last4 = numText.substring(numText.length - 4);
                        setState(() {
                          _cards.add({
                            'type': numText.startsWith('4') ? 'Visa' : 'Mastercard',
                            'number': '•••• •••• •••• $last4',
                            'expiry': _expiryController.text.trim(),
                            'holder': _holderController.text.trim(),
                          });
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Card added successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ADD CARD', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _addUpi() {
    _upiController.clear();
    showModalBottomSheet(
      backgroundColor: const Color(0xFF0E0724),
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24,
            right: 24,
            top: 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _upiFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add UPI ID',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                  const Divider(color: Colors.white10, height: 24),
                  TextFormField(
                    controller: _upiController,
                    decoration: const InputDecoration(
                      labelText: 'UPI ID (e.g. mobile@upi)',
                      labelStyle: TextStyle(color: Colors.white54),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFFFF8A00))),
                    ),
                    style: const TextStyle(color: Colors.white),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return 'Enter UPI ID';
                      if (!val.contains('@')) return 'Invalid UPI ID format';
                      return null;
                    },
                  ),
                  const SizedBox(height: 28),
                  ElevatedButton(
                    onPressed: () {
                      if (_upiFormKey.currentState!.validate()) {
                        setState(() {
                          _upiIds.add(_upiController.text.trim());
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('UPI ID added successfully!'), backgroundColor: Colors.green),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('ADD UPI ID', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070412),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D0622),
        elevation: 0,
        title: const Text('Payment Modes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Credit/Debit Cards Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Saved Cards',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                TextButton.icon(
                  onPressed: _addCard,
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF8A00)),
                  label: const Text('ADD NEW', style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_cards.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No saved cards.', style: TextStyle(color: Colors.white30, fontSize: 13)),
              )
            else
              ..._cards.map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      child: Row(
                        children: [
                          Icon(
                            card['type'] == 'Visa' ? Icons.credit_card_rounded : Icons.payment_rounded,
                            color: const Color(0xFFFF8A00),
                            size: 32,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card['number']!,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Expires: ${card['expiry']}  •  ${card['type']}',
                                  style: const TextStyle(fontSize: 11, color: Colors.white38),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() {
                                _cards.remove(card);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )),

            const SizedBox(height: 24),

            // UPI Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'UPI Accounts',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
                ),
                TextButton.icon(
                  onPressed: _addUpi,
                  icon: const Icon(Icons.add, size: 16, color: Color(0xFFFF8A00)),
                  label: const Text('ADD NEW', style: TextStyle(color: Color(0xFFFF8A00), fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_upiIds.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text('No saved UPI IDs.', style: TextStyle(color: Colors.white30, fontSize: 13)),
              )
            else
              ..._upiIds.map((upi) => Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: GlassCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Color(0xFFFF8A00),
                            size: 28,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              upi,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            onPressed: () {
                              setState(() {
                                _upiIds.remove(upi);
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  )),

            const SizedBox(height: 24),

            // Cash/Other modes
            const Text(
              'Other Payment Modes',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            const SizedBox(height: 12),
            GlassCard(
              child: Row(
                children: [
                  const Icon(
                    Icons.payments_outlined,
                    color: Colors.greenAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Cash on Delivery',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pay with Cash or UPI upon receiving your food',
                          style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.4)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
