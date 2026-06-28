import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/category.dart';
import '../../../services/database_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/glass_card.dart';

class CategoriesTab extends StatefulWidget {
  const CategoriesTab({super.key});

  @override
  State<CategoriesTab> createState() => _CategoriesTabState();
}

class _CategoriesTabState extends State<CategoriesTab> {
  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final list = await DatabaseService.getCategories();
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load categories: $e');
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

  void _openAddEditCategoryDialog([CategoryModel? category]) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _AddEditCategoryDialog(
        category: category,
        onSuccess: (msg) {
          _showSuccessSnackBar(msg);
          _loadCategories();
        },
        onError: _showErrorSnackBar,
      ),
    );
  }

  Future<void> _deleteCategory(CategoryModel cat) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete Category "${cat.name}"?'),
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
        await DatabaseService.deleteCategory(cat.id);
        _showSuccessSnackBar('Category deleted successfully.');
        _loadCategories();
      } catch (e) {
        _showErrorSnackBar('Failed to delete category: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _categories.where((cat) {
      return cat.name.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

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
                  const Text('Categories Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Manage product categories & upload catalog artwork', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddEditCategoryDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADD CATEGORY', style: TextStyle(fontWeight: FontWeight.bold)),
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
          
          // Search & Filter
          TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search categories...',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
              prefixIcon: const Icon(Icons.search_rounded, color: Colors.white60),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.02),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Color(0xFFFF8A00))))
                : filteredList.isEmpty
                    ? const Center(child: Text('No categories found.', style: TextStyle(color: Colors.white38)))
                    : GlassCard(
                        padding: EdgeInsets.zero,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: WidgetStateProperty.all(Colors.white.withValues(alpha: 0.02)),
                              columns: const [
                                DataColumn(label: Text('Image', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Category Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredList.map((cat) {
                                return DataRow(cells: [
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(cat.imageUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, size: 20))),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(cat.createdDate.toString().split(' ')[0])),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent), onPressed: () => _openAddEditCategoryDialog(cat)),
                                        IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _deleteCategory(cat)),
                                      ],
                                    ),
                                  ),
                                ]);
                              }).toList(),
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

class _AddEditCategoryDialog extends StatefulWidget {
  final CategoryModel? category;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AddEditCategoryDialog({
    this.category,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_AddEditCategoryDialog> createState() => _AddEditCategoryDialogState();
}

class _AddEditCategoryDialogState extends State<_AddEditCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  XFile? _pickedImage;
  String? _currentImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _nameController.text = widget.category!.name;
      _currentImageUrl = widget.category!.imageUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pickedImage == null && _currentImageUrl == null) {
      widget.onError('Please select a category image.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalUrl = _currentImageUrl ?? '';

      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        finalUrl = await CloudinaryService.uploadImage(bytes, _pickedImage!.name);
      }

      if (widget.category == null) {
        await DatabaseService.addCategory(_nameController.text.trim(), finalUrl);
        widget.onSuccess('Category added successfully.');
      } else {
        await DatabaseService.updateCategory(widget.category!.id, _nameController.text.trim(), finalUrl);
        widget.onSuccess('Category updated successfully.');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      widget.onError('Failed to save category: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.category != null;

    return Dialog(
      backgroundColor: const Color(0xFF150A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Category' : 'Add Category',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 24),
              
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    width: 120,
                    height: 120,
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
                                  Icon(Icons.add_a_photo_rounded, color: Color(0xFFFF8A00), size: 28),
                                  SizedBox(height: 8),
                                  Text('Pick Image', style: TextStyle(color: Colors.white60, fontSize: 11)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter category name';
                  return null;
                },
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
                    onPressed: _isSaving ? null : _saveCategory,
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
      ),
    );
  }
}
