import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/cart_service.dart';
import '../utils/premium_animations.dart';

class AddToCartButton extends StatefulWidget {
  final ProductModel product;
  final double width;
  final double height;

  const AddToCartButton({
    super.key,
    required this.product,
    this.width = 90,
    this.height = 34,
  });

  @override
  State<AddToCartButton> createState() => _AddToCartButtonState();
}

class _AddToCartButtonState extends State<AddToCartButton> with SingleTickerProviderStateMixin {
  final GlobalKey _buttonKey = GlobalKey();
  double _scale = 1.0;

  void _triggerBounce() {
    setState(() => _scale = 0.85);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) setState(() => _scale = 1.0);
    });
  }

  void _triggerFlyAnimation(BuildContext context) {
    final RenderBox? renderBox = _buttonKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final imageUrl = widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : '';
      CartFlyAnimation.trigger(context, imageUrl, position);
    }
  }

  void _handleAdd(BuildContext context) {
    _triggerBounce();
    _triggerFlyAnimation(context);
    CartService.instance.addToCart(widget.product, quantity: 1);
  }
  
  void _handleIncrease(BuildContext context, int currentQty) {
    _triggerBounce();
    _triggerFlyAnimation(context);
    CartService.instance.updateQuantity(widget.product.id, currentQty + 1);
  }

  void _handleDecrease(int currentQty) {
    _triggerBounce();
    CartService.instance.updateQuantity(widget.product.id, currentQty - 1);
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.product.isAvailable) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: const Text(
          'OUT OF STOCK',
          style: TextStyle(
            color: Colors.white30,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return AnimatedScale(
      scale: _scale,
      duration: const Duration(milliseconds: 200),
      curve: Curves.elasticOut,
      child: ListenableBuilder(
        listenable: CartService.instance,
        builder: (context, _) {
          final cartItems = CartService.instance.items;
          final cartItemIdx = cartItems.indexWhere((item) => item.product.id == widget.product.id);
          final currentQty = cartItemIdx >= 0 ? cartItems[cartItemIdx].quantity : 0;

          if (currentQty == 0) {
            // Show "ADD" button
            return InkWell(
              key: _buttonKey,
              onTap: () => _handleAdd(context),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFFFF8A00),
                    width: 1.2,
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'ADD',
                      style: TextStyle(
                        color: Color(0xFFFF8A00),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(
                      Icons.add,
                      color: Color(0xFFFF8A00),
                      size: 12,
                    ),
                  ],
                ),
              ),
            );
          }

          // Show "- qty +" selector
          return Container(
            key: _buttonKey,
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: const Color(0xFFFF8A00),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF8A00).withValues(alpha: 0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Decrease Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleDecrease(currentQty),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      bottomLeft: Radius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 26,
                      height: double.infinity,
                      child: Icon(
                        Icons.remove,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
                // Quantity Display
                Text(
                  currentQty.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                // Increase Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _handleIncrease(context, currentQty),
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(8),
                      bottomRight: Radius.circular(8),
                    ),
                    child: const SizedBox(
                      width: 26,
                      height: double.infinity,
                      child: Icon(
                        Icons.add,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
