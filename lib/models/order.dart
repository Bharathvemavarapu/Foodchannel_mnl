class OrderModel {
  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final List<OrderItemModel> items;
  final double totalAmount;
  final String deliveryAddress;
  final String paymentMethod;
  final String paymentStatus; // e.g. 'Pending', 'Paid', 'Failed', 'Refunded'
  final String status; // 'Pending', 'Confirmed', 'Packed', 'Shipped', 'Out for Delivery', 'Delivered', 'Cancelled', 'Refunded'
  final DateTime createdDate;
  final List<OrderTimelineEvent> timeline;

  OrderModel({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.items,
    required this.totalAmount,
    required this.deliveryAddress,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.createdDate,
    required this.timeline,
  });

  factory OrderModel.fromJson(String id, Map<String, dynamic> json) {
    var itemsList = (json['items'] as List?)?.map((i) => OrderItemModel.fromJson(Map<String, dynamic>.from(i))).toList() ?? [];
    var timelineList = (json['timeline'] as List?)?.map((t) => OrderTimelineEvent.fromJson(Map<String, dynamic>.from(t))).toList() ?? [];
    
    return OrderModel(
      id: id,
      customerId: json['customerId'] ?? '',
      customerName: json['customerName'] ?? '',
      customerEmail: json['customerEmail'] ?? '',
      customerPhone: json['customerPhone'] ?? '',
      items: itemsList,
      totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryAddress: json['deliveryAddress'] ?? '',
      paymentMethod: json['paymentMethod'] ?? '',
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      status: json['status'] ?? 'Pending',
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate'] as String) : DateTime.now(),
      timeline: timelineList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerPhone': customerPhone,
      'items': items.map((i) => i.toJson()).toList(),
      'totalAmount': totalAmount,
      'deliveryAddress': deliveryAddress,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'createdDate': createdDate.toIso8601String(),
      'timeline': timeline.map((t) => t.toJson()).toList(),
    };
  }
}

class OrderItemModel {
  final String productId;
  final String name;
  final int quantity;
  final double price;

  OrderItemModel({
    required this.productId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    return OrderItemModel(
      productId: json['productId'] ?? '',
      name: json['name'] ?? '',
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'quantity': quantity,
      'price': price,
    };
  }
}

class OrderTimelineEvent {
  final String status;
  final DateTime timestamp;
  final String notes;

  OrderTimelineEvent({
    required this.status,
    required this.timestamp,
    required this.notes,
  });

  factory OrderTimelineEvent.fromJson(Map<String, dynamic> json) {
    return OrderTimelineEvent(
      status: json['status'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      notes: json['notes'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'notes': notes,
    };
  }
}
