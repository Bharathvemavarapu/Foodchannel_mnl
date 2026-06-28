class CategoryModel {
  final String id;
  final String name;
  final String imageUrl;
  final DateTime createdDate;

  CategoryModel({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.createdDate,
  });

  factory CategoryModel.fromJson(String id, Map<String, dynamic> json) {
    return CategoryModel(
      id: id,
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}

class SubCategoryModel {
  final String id;
  final String categoryId;
  final String name;
  final String imageUrl;
  final DateTime createdDate;

  SubCategoryModel({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    required this.createdDate,
  });

  factory SubCategoryModel.fromJson(String id, Map<String, dynamic> json) {
    return SubCategoryModel(
      id: id,
      categoryId: json['categoryId'] ?? '',
      name: json['name'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categoryId': categoryId,
      'name': name,
      'imageUrl': imageUrl,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}
