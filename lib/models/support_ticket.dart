class SupportTicketModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String type; // 'Contact Request', 'Complaint', 'Return Request', 'Refund Request'
  final String subject;
  final String message;
  final String? imageUrl;
  final String status; // 'Open', 'In Progress', 'Waiting for Customer', 'Resolved', 'Closed'
  final List<SupportReplyModel> replies;
  final DateTime createdDate;
  final DateTime updatedDate;

  SupportTicketModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.type,
    required this.subject,
    required this.message,
    this.imageUrl,
    required this.status,
    required this.replies,
    required this.createdDate,
    required this.updatedDate,
  });

  factory SupportTicketModel.fromJson(String id, Map<String, dynamic> json) {
    var repliesList = (json['replies'] as List?)?.map((r) => SupportReplyModel.fromJson(Map<String, dynamic>.from(r))).toList() ?? [];
    
    return SupportTicketModel(
      id: id,
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      type: json['type'] ?? 'Contact Request',
      subject: json['subject'] ?? '',
      message: json['message'] ?? '',
      imageUrl: json['imageUrl'],
      status: json['status'] ?? 'Open',
      replies: repliesList,
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate'] as String) : DateTime.now(),
      updatedDate: json['updatedDate'] != null ? DateTime.parse(json['updatedDate'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'type': type,
      'subject': subject,
      'message': message,
      'imageUrl': imageUrl,
      'status': status,
      'replies': replies.map((r) => r.toJson()).toList(),
      'createdDate': createdDate.toIso8601String(),
      'updatedDate': updatedDate.toIso8601String(),
    };
  }
}

class SupportReplyModel {
  final String sender; // 'Admin' or 'Customer'
  final String message;
  final DateTime timestamp;

  SupportReplyModel({
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  factory SupportReplyModel.fromJson(Map<String, dynamic> json) {
    return SupportReplyModel(
      sender: json['sender'] ?? 'Customer',
      message: json['message'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
