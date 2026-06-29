import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/banner_hero.dart';
import '../../../services/database_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/glass_card.dart';

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
                            child: GlassCard(
                              padding: EdgeInsets.zero,
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 220,
                                    child: ClipRRect(
                                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(24)),
                                      child: AspectRatio(
                                        aspectRatio: 16 / 9,
                                        child: Image.network(
                                          item.imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Sort Order: ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        const SizedBox(height: 8),
                                        SelectableText(
                                          item.imageUrl,
                                          style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.arrow_upward_rounded, color: Colors.white70),
                                          onPressed: index == 0 ? null : () => _reorderImage(index, -1),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.arrow_downward_rounded, color: Colors.white70),
                                          onPressed: index == _heroImages.length - 1 ? null : () => _reorderImage(index, 1),
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          icon: const Icon(Icons.delete_rounded, color: Colors.redAccent),
                                          onPressed: () => _deleteHeroImage(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
