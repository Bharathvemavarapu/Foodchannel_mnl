import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/category.dart';
import '../../../services/database_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/glass_card.dart';

class SubcategoriesTab extends StatefulWidget {
  const SubcategoriesTab({super.key});

  @override
  State<SubcategoriesTab> createState() => _SubcategoriesTabState();
}

class _SubcategoriesTabState extends State<SubcategoriesTab> {
  List<CategoryModel> _categories = [];
  List<SubCategoryModel> _subCategories = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        DatabaseService.getCategories(),
        DatabaseService.getSubCategories(),
      ]);
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _subCategories = results[1] as List<SubCategoryModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load subcategories: $e');
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

  String _getParentCategoryName(String categoryId) {
    final cat = _categories.firstWhere((c) => c.id == categoryId, orElse: () => CategoryModel(id: '', name: 'Unknown Category', imageUrl: '', createdDate: DateTime.now()));
    return cat.name;
  }

  void _openAddEditSubCategoryDialog([SubCategoryModel? subCategory]) {
    if (_categories.isEmpty) {
      _showErrorSnackBar('Please create at least one parent category first.');
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _AddEditSubCategoryDialog(
        categories: _categories,
        subCategory: subCategory,
        onSuccess: (msg) {
          _showSuccessSnackBar(msg);
          _loadData();
        },
        onError: _showErrorSnackBar,
      ),
    );
  }

  Future<void> _deleteSubCategory(SubCategoryModel sub) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Sub Category'),
        content: Text('Are you sure you want to delete Sub Category "${sub.name}"?'),
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
        await DatabaseService.deleteSubCategory(sub.id);
        _showSuccessSnackBar('Sub Category deleted successfully.');
        _loadData();
      } catch (e) {
        _showErrorSnackBar('Failed to delete subcategory: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _subCategories.where((sub) {
      final nameMatches = sub.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final parentNameMatches = _getParentCategoryName(sub.categoryId).toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || parentNameMatches;
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
                  const Text('Sub Categories Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Create sub-level structures for granular catalog filtering', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddEditSubCategoryDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADD SUB CATEGORY', style: TextStyle(fontWeight: FontWeight.bold)),
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
              hintText: 'Search sub categories or parent categories...',
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
                    ? const Center(child: Text('No sub categories found.', style: TextStyle(color: Colors.white38)))
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
                                DataColumn(label: Text('Sub Category Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Parent Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Created Date', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredList.map((sub) {
                                return DataRow(cells: [
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(sub.imageUrl, width: 44, height: 44, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, size: 20))),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(_getParentCategoryName(sub.categoryId))),
                                  DataCell(Text(sub.createdDate.toString().split(' ')[0])),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent), onPressed: () => _openAddEditSubCategoryDialog(sub)),
                                        IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _deleteSubCategory(sub)),
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

class _AddEditSubCategoryDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final SubCategoryModel? subCategory;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AddEditSubCategoryDialog({
    required this.categories,
    this.subCategory,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_AddEditSubCategoryDialog> createState() => _AddEditSubCategoryDialogState();
}

class _AddEditSubCategoryDialogState extends State<_AddEditSubCategoryDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  
  String? _selectedParentCategoryId;
  XFile? _pickedImage;
  String? _currentImageUrl;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.subCategory != null) {
      _nameController.text = widget.subCategory!.name;
      _currentImageUrl = widget.subCategory!.imageUrl;
      _selectedParentCategoryId = widget.subCategory!.categoryId;
    } else if (widget.categories.isNotEmpty) {
      _selectedParentCategoryId = widget.categories.first.id;
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

  Future<void> _saveSubCategory() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedParentCategoryId == null) {
      widget.onError('Please select a parent category.');
      return;
    }
    if (_pickedImage == null && _currentImageUrl == null) {
      widget.onError('Please select a subcategory image.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      String finalUrl = _currentImageUrl ?? '';

      if (_pickedImage != null) {
        final bytes = await _pickedImage!.readAsBytes();
        finalUrl = await CloudinaryService.uploadImage(bytes, _pickedImage!.name);
      }

      if (widget.subCategory == null) {
        await DatabaseService.addSubCategory(_selectedParentCategoryId!, _nameController.text.trim(), finalUrl);
        widget.onSuccess('Sub Category added successfully.');
      } else {
        await DatabaseService.updateSubCategory(widget.subCategory!.id, _selectedParentCategoryId!, _nameController.text.trim(), finalUrl);
        widget.onSuccess('Sub Category updated successfully.');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      widget.onError('Failed to save subcategory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.subCategory != null;

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
                isEdit ? 'Edit Sub Category' : 'Add Sub Category',
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
              
              DropdownButtonFormField<String>(
                value: _selectedParentCategoryId,
                dropdownColor: const Color(0xFF150A2E),
                style: const TextStyle(color: Colors.white, fontSize: 15),
                items: widget.categories.map((cat) {
                  return DropdownMenuItem<String>(
                    value: cat.id,
                    child: Text(cat.name, style: const TextStyle(color: Colors.white)),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedParentCategoryId = val;
                  });
                },
                decoration: InputDecoration(
                  labelText: 'Parent Category',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                ),
              ),
              const SizedBox(height: 20),
              
              TextFormField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Sub Category Name',
                  labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFFF8A00))),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter subcategory name';
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
                    onPressed: _isSaving ? null : _saveSubCategory,
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
