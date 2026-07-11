import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:math' as math;
import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import 'glass_card.dart';
import 'add_to_cart_button.dart';
import '../views/user/product_detail_view.dart';
import '../utils/premium_animations.dart';

class ProductCard extends StatefulWidget {
  final ProductModel product;
  final bool showWishlistButton;
  final bool isWishlistPage;

  const ProductCard({
    super.key,
    required this.product,
    this.showWishlistButton = true,
    this.isWishlistPage = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with TickerProviderStateMixin {
  bool? _localIsWishlisted;
  
  bool _isHovered = false;
  Offset _mousePos = Offset.zero;
  double _rotX = 0.0;
  double _rotY = 0.0;

  late AnimationController _loopController;
  late AnimationController _wishlistPopController;

  @override
  void initState() {
    super.initState();
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
    
    _wishlistPopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _loopController.dispose();
    _wishlistPopController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    setState(() {
      _isHovered = true;
    });
  }

  void _onHoverExit() {
    setState(() {
      _isHovered = false;
      _rotX = 0.0;
      _rotY = 0.0;
    });
  }

  void _toggleWishlist(bool isWishlisted) {
    final uid = AuthService.currentUser?.uid;
    if (uid != null) {
      if (!isWishlisted) {
        _wishlistPopController.forward(from: 0.0);
      }
      setState(() {
        _localIsWishlisted = !isWishlisted;
      });
      DatabaseService.toggleWishlist(uid, widget.product.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasDiscount = widget.product.discountPrice > 0 && widget.product.discountPrice < widget.product.price;
    final displayPrice = hasDiscount ? widget.product.discountPrice : widget.product.price;

    final Curve premiumCurve = const Cubic(0.22, 1.0, 0.36, 1.0);
    final Duration premiumDuration = const Duration(milliseconds: 450);
    final isReducedMotion = MediaQuery.maybeOf(context)?.accessibleNavigation ?? false;

    return MouseRegion(
      onEnter: (_) => _onHoverEnter(),
      onExit: (_) => _onHoverExit(),
      onHover: (event) {
        final size = context.size;
        if (size != null) {
          final localPos = event.localPosition;
          final dx = (localPos.dx / size.width) * 2 - 1;
          final dy = (localPos.dy / size.height) * 2 - 1;
          setState(() {
            _mousePos = localPos;
            _rotX = -dy * 4 * math.pi / 180;
            _rotY = dx * 6 * math.pi / 180;
          });
        }
      },
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailView(product: widget.product),
            ),
          );
        },
        child: AnimatedContainer(
          duration: premiumDuration,
          curve: premiumCurve,
          transform: _isHovered && !isReducedMotion
              ? (Matrix4.identity()..translate(0, -10)..scale(1.02))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: _isHovered && !isReducedMotion
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.45),
                      blurRadius: 60,
                      offset: const Offset(0, 25),
                    ),
                  ]
                : [],
          ),
          child: GlassCard(
            padding: EdgeInsets.zero,
            child: CustomPaint(
              painter: !isReducedMotion ? SpotlightPainter(mousePos: _mousePos, isActive: _isHovered) : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product image section
                  Expanded(
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Transform(
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.001)
                                ..rotateX(_isHovered && !isReducedMotion ? _rotX : 0.0)
                                ..rotateY(_isHovered && !isReducedMotion ? _rotY : 0.0),
                              alignment: Alignment.center,
                              child: AnimatedContainer(
                                duration: premiumDuration,
                                curve: premiumCurve,
                                transform: _isHovered && !isReducedMotion
                                    ? (Matrix4.identity()..scale(1.08)..translate(-4.0, 0.0))
                                    : Matrix4.identity(),
                                transformAlignment: Alignment.center,
                                child: Image.network(
                                  widget.product.imageUrls.isNotEmpty ? widget.product.imageUrls.first : '',
                                  width: double.infinity,
                                  height: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(Icons.broken_image, size: 40, color: Colors.white30),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (!isReducedMotion)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _loopController,
                              builder: (context, child) {
                                return CustomPaint(
                                  painter: SteamPainter(
                                    progress: _loopController.value,
                                    isHovered: _isHovered,
                                  ),
                                );
                              },
                            ),
                          ),
                        if (!isReducedMotion)
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _loopController,
                              builder: (context, child) {
                                return FloatingIngredients(
                                  progress: _loopController.value,
                                  isHovered: _isHovered,
                                );
                              },
                            ),
                          ),
                        // Wishlist overlay
                        if (widget.showWishlistButton)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: StreamBuilder<List<String>>(
                              stream: DatabaseService.getUserWishlistStream(AuthService.currentUser?.uid ?? ''),
                              builder: (context, snapshot) {
                                final wishlist = snapshot.data ?? [];
                                final isWishlistedFromDb = wishlist.contains(widget.product.id);
                                final isWishlisted = _localIsWishlisted ?? isWishlistedFromDb;

                                return Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    if (isWishlisted && !isReducedMotion)
                                      AnimatedBuilder(
                                        animation: _wishlistPopController,
                                        builder: (context, child) {
                                          return CustomPaint(
                                            painter: ParticlePainter(
                                              progress: _wishlistPopController.value,
                                              color: Colors.redAccent,
                                            ),
                                            size: const Size(40, 40),
                                          );
                                        },
                                      ),
                                    AnimatedScale(
                                      scale: isWishlisted ? 1.1 : 1.0,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.elasticOut,
                                      child: IconButton(
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                          padding: const EdgeInsets.all(6),
                                        ),
                                        icon: Icon(
                                          widget.isWishlistPage || isWishlisted
                                              ? Icons.favorite_rounded
                                              : Icons.favorite_border_rounded,
                                          color: widget.isWishlistPage || isWishlisted ? Colors.redAccent : Colors.white70,
                                          size: 16,
                                        ),
                                        onPressed: () => _toggleWishlist(isWishlisted),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        // Discount badge
                        if (hasDiscount)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDA1B60),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'SALE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Details section
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.brand.toUpperCase(),
                          style: TextStyle(
                            color: const Color(0xFFFF8A00).withValues(alpha: 0.8),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Prices & ADD Button Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween<double>(begin: 0, end: displayPrice),
                                    duration: const Duration(seconds: 1),
                                    curve: Curves.easeOutQuart,
                                    builder: (context, value, child) {
                                      return Text(
                                        '₹${value.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                                  ),
                                  if (hasDiscount)
                                    Text(
                                      '₹${widget.product.price}',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white30,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            AddToCartButton(product: widget.product),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
