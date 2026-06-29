class UserAddressModel {
  final String id;
  final String title; // e.g., "Home", "Office"
  final String recipientName;
  final String phone;
  final String fullAddress;

  UserAddressModel({
    required this.id,
    required this.title,
    required this.recipientName,
    required this.phone,
    required this.fullAddress,
  });

  factory UserAddressModel.fromJson(String id, Map<String, dynamic> json) {
    return UserAddressModel(
      id: id,
      title: json['title'] ?? '',
      recipientName: json['recipientName'] ?? '',
      phone: json['phone'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'recipientName': recipientName,
      'phone': phone,
      'fullAddress': fullAddress,
    };
  }
}
