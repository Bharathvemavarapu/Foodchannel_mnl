class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String type; // 'All Users', 'Selected Users', 'Promotional'
  final List<String> targetUserIds;
  final DateTime? scheduledTime; // null if sent immediately
  final DateTime createdDate;
  final bool isSent;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetUserIds,
    this.scheduledTime,
    required this.createdDate,
    required this.isSent,
  });

  factory NotificationModel.fromJson(String id, Map<String, dynamic> json) {
    return NotificationModel(
      id: id,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? 'All Users',
      targetUserIds: List<String>.from(json['targetUserIds'] ?? []),
      scheduledTime: json['scheduledTime'] != null ? DateTime.parse(json['scheduledTime'] as String) : null,
      createdDate: json['createdDate'] != null ? DateTime.parse(json['createdDate'] as String) : DateTime.now(),
      isSent: json['isSent'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'body': body,
      'type': type,
      'targetUserIds': targetUserIds,
      'scheduledTime': scheduledTime?.toIso8601String(),
      'createdDate': createdDate.toIso8601String(),
      'isSent': isSent,
    };
  }
}
