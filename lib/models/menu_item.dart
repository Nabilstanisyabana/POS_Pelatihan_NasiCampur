import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    this.description = '',
    this.emoji = '🍽️',
    this.imageUrl = '',
    required this.isAvailable,
    required this.createdAt,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? createdAt;

  final String id;
  final String name;
  final String category;
  final int price;
  final String description;
  final String emoji;
  final String imageUrl;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime updatedAt;

  MenuItem copyWith({
    String? id,
    String? name,
    String? category,
    int? price,
    String? description,
    String? emoji,
    String? imageUrl,
    bool? isAvailable,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MenuItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      price: price ?? this.price,
      description: description ?? this.description,
      emoji: emoji ?? this.emoji,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailable: isAvailable ?? this.isAvailable,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'category': category,
    'price': price,
    'description': description,
    'emoji': emoji,
    'imageUrl': imageUrl,
    'isAvailable': isAvailable,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory MenuItem.fromMap(String id, Map<String, dynamic> map) {
    return MenuItem(
      id: id,
      name: (map['name'] as String?)?.trim() ?? 'Tanpa nama',
      category: (map['category'] as String?)?.trim().isNotEmpty == true
          ? (map['category'] as String).trim()
          : 'Lainnya',
      price: _toInt(map['price']),
      description: (map['description'] as String?)?.trim() ?? '',
      emoji: (map['emoji'] as String?)?.trim().isNotEmpty == true
          ? (map['emoji'] as String).trim()
          : '🍽️',
      imageUrl: (map['imageUrl'] as String?)?.trim() ?? '',
      isAvailable: map['isAvailable'] is bool ? map['isAvailable'] as bool : true,
      createdAt: _toDate(map['createdAt']),
      updatedAt: _toDate(map['updatedAt'] ?? map['createdAt']),
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value') ?? 0;
  }

  static DateTime _toDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
