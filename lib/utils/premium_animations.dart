import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui';

class SpotlightPainter extends CustomPainter {
  final Offset mousePos;
  final bool isActive;

  SpotlightPainter({required this.mousePos, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive) return;
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white.withOpacity(0.12),
          Colors.transparent,
        ],
        radius: 0.45,
      ).createShader(Rect.fromCircle(center: mousePos, radius: size.width * 0.45));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant SpotlightPainter oldDelegate) {
    return oldDelegate.mousePos != mousePos || oldDelegate.isActive != isActive;
  }
}

class ShinePainter extends CustomPainter {
  final double progress;
  ShinePainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.0),
          Colors.transparent,
        ],
        stops: const [0.0, 0.35, 0.5, 0.65, 1.0],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(
        (size.width * 1.5) * progress - (size.width * 0.5),
        0,
        size.width * 0.5,
        size.height,
      ));
    canvas.drawRect(Offset.zero & size, paint);
  }

  @override
  bool shouldRepaint(covariant ShinePainter oldDelegate) => oldDelegate.progress != progress;
}

class SteamPainter extends CustomPainter {
  final double progress;
  final bool isHovered;
  SteamPainter({required this.progress, required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isHovered) return;
    final paint = Paint()
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    for (int i = 0; i < 3; i++) {
      double p = (progress + (i * 0.33)) % 1.0;
      double y = size.height * (1.0 - p * 1.2);
      double x = size.width * (0.4 + i * 0.1) + math.sin(p * math.pi * 4 + i) * 6;
      double opacity = 0.15 * (1.0 - (2 * (p - 0.5)).abs()).clamp(0.0, 1.0);
      paint.color = Colors.white.withOpacity(opacity);
      double radius = 8 + p * 12;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SteamPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isHovered != isHovered;
}

class FloatingIngredients extends StatelessWidget {
  final double progress;
  final bool isHovered;
  final List<String> ingredients;

  const FloatingIngredients({
    super.key, 
    required this.progress, 
    required this.isHovered,
    this.ingredients = const ['🍅', '🧀', '🌿', '🍄', '🌶', '🍕', '🥬'],
  });

  @override
  Widget build(BuildContext context) {
    if (!isHovered) return const SizedBox.shrink();
    return Stack(
      children: List.generate(ingredients.length, (index) {
        final emoji = ingredients[index];
        double p = (progress + (index * 0.15)) % 1.0;
        double yAlign = 1.0 - (p * 1.4);
        double xAlign = -0.7 + (index * 0.22) + math.sin(p * math.pi * 3 + index) * 0.1;
        double opacity = (1.0 - (2 * (p - 0.5)).abs()).clamp(0.0, 1.0);
        double rotation = p * math.pi * 2 * (index % 2 == 0 ? 1.0 : -1.0);
        return Align(
          alignment: Alignment(xAlign, yAlign),
          child: Opacity(
            opacity: opacity,
            child: Transform.rotate(
              angle: rotation,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class ParticlePainter extends CustomPainter {
  final double progress;
  final Color color;
  final int count;
  final double radius;

  ParticlePainter({
    required this.progress,
    this.color = const Color(0xFFFF8A00),
    this.count = 8,
    this.radius = 40.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;

    final paint = Paint()
      ..color = color.withOpacity((1 - progress).clamp(0.0, 1.0))
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final currentRadius = radius * progress;

    for (int i = 0; i < count; i++) {
      final angle = (i * 2 * math.pi) / count;
      final dx = center.dx + math.cos(angle) * currentRadius;
      final dy = center.dy + math.sin(angle) * currentRadius;
      
      // Draw tiny star/circle
      canvas.drawCircle(Offset(dx, dy), 2 * (1 - progress), paint);
    }
  }

  @override
  bool shouldRepaint(covariant ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class CartFlyAnimation {
  static void trigger(BuildContext context, String imageUrl, Offset startOffset) {
    final overlay = Overlay.of(context);
    final screenSize = MediaQuery.of(context).size;
    
    // Default destination: Center bottom of the screen
    final endOffset = Offset(screenSize.width / 2 - 25, screenSize.height - 80);

    late OverlayEntry entry;
    
    entry = OverlayEntry(
      builder: (context) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
          onEnd: () {
            entry.remove();
          },
          builder: (context, value, child) {
            // Parabolic jump path
            final dx = startOffset.dx + (endOffset.dx - startOffset.dx) * value;
            final dy = startOffset.dy + (endOffset.dy - startOffset.dy) * value - math.sin(value * math.pi) * 100;
            
            final scale = 1.0 - (value * 0.5);
            final opacity = 1.0 - (value * value);
            
            return Positioned(
              left: dx,
              top: dy,
              child: Opacity(
                opacity: opacity.clamp(0.0, 1.0),
                child: Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        )
                      ],
                      image: DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    overlay.insert(entry);
  }
}
