class PromoCodeModel {
  final String code;
  final double discountPercentage;
  final double minOrderAmount;
  final bool isActive;

  PromoCodeModel({
    required this.code,
    required this.discountPercentage,
    required this.minOrderAmount,
    required this.isActive,
  });

  factory PromoCodeModel.fromJson(String code, Map<String, dynamic> json) {
    return PromoCodeModel(
      code: code,
      discountPercentage: (json['discountPercentage'] as num?)?.toDouble() ?? 0.0,
      minOrderAmount: (json['minOrderAmount'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'discountPercentage': discountPercentage,
      'minOrderAmount': minOrderAmount,
      'isActive': isActive,
    };
  }
}
