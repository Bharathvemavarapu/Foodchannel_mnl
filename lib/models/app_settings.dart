class AppSettingsModel {
  final String name;
  final String description;
  final String contactNumber;
  final String email;
  final String whatsapp;
  final String logoUrl;

  AppSettingsModel({
    required this.name,
    required this.description,
    required this.contactNumber,
    required this.email,
    required this.whatsapp,
    required this.logoUrl,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contactNumber: json['contactNumber'] ?? '',
      email: json['email'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      logoUrl: json['logoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'contactNumber': contactNumber,
      'email': email,
      'whatsapp': whatsapp,
      'logoUrl': logoUrl,
    };
  }

  factory AppSettingsModel.empty() {
    return AppSettingsModel(
      name: '',
      description: '',
      contactNumber: '',
      email: '',
      whatsapp: '',
      logoUrl: '',
    );
  }
}

class StoreAddressModel {
  final String fullAddress;
  final double latitude;
  final double longitude;

  StoreAddressModel({
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });

  factory StoreAddressModel.fromJson(Map<String, dynamic> json) {
    return StoreAddressModel(
      fullAddress: json['fullAddress'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fullAddress': fullAddress,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory StoreAddressModel.empty() {
    return StoreAddressModel(
      fullAddress: '',
      latitude: 0.0,
      longitude: 0.0,
    );
  }
}
