class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // 'user' or 'admin'
  final DateTime createdDate;
  final DateTime lastLogin;
  final bool isActive;
  final String phone;
  final String address;
  final String profileImage;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.createdDate,
    required this.lastLogin,
    required this.isActive,
    required this.phone,
    this.address = '',
    this.profileImage = '',
  });

  factory UserModel.fromJson(String uid, Map<String, dynamic> json) {
    return UserModel(
      uid: uid,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      createdDate: json['createdDate'] != null 
          ? DateTime.parse(json['createdDate'] as String) 
          : DateTime.now(),
      lastLogin: json['lastLogin'] != null 
          ? DateTime.parse(json['lastLogin'] as String) 
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      profileImage: json['profileImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'createdDate': createdDate.toIso8601String(),
      'lastLogin': lastLogin.toIso8601String(),
      'isActive': isActive,
      'phone': phone,
      'address': address,
      'profileImage': profileImage,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    DateTime? createdDate,
    DateTime? lastLogin,
    bool? isActive,
    String? phone,
    String? address,
    String? profileImage,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      createdDate: createdDate ?? this.createdDate,
      lastLogin: lastLogin ?? this.lastLogin,
      isActive: isActive ?? this.isActive,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      profileImage: profileImage ?? this.profileImage,
    );
  }
}
