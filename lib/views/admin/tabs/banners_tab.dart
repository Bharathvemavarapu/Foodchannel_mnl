import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/banner_hero.dart';
import '../../../services/database_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/glass_card.dart';

class BannersTab extends StatefulWidget {
  const BannersTab({super.key});

  @override
  State<BannersTab> createState() => _BannersTabState();
}

class _BannersTabState extends State<BannersTab> {
  List<BannerModel> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.getBanners();
      setState(() {
        _banners = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load banners: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _openAddEditBannerDialog([BannerModel? banner]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _AddEditBannerDialog(
        banner: banner,
        onSuccess: (msg) {
          _showSuccessSnackBar(msg);
          _loadBanners();
        },
        onError: _showErrorSnackBar,
      ),
    );
  }

  Future<void> _toggleBannerStatus(BannerModel banner, bool newStatus) async {
    try {
      await DatabaseService.updateBanner(banner.id, banner.imageUrl, newStatus);
      _showSuccessSnackBar('Banner status updated.');
      _loadBanners();
    } catch (e) {
      _showErrorSnackBar('Failed to update banner: $e');
    }
  }

  Future<void> _deleteBanner(BannerModel banner) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Banner'),
        content: const Text('Are you sure you want to delete this promotional banner?'),
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
      try {
        await DatabaseService.deleteBanner(banner.id);
        _showSuccessSnackBar('Banner deleted successfully.');
        _loadBanners();
      } catch (e) {
        _showErrorSnackBar('Failed to delete banner: $e');
      }
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
                  const Text('Promotional Banners', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Upload marketing promo banners to display inside the customer app', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddEditBannerDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADD BANNER', style: TextStyle(fontWeight: FontWeight.bold)),
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
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))))
                : _banners.isEmpty
                    ? const Center(child: Text('No promotional banners configured.', style: TextStyle(color: Colors.white38)))
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          childAspectRatio: 2.1,
                        ),
                        itemCount: _banners.length,
                        itemBuilder: (context, index) {
                          final banner = _banners[index];
                          return GlassCard(
                            padding: EdgeInsets.zero,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Expanded(
                                  child: Image.network(
                                    banner.imageUrl,
                                    width: double.infinity,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 40)),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Switch(
                                            value: banner.isEnabled,
                                            activeColor: const Color(0xFFFF8A00),
                                            onChanged: (val) => _toggleBannerStatus(banner, val),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(banner.isEnabled ? 'Enabled' : 'Disabled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent), onPressed: () => _openAddEditBannerDialog(banner)),
                                          IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _deleteBanner(banner)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
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

class _AddEditBannerDialog extends StatefulWidget {
  final BannerModel? banner;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AddEditBannerDialog({
    this.banner,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_AddEditBannerDialog> createState() => _AddEditBannerDialogState();
}

class _AddEditBannerDialogState extends State<_AddEditBannerDialog> {
  XFile? _pickedImage;
  String? _currentImageUrl;
  bool _isEnabled = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.banner != null) {
      _currentImageUrl = widget.banner!.imageUrl;
      _isEnabled = widget.banner!.isEnabled;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() {
        _pickedImage = img;
      });
    }
  }

  Future<void> _saveBanner() async {
    if (_pickedImage == null && _currentImageUrl == null) {
      widget.onError('Please select a banner image.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      String finalUrl = _currentImageUrl ?? '';

      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        finalUrl = await CloudinaryService.uploadImage(bytes, _pickedImage!.name);
      }

      if (widget.banner == null) {
        await DatabaseService.addBanner(finalUrl, _isEnabled);
        widget.onSuccess('Banner added successfully.');
      } else {
        await DatabaseService.updateBanner(widget.banner!.id, finalUrl, _isEnabled);
        widget.onSuccess('Banner updated successfully.');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      widget.onError('Failed to save banner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.banner != null;

    return Dialog(
      backgroundColor: const Color(0xFF150A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Promotional Banner' : 'Add Promotional Banner',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 24),
            
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: _pickedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(_pickedImage!.path, fit: BoxFit.cover),
                      )
                    : _currentImageUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: Image.network(_currentImageUrl!, fit: BoxFit.cover),
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFF8A00), size: 36),
                              SizedBox(height: 10),
                              Text('Select Promo Banner Image', style: TextStyle(color: Colors.white60, fontSize: 13)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 20),
            
            Row(
              children: [
                Switch(
                  value: _isEnabled,
                  activeColor: const Color(0xFFFF8A00),
                  onChanged: (val) => setState(() => _isEnabled = val),
                ),
                const SizedBox(width: 12),
                const Text('Enable Banner immediately', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
                ),
                const SizedBox(width: 14),
                ElevatedButton(
                  onPressed: _isSaving ? null : _saveBanner,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
                      : Text(isEdit ? 'UPDATE' : 'SAVE', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
