class BannerModel {
  final String id;
  final String imageUrl;
  final bool isEnabled;
  final DateTime createdDate;

  BannerModel({
    required this.id,
    required this.imageUrl,
    required this.isEnabled,
    required this.createdDate,
  });

  factory BannerModel.fromJson(String id, Map<String, dynamic> json) {
    return BannerModel(
      id: id,
      imageUrl: json['imageUrl'] ?? '',
      isEnabled: json['isEnabled'] ?? true,
      createdDate: json['createdDate'] != null
          ? DateTime.parse(json['createdDate'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'isEnabled': isEnabled,
      'createdDate': createdDate.toIso8601String(),
    };
  }
}

class HeroImageModel {
  final String id;
  final String imageUrl;
  final int sortOrder;

  HeroImageModel({
    required this.id,
    required this.imageUrl,
    required this.sortOrder,
  });

  factory HeroImageModel.fromJson(String id, Map<String, dynamic> json) {
    return HeroImageModel(
      id: id,
      imageUrl: json['imageUrl'] ?? '',
      sortOrder: json['sortOrder'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
    };
  }
}
