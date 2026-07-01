import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/cart_service.dart';

class AddToCartButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (!product.isAvailable) {
      return Container(
        width: width,
        height: height,
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

    return ListenableBuilder(
      listenable: CartService.instance,
      builder: (context, _) {
        final cartItems = CartService.instance.items;
        final cartItemIdx = cartItems.indexWhere((item) => item.product.id == product.id);
        final currentQty = cartItemIdx >= 0 ? cartItems[cartItemIdx].quantity : 0;

        if (currentQty == 0) {
          // Show "ADD" button
          return InkWell(
            onTap: () {
              CartService.instance.addToCart(product, quantity: 1);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: width,
              height: height,
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
          width: width,
          height: height,
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
                  onTap: () {
                    CartService.instance.updateQuantity(product.id, currentQty - 1);
                  },
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
                  onTap: () {
                    CartService.instance.updateQuantity(product.id, currentQty + 1);
                  },
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
    );
  }
}
