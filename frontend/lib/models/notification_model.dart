class NotificationModel {
  final String id;
  final String userId;
  final String alertId;
  final String title;
  final double? price;
  final String? city;
  final String? category;
  final String url;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.alertId,
    required this.title,
    this.price,
    this.city,
    this.category,
    required this.url,
    this.imageUrl,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      alertId: json['alertId'] as String,
      title: json['title'] as String,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      city: json['city'] as String?,
      category: json['category'] as String?,
      url: json['url'] as String,
      imageUrl: json['imageUrl'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
