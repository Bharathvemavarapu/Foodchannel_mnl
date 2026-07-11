import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async' as async;
import '../../../models/banner_hero.dart';
import '../../../services/database_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/glass_card.dart';
import '../../../utils/premium_animations.dart';

class HeroTab extends StatefulWidget {
  const HeroTab({super.key});

  @override
  State<HeroTab> createState() => _HeroTabState();
}

class _HeroTabState extends State<HeroTab> {
  List<HeroImageModel> _heroImages = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadHeroImages();
  }

  Future<void> _loadHeroImages() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.getHeroImages();
      setState(() {
        _heroImages = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load hero images: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.redAccent));
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: Colors.green));
  }

  Future<void> _addHeroImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => _isSaving = true);
      try {
        final bytes = await img.readAsBytes();
        final url = await CloudinaryService.uploadImage(bytes, img.name);
        
        final newImage = HeroImageModel(
          id: 'new_${DateTime.now().microsecondsSinceEpoch}',
          imageUrl: url,
          sortOrder: _heroImages.length,
        );

        final updatedList = List<HeroImageModel>.from(_heroImages)..add(newImage);
        await DatabaseService.saveHeroImages(updatedList);
        _showSuccessSnackBar('Hero image uploaded successfully.');
        _loadHeroImages();
      } catch (e) {
        _showErrorSnackBar('Failed to upload hero image: $e');
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteHeroImage(HeroImageModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hero Image'),
        content: const Text('Are you sure you want to remove this hero image from the slider carousel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCEL')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSaving = true);
      try {
        final updatedList = List<HeroImageModel>.from(_heroImages)..removeWhere((element) => element.id == item.id);
        await DatabaseService.saveHeroImages(updatedList);
        _showSuccessSnackBar('Hero image deleted.');
        _loadHeroImages();
      } catch (e) {
        _showErrorSnackBar('Failed to delete: $e');
      } finally {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _reorderImage(int index, int offset) async {
    final newIndex = index + offset;
    if (newIndex < 0 || newIndex >= _heroImages.length) return;

    setState(() => _isSaving = true);
    try {
      final list = List<HeroImageModel>.from(_heroImages);
      final item = list.removeAt(index);
      list.insert(newIndex, item);

      await DatabaseService.saveHeroImages(list);
      _loadHeroImages();
    } catch (e) {
      _showErrorSnackBar('Failed to reorder: $e');
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text('Hero Images', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Upload and reorder 16:9 banner slides for the storefront home page slider', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: _isSaving ? null : _addHeroImage,
                icon: const Icon(Icons.upload_file_rounded),
                label: const Text('UPLOAD HERO IMAGE', style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8A00),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: LinearProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00)), backgroundColor: Colors.white10),
            ),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))))
                : _heroImages.isEmpty
                    ? const Center(child: Text('No hero images uploaded yet.', style: TextStyle(color: Colors.white38)))
                    : ListView.builder(
                        itemCount: _heroImages.length,
                        itemBuilder: (context, index) {
                          final item = _heroImages[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 20),
                            child: _HoverAnimatedHeroCard(
                              item: item,
                              index: index,
                              totalLength: _heroImages.length,
                              onReorderUp: index == 0 ? null : () => _reorderImage(index, -1),
                              onReorderDown: index == _heroImages.length - 1 ? null : () => _reorderImage(index, 1),
                              onDelete: () => _deleteHeroImage(item),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}

class _HoverAnimatedHeroCard extends StatefulWidget {
  final HeroImageModel item;
  final int index;
  final int totalLength;
  final VoidCallback? onReorderUp;
  final VoidCallback? onReorderDown;
  final VoidCallback onDelete;

  const _HoverAnimatedHeroCard({
    required this.item,
    required this.index,
    required this.totalLength,
    this.onReorderUp,
    this.onReorderDown,
    required this.onDelete,
  });

  @override
  State<_HoverAnimatedHeroCard> createState() => _HoverAnimatedHeroCardState();
}

class _HoverAnimatedHeroCardState extends State<_HoverAnimatedHeroCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  Offset _mousePos = Offset.zero;
  double _rotX = 0.0;
  double _rotY = 0.0;

  late AnimationController _shineController;
  late AnimationController _loopController;

  @override
  void initState() {
    super.initState();
    _shineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _loopController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _shineController.dispose();
    _loopController.dispose();
    super.dispose();
  }

  void _onHoverEnter() {
    _shineController.forward(from: 0.0);
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

  @override
  Widget build(BuildContext context) {
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
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedOpacity(
              duration: premiumDuration,
              opacity: _isHovered ? 0.4 : 0.0,
              child: ImageFiltered(
                imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
                child: Container(
                  margin: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Color(0x40FF9100),
                        Colors.transparent,
                      ],
                      stops: [0.0, 0.7],
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedContainer(
            duration: premiumDuration,
            curve: premiumCurve,
            transform: _isHovered
                ? (Matrix4.identity()..translate(0, -10)..scale(1.02))
                : Matrix4.identity(),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: _isHovered
                  ? [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 60,
                        offset: const Offset(0, 25),
                      ),
                      BoxShadow(
                        color: const Color(0xFFFF8A00).withOpacity(0.35),
                        blurRadius: 30,
                        spreadRadius: -10,
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      )
                    ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: AnimatedContainer(
                  duration: premiumDuration,
                  curve: premiumCurve,
                  decoration: BoxDecoration(
                    color: const Color(0x65121219),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _isHovered ? const Color(0xFFFF8A00) : Colors.white.withOpacity(0.08),
                      width: _isHovered ? 2.0 : 1.0,
                    ),
                  ),
                  child: CustomPaint(
                    painter: SpotlightPainter(mousePos: _mousePos, isActive: _isHovered),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 220,
                          child: ClipRRect(
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(22)),
                            child: AspectRatio(
                              aspectRatio: 16 / 9,
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Transform(
                                      transform: Matrix4.identity()
                                        ..setEntry(3, 2, 0.001)
                                        ..rotateX(_isHovered ? _rotX : 0.0)
                                        ..rotateY(_isHovered ? _rotY : 0.0),
                                      alignment: Alignment.center,
                                      child: AnimatedContainer(
                                        duration: premiumDuration,
                                        curve: premiumCurve,
                                        transform: _isHovered
                                            ? (Matrix4.identity()..scale(1.08)..translate(-8.0, 0.0))
                                            : Matrix4.identity(),
                                        transformAlignment: Alignment.center,
                                        child: Image.network(
                                          widget.item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40)),
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
                                  Positioned.fill(
                                    child: AnimatedBuilder(
                                      animation: _shineController,
                                      builder: (context, child) {
                                        return CustomPaint(
                                          painter: ShinePainter(progress: _shineController.value),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedScale(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.bounceOut,
                                scale: _isHovered ? 1.08 : 1.0,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF8A00).withOpacity(_isHovered ? 0.25 : 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFFF8A00).withOpacity(_isHovered ? 0.5 : 0.2)),
                                  ),
                                  child: AnimatedSlide(
                                    duration: premiumDuration,
                                    curve: premiumCurve,
                                    offset: _isHovered ? const Offset(0, -0.05) : Offset.zero,
                                    child: Text(
                                      'Sort Order: ${widget.index + 1}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFFFF8A00)),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              AnimatedOpacity(
                                duration: const Duration(milliseconds: 300),
                                opacity: _isHovered ? 0.7 : 0.4,
                                child: SelectableText(
                                  widget.item.imageUrl,
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Row(
                            children: [
                              _StaggeredHoverIconButton(
                                icon: Icons.arrow_upward_rounded,
                                color: Colors.white70,
                                hoverColor: const Color(0xFFFF8A00),
                                hoverTranslateY: -4.0,
                                parentHovered: _isHovered,
                                staggerIndex: 0,
                                onPressed: widget.onReorderUp,
                              ),
                              _StaggeredHoverIconButton(
                                icon: Icons.arrow_downward_rounded,
                                color: Colors.white70,
                                hoverColor: const Color(0xFFFF8A00),
                                hoverTranslateY: 4.0,
                                parentHovered: _isHovered,
                                staggerIndex: 1,
                                onPressed: widget.onReorderDown,
                              ),
                              const SizedBox(width: 12),
                              _StaggeredHoverIconButton(
                                icon: Icons.delete_rounded,
                                color: Colors.redAccent,
                                hoverColor: Colors.red,
                                hoverRotate: 8 * math.pi / 180,
                                parentHovered: _isHovered,
                                staggerIndex: 2,
                                onPressed: widget.onDelete,
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
          ),
        ],
      ),
    );
  }
}

class _StaggeredHoverIconButton extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? hoverColor;
  final double hoverTranslateY;
  final double hoverRotate;
  final bool parentHovered;
  final int staggerIndex;
  final VoidCallback? onPressed;

  const _StaggeredHoverIconButton({
    required this.icon,
    required this.color,
    this.hoverColor,
    this.hoverTranslateY = 0.0,
    this.hoverRotate = 0.0,
    required this.parentHovered,
    required this.staggerIndex,
    this.onPressed,
  });

  @override
  State<_StaggeredHoverIconButton> createState() => _StaggeredHoverIconButtonState();
}

class _StaggeredHoverIconButtonState extends State<_StaggeredHoverIconButton> {
  bool _isButtonHovered = false;
  bool _staggeredActive = false;
  async.Timer? _timer;

  @override
  void didUpdateWidget(covariant _StaggeredHoverIconButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.parentHovered != oldWidget.parentHovered) {
      _timer?.cancel();
      if (widget.parentHovered) {
        _timer = async.Timer(Duration(milliseconds: widget.staggerIndex * 80), () {
          if (mounted) setState(() => _staggeredActive = true);
        });
      } else {
        _staggeredActive = false;
        setState(() {});
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool active = _staggeredActive || _isButtonHovered;
    final Color currentIconColor = _isButtonHovered
        ? (widget.hoverColor ?? Colors.white)
        : (active ? widget.color : widget.color.withOpacity(0.5));
    return MouseRegion(
      onEnter: (_) => setState(() => _isButtonHovered = true),
      onExit: (_) => setState(() => _isButtonHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutBack,
        transform: active
            ? (Matrix4.identity()
              ..translate(0.0, widget.hoverTranslateY)
              ..rotateZ(widget.hoverRotate))
            : Matrix4.identity(),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: (_isButtonHovered && widget.hoverColor != null)
              ? [
                  BoxShadow(
                    color: widget.hoverColor!.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  )
                ]
              : [],
        ),
        child: IconButton(
          icon: Icon(widget.icon, color: currentIconColor),
          onPressed: widget.onPressed,
        ),
      ),
    );
  }
}
