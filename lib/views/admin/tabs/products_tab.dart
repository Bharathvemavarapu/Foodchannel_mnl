import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../services/database_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../widgets/glass_card.dart';

class ProductsTab extends StatefulWidget {
  const ProductsTab({super.key});

  @override
  State<ProductsTab> createState() => _ProductsTabState();
}

class _ProductsTabState extends State<ProductsTab> {
  List<CategoryModel> _categories = [];
  List<SubCategoryModel> _subCategories = [];
  List<ProductModel> _products = [];
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
        DatabaseService.getProducts(),
      ]);
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _subCategories = results[1] as List<SubCategoryModel>;
        _products = results[2] as List<ProductModel>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load products: $e');
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

  String _getCategoryName(String id) {
    return _categories.firstWhere((c) => c.id == id, orElse: () => CategoryModel(id: '', name: 'Unknown', imageUrl: '', createdDate: DateTime.now())).name;
  }

  String _getSubCategoryName(String id) {
    return _subCategories.firstWhere((s) => s.id == id, orElse: () => SubCategoryModel(id: '', categoryId: '', name: 'Unknown', imageUrl: '', createdDate: DateTime.now())).name;
  }

  void _openAddEditProductDialog([ProductModel? product]) {
    if (_categories.isEmpty) {
      _showErrorSnackBar('Please create a parent category first.');
      return;
    }
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => _AddEditProductDialog(
        categories: _categories,
        subCategories: _subCategories,
        product: product,
        onSuccess: (msg) {
          _showSuccessSnackBar(msg);
          _loadData();
        },
        onError: _showErrorSnackBar,
      ),
    );
  }

  Future<void> _deleteProduct(ProductModel prod) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete Product "${prod.name}"?'),
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
        await DatabaseService.deleteProduct(prod.id);
        _showSuccessSnackBar('Product deleted successfully.');
        _loadData();
      } catch (e) {
        _showErrorSnackBar('Failed to delete product: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _products.where((p) {
      final nameMatches = p.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final brandMatches = p.brand.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || brandMatches;
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
                  const Text('Products Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(height: 6),
                  Text('Add, edit, or delete items in the store catalogue', style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13)),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _openAddEditProductDialog(),
                icon: const Icon(Icons.add_rounded),
                label: const Text('ADD PRODUCT', style: TextStyle(fontWeight: FontWeight.bold)),
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
              hintText: 'Search products by name or brand...',
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
                    ? const Center(child: Text('No products found.', style: TextStyle(color: Colors.white38)))
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
                                DataColumn(label: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Sub Category', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Stock', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                              ],
                              rows: filteredList.map((prod) {
                                return DataRow(cells: [
                                  DataCell(
                                    Padding(
                                      padding: const EdgeInsets.all(6.0),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          prod.imageUrls.isNotEmpty ? prod.imageUrls.first : '',
                                          width: 44,
                                          height: 44,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image, size: 20)),
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(prod.name, style: const TextStyle(fontWeight: FontWeight.bold))),
                                  DataCell(Text(_getCategoryName(prod.categoryId))),
                                  DataCell(Text(_getSubCategoryName(prod.subCategoryId))),
                                  DataCell(Text('₹${prod.price}')),
                                  DataCell(Text('${prod.stock}')),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: prod.isAvailable ? Colors.green.withValues(alpha: 0.15) : Colors.red.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        prod.isAvailable ? 'In Stock' : 'Out of Stock',
                                        style: TextStyle(
                                          color: prod.isAvailable ? Colors.green : Colors.redAccent,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Row(
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit_rounded, color: Colors.blueAccent), onPressed: () => _openAddEditProductDialog(prod)),
                                        IconButton(icon: const Icon(Icons.delete_rounded, color: Colors.redAccent), onPressed: () => _deleteProduct(prod)),
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

class _AddEditProductDialog extends StatefulWidget {
  final List<CategoryModel> categories;
  final List<SubCategoryModel> subCategories;
  final ProductModel? product;
  final Function(String) onSuccess;
  final Function(String) onError;

  const _AddEditProductDialog({
    required this.categories,
    required this.subCategories,
    this.product,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_AddEditProductDialog> createState() => _AddEditProductDialogState();
}

class _AddEditProductDialogState extends State<_AddEditProductDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _discountPriceController = TextEditingController();
  final _stockController = TextEditingController();
  final _brandController = TextEditingController();
  final _skuController = TextEditingController();

  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  bool _isAvailable = true;
  bool _isFeatured = false;
  bool _isTrending = false;
  
  List<XFile> _pickedImages = [];
  List<String> _currentImageUrls = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _descriptionController.text = widget.product!.description;
      _priceController.text = widget.product!.price.toString();
      _discountPriceController.text = widget.product!.discountPrice.toString();
      _stockController.text = widget.product!.stock.toString();
      _brandController.text = widget.product!.brand;
      _skuController.text = widget.product!.sku;
      _isAvailable = widget.product!.isAvailable;
      _isFeatured = widget.product!.isFeatured;
      _isTrending = widget.product!.isTrending;
      _currentImageUrls = List<String>.from(widget.product!.imageUrls);
      _selectedCategoryId = widget.product!.categoryId;
      _selectedSubCategoryId = widget.product!.subCategoryId;
    } else {
      if (widget.categories.isNotEmpty) {
        _selectedCategoryId = widget.categories.first.id;
        _updateSubcategoryList();
      }
    }
  }

  void _updateSubcategoryList() {
    final filtered = widget.subCategories.where((s) => s.categoryId == _selectedCategoryId).toList();
    if (filtered.isNotEmpty) {
      _selectedSubCategoryId = filtered.first.id;
    } else {
      _selectedSubCategoryId = null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _stockController.dispose();
    _brandController.dispose();
    _skuController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final imgs = await picker.pickMultiImage();
    if (imgs.isNotEmpty) {
      setState(() {
        _pickedImages = imgs;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null || _selectedSubCategoryId == null) {
      widget.onError('Please select Category and Sub Category.');
      return;
    }
    if (_pickedImages.isEmpty && _currentImageUrls.isEmpty) {
      widget.onError('Please upload at least one image.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final List<String> uploadedUrls = List<String>.from(_currentImageUrls);

      // Upload newly picked images in parallel
      if (_pickedImages.isNotEmpty) {
        final uploadFutures = _pickedImages.map((img) async {
          final bytes = await img.readAsBytes();
          return await CloudinaryService.uploadImage(bytes, img.name);
        });
        final results = await Future.wait(uploadFutures);
        uploadedUrls.addAll(results);
      }

      final double price = double.tryParse(_priceController.text) ?? 0.0;
      final double discount = double.tryParse(_discountPriceController.text) ?? 0.0;
      final int stock = int.tryParse(_stockController.text) ?? 0;

      final productData = ProductModel(
        id: widget.product?.id ?? '',
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        imageUrls: uploadedUrls,
        price: price,
        discountPrice: discount,
        stock: stock,
        brand: _brandController.text.trim(),
        sku: _skuController.text.trim(),
        categoryId: _selectedCategoryId!,
        subCategoryId: _selectedSubCategoryId!,
        isAvailable: _isAvailable,
        isFeatured: _isFeatured,
        isTrending: _isTrending,
        createdDate: widget.product?.createdDate ?? DateTime.now(),
      );

      if (widget.product == null) {
        await DatabaseService.addProduct(productData);
        widget.onSuccess('Product added successfully.');
      } else {
        await DatabaseService.updateProduct(widget.product!.id, productData);
        widget.onSuccess('Product updated successfully.');
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _isSaving = false);
      widget.onError('Failed to save product: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.product != null;
    final subcategoriesForCat = widget.subCategories.where((s) => s.categoryId == _selectedCategoryId).toList();

    return Dialog(
      backgroundColor: const Color(0xFF150A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        height: MediaQuery.of(context).size.height * 0.85,
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                isEdit ? 'Edit Product' : 'Add Product',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 20),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Multi Image Picker Preview
                      Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                        ),
                        child: _pickedImages.isNotEmpty || _currentImageUrls.isNotEmpty
                            ? ListView(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(8),
                                children: [
                                  ..._currentImageUrls.map((url) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(url, width: 80, height: 80, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _currentImageUrls.remove(url);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  ..._pickedImages.map((img) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(img.path, width: 80, height: 80, fit: BoxFit.cover),
                                        ),
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: GestureDetector(
                                            onTap: () {
                                              setState(() {
                                                _pickedImages.remove(img);
                                              });
                                            },
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: const BoxDecoration(
                                                color: Colors.black54,
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.close_rounded,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                  GestureDetector(
                                    onTap: _pickImages,
                                    child: Container(
                                      width: 80,
                                      decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                                      child: const Icon(Icons.add_photo_alternate_rounded, color: Color(0xFFFF8A00)),
                                    ),
                                  ),
                                ],
                              )
                            : GestureDetector(
                                onTap: _pickImages,
                                behavior: HitTestBehavior.opaque,
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_a_photo_rounded, color: Color(0xFFFF8A00), size: 24),
                                    SizedBox(width: 12),
                                    Text('Upload Product Images (Multiple)', style: TextStyle(color: Colors.white60, fontSize: 13)),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Categories Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedCategoryId,
                              dropdownColor: const Color(0xFF150A2E),
                              style: const TextStyle(color: Colors.white),
                              items: widget.categories.map((cat) => DropdownMenuItem(value: cat.id, child: Text(cat.name))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedCategoryId = val;
                                  _updateSubcategoryList();
                                });
                              },
                              decoration: const InputDecoration(labelText: 'Category', labelStyle: TextStyle(color: Colors.white70)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _selectedSubCategoryId,
                              dropdownColor: const Color(0xFF150A2E),
                              style: const TextStyle(color: Colors.white),
                              items: subcategoriesForCat.map((sub) => DropdownMenuItem(value: sub.id, child: Text(sub.name))).toList(),
                              onChanged: (val) {
                                setState(() {
                                  _selectedSubCategoryId = val;
                                });
                              },
                              decoration: const InputDecoration(labelText: 'Sub Category', labelStyle: TextStyle(color: Colors.white70)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      TextFormField(
                        controller: _nameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Product Name', labelStyle: TextStyle(color: Colors.white70)),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter name' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white70)),
                        validator: (val) => val == null || val.trim().isEmpty ? 'Enter description' : null,
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Price (₹)', labelStyle: TextStyle(color: Colors.white70)),
                              validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid price' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _discountPriceController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Discount Price (₹)', labelStyle: TextStyle(color: Colors.white70)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Stock Qty', labelStyle: TextStyle(color: Colors.white70)),
                              validator: (val) => val == null || int.tryParse(val) == null ? 'Invalid stock' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'Brand', labelStyle: TextStyle(color: Colors.white70)),
                              validator: (val) => val == null || val.isEmpty ? 'Enter brand' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _skuController,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(labelText: 'SKU', labelStyle: TextStyle(color: Colors.white70)),
                              validator: (val) => val == null || val.isEmpty ? 'Enter SKU' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Checkboxes Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: _isAvailable,
                                onChanged: (val) => setState(() => _isAvailable = val ?? true),
                              ),
                              const Text('In Stock'),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _isFeatured,
                                onChanged: (val) => setState(() => _isFeatured = val ?? false),
                              ),
                              const Text('Featured'),
                            ],
                          ),
                          Row(
                            children: [
                              Checkbox(
                                value: _isTrending,
                                onChanged: (val) => setState(() => _isTrending = val ?? false),
                              ),
                              const Text('Trending'),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('CANCEL', style: TextStyle(color: Colors.white60)),
                  ),
                  const SizedBox(width: 14),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveProduct,
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
