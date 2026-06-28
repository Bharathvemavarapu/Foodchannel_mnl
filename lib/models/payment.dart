class PaymentSettingsModel {
  final GatewayConfig razorpay;
  final GatewayConfig stripe;
  final GatewayConfig cashfree;
  final GatewayConfig phonepe;
  final bool codEnabled;
  final double minOrderAmountForOnline;

  PaymentSettingsModel({
    required this.razorpay,
    required this.stripe,
    required this.cashfree,
    required this.phonepe,
    required this.codEnabled,
    required this.minOrderAmountForOnline,
  });

  factory PaymentSettingsModel.empty() {
    return PaymentSettingsModel(
      razorpay: GatewayConfig.empty(),
      stripe: GatewayConfig.empty(),
      cashfree: GatewayConfig.empty(),
      phonepe: GatewayConfig.empty(),
      codEnabled: true,
      minOrderAmountForOnline: 0.0,
    );
  }

  factory PaymentSettingsModel.fromJson(Map<String, dynamic> json) {
    return PaymentSettingsModel(
      razorpay: GatewayConfig.fromJson(Map<String, dynamic>.from(json['razorpay'] ?? {})),
      stripe: GatewayConfig.fromJson(Map<String, dynamic>.from(json['stripe'] ?? {})),
      cashfree: GatewayConfig.fromJson(Map<String, dynamic>.from(json['cashfree'] ?? {})),
      phonepe: GatewayConfig.fromJson(Map<String, dynamic>.from(json['phonepe'] ?? {})),
      codEnabled: json['codEnabled'] ?? true,
      minOrderAmountForOnline: (json['minOrderAmountForOnline'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razorpay': razorpay.toJson(),
      'stripe': stripe.toJson(),
      'cashfree': cashfree.toJson(),
      'phonepe': phonepe.toJson(),
      'codEnabled': codEnabled,
      'minOrderAmountForOnline': minOrderAmountForOnline,
    };
  }
}

class GatewayConfig {
  final bool isEnabled;
  final String testApiKey;
  final String testApiSecret;
  final String liveApiKey;
  final String liveApiSecret;
  final bool isLiveMode;

  GatewayConfig({
    required this.isEnabled,
    required this.testApiKey,
    required this.testApiSecret,
    required this.liveApiKey,
    required this.liveApiSecret,
    required this.isLiveMode,
  });

  factory GatewayConfig.empty() {
    return GatewayConfig(
      isEnabled: false,
      testApiKey: '',
      testApiSecret: '',
      liveApiKey: '',
      liveApiSecret: '',
      isLiveMode: false,
    );
  }

  factory GatewayConfig.fromJson(Map<String, dynamic> json) {
    return GatewayConfig(
      isEnabled: json['isEnabled'] ?? false,
      testApiKey: json['testApiKey'] ?? '',
      testApiSecret: json['testApiSecret'] ?? '',
      liveApiKey: json['liveApiKey'] ?? '',
      liveApiSecret: json['liveApiSecret'] ?? '',
      isLiveMode: json['isLiveMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'testApiKey': testApiKey,
      'testApiSecret': testApiSecret,
      'liveApiKey': liveApiKey,
      'liveApiSecret': liveApiSecret,
      'isLiveMode': isLiveMode,
    };
  }
}

class PaymentTransactionModel {
  final String id;
  final String orderId;
  final String customerName;
  final String gateway; // 'Razorpay', 'Stripe', etc.
  final double amount;
  final String status; // 'Success', 'Failed', 'Pending', 'Refunded'
  final String transactionId;
  final DateTime timestamp;
  final String errorMessage;

  PaymentTransactionModel({
    required this.id,
    required this.orderId,
    required this.customerName,
    required this.gateway,
    required this.amount,
    required this.status,
    required this.transactionId,
    required this.timestamp,
    this.errorMessage = '',
  });

  factory PaymentTransactionModel.fromJson(String id, Map<String, dynamic> json) {
    return PaymentTransactionModel(
      id: id,
      orderId: json['orderId'] ?? '',
      customerName: json['customerName'] ?? '',
      gateway: json['gateway'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] ?? 'Pending',
      transactionId: json['transactionId'] ?? '',
      timestamp: json['timestamp'] != null ? DateTime.parse(json['timestamp'] as String) : DateTime.now(),
      errorMessage: json['errorMessage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'orderId': orderId,
      'customerName': customerName,
      'gateway': gateway,
      'amount': amount,
      'status': status,
      'transactionId': transactionId,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
    };
  }
}
