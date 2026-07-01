import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import '../views/user/user_bottom_nav.dart';

class CartIconButton extends StatelessWidget {
  final Color color;
  const CartIconButton({super.key, this.color = const Color(0xFFFF8A00)});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartService.instance,
      builder: (context, _) {
        final count = CartService.instance.totalItems;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.shopping_cart_rounded, color: color, size: 24),
              onPressed: () {
                // Return to first route and switch active tab to Cart (index 3)
                Navigator.popUntil(context, (route) => route.isFirst);
                UserBottomNav.activeTabNotifier.value = 3;
              },
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: IgnorePointer(
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFDA1B60),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
