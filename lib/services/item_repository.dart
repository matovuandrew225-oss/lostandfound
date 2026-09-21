import '../models/item.dart';
import 'api_client.dart';

class ItemRepository {
  ItemRepository(this._api);

  final ApiClient _api;

  Future<List<Item>> fetchRecent({String? query, ItemType? type}) async {
    final response = await _api.get('/items', query: {
      'status': 'ACTIVE',
      'limit': '30',
      if (query != null && query.trim().isNotEmpty) 'q': query.trim(),
      if (type != null) 'item_type': type == ItemType.lost ? 'LOST' : 'FOUND',
    });
    final rows = response['data'] as List? ?? response['items'] as List? ?? [];
    return rows
        .map((row) => Item.fromMap((row as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await _api.get('/categories');
    final rows = response['data'] as List? ?? response['categories'] as List? ?? [];
    return rows
        .map((row) => (row as Map).cast<String, dynamic>())
        .toList();
  }

  Future<Item> createItem({
    required ItemType type,
    required String title,
    required String categoryId,
    required String description,
    required DateTime date,
    required String location,
    String? specificLocation,
    String? color,
    String? brand,
    String? model,
  }) async {
    final response = await _api.post('/items', {
      'item_type': type == ItemType.lost ? 'LOST' : 'FOUND',
      'title': title.trim(),
      'category_id': categoryId,
      'description': description.trim(),
      'date_lost_or_found': date.toIso8601String().split('T').first,
      'location': location.trim(),
      'specific_location': specificLocation?.trim(),
      'color': color?.trim(),
      'brand': brand?.trim(),
      'model': model?.trim(),
    });
    return Item.fromMap(_mapData(response));
  }

  Future<String> uploadImage({
    required String itemId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final response = await _api.postMultipart(
      '/items/$itemId/images',
      fileName: fileName,
      bytes: bytes,
      itemId: itemId,
    );
    return (_mapData(response)['url'] as String?) ?? '';
  }

  static Map<String, dynamic> _mapData(Map<String, dynamic> response) {
    final data = response['data'];
    return data is Map
        ? data.cast<String, dynamic>()
        : response['item'] is Map
            ? (response['item'] as Map).cast<String, dynamic>()
            : response;
  }
}
