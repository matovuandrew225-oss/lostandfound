enum ItemType { lost, found }

enum ItemStatus { active, pendingClaim, matched, claimed, recovered, closed, removed }

class Item {
  const Item({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.title,
    required this.description,
    required this.category,
    required this.location,
    required this.date,
    required this.referenceNumber,
    required this.status,
    this.imageUrl,
    this.color,
    this.brand,
    this.model,
    this.specificLocation,
    this.createdAt,
  });

  final String id;
  final String userId;
  final ItemType itemType;
  final String title;
  final String description;
  final String category;
  final String location;
  final DateTime date;
  final String referenceNumber;
  final ItemStatus status;
  final String? imageUrl;
  final String? color;
  final String? brand;
  final String? model;
  final String? specificLocation;
  final DateTime? createdAt;

  bool get isLost => itemType == ItemType.lost;
  String get typeLabel => isLost ? 'LOST' : 'FOUND';

  factory Item.fromMap(Map<String, dynamic> map) {
    final categoryData = map['categories'];
    return Item(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      itemType: _parseType(map['item_type'] as String?),
      title: map['title'] as String? ?? 'Untitled item',
      description: map['description'] as String? ?? '',
      category: categoryData is Map
          ? categoryData['name'] as String? ?? 'Other'
          : map['category'] as String? ?? 'Other',
      location: map['location'] as String? ?? 'Location not provided',
      date: DateTime.tryParse(map['date_lost_or_found'] as String? ?? '') ??
          DateTime.now(),
      referenceNumber: map['reference_number'] as String? ?? 'Pending',
      status: _parseStatus(map['status'] as String?),
      imageUrl: _firstImage(map['item_images']),
      color: map['color'] as String?,
      brand: map['brand'] as String?,
      model: map['model'] as String?,
      specificLocation: map['specific_location'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? ''),
    );
  }

  static String? _firstImage(dynamic value) {
    if (value is List && value.isNotEmpty && value.first is Map) {
      return (value.first as Map)['public_url'] as String?;
    }
    return null;
  }

  static ItemType _parseType(String? value) =>
      value == 'FOUND' ? ItemType.found : ItemType.lost;

  static ItemStatus _parseStatus(String? value) {
    final normalized = value?.replaceAll('_', '').toUpperCase();
    return ItemStatus.values.firstWhere(
      (status) => status.name.toUpperCase() == normalized,
      orElse: () => ItemStatus.active,
    );
  }

  Map<String, dynamic> toInsert({
    required String userId,
    required String categoryId,
  }) {
    return {
      'user_id': userId,
      'item_type': itemType == ItemType.lost ? 'LOST' : 'FOUND',
      'title': title,
      'category_id': categoryId,
      'description': description,
      'date_lost_or_found': date.toIso8601String().split('T').first,
      'location': location,
      'specific_location': specificLocation,
      'color': color,
      'brand': brand,
      'model': model,
      'status': 'ACTIVE',
    };
  }
}
