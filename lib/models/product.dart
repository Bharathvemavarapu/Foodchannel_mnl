class ProductModel {
  final String id;
  final String name;
  final String description;
  final List<String> imageUrls;
  final double price;
  final double discountPrice;
  final int stock;
  final String brand;
  final String sku;
  final String categoryId;
  final String subCategoryId;
  final bool isAvailable;
  final bool isFeatured;
  final bool isTrending;
  final DateTime createdDate;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrls,
    required this.price,
    required this.discountPrice,
    required this.stock,
    required this.brand,
    required this.sku,
    required this.categoryId,
    required this.subCategoryId,
    required this.isAvailable,
    required this.isFeatured,
    required this.isTrending,
    required this.createdDate,
  });

  factory ProductModel.fromJson(String id, Map<String, dynamic> json) {
    return ProductModel(
      id: id,
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'])
          : [],
      price: (json['price'] ?? 0.0).toDouble(),
      discountPrice: (json['discountPrice'] ?? 0.0).toDouble(),
      stock: json['stock'] ?? 0,
      brand: json['brand'] ?? '',
      sku: json['sku'] ?? '',
      categoryId: json['categoryId'] ?? '',
      subCategoryId: json['subCategoryId'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      isFeatured: json['isFeatured'] ?? false,
      isTrending: json['isTrending'] ?? false,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'imageUrls': imageUrls,
      'price': price,
      'discountPrice': discountPrice,
      'stock': stock,
      'brand': brand,
      'sku': sku,
      'categoryId': categoryId,
      'subCategoryId': subCategoryId,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'isTrending': isTrending,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}
