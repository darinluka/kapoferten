class AlertModel {
  final String id;
  final String userId;
  final String title;
  final String? keyword;
  final double? minPrice;
  final double? maxPrice;
  final String? city;
  final String? category;
  final bool isActive;
  final DateTime createdAt;

  AlertModel({
    required this.id,
    required this.userId,
    required this.title,
    this.keyword,
    this.minPrice,
    this.maxPrice,
    this.city,
    this.category,
    required this.isActive,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      keyword: json['keyword'] as String?,
      minPrice: json['minPrice'] != null ? (json['minPrice'] as num).toDouble() : null,
      maxPrice: json['maxPrice'] != null ? (json['maxPrice'] as num).toDouble() : null,
      city: json['city'] as String?,
      category: json['category'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'keyword': keyword,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'city': city,
      'category': category,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
