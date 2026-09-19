// The Supabase Dart query builder changes its concrete generic type as filters
// are appended. Keeping the intermediate builder dynamic lets us compose
// optional filters without weakening the public repository API.
// ignore_for_file: avoid_dynamic_calls

import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/item.dart';

class ItemRepository {
  ItemRepository(this._client);

  final SupabaseClient _client;

  Future<List<Item>> fetchRecent({String? query, ItemType? type}) async {
    dynamic request = _client
        .from('items')
        .select('*, categories(name), item_images(public_url)')
        .eq('status', 'ACTIVE');
    if (type != null) {
      request = request.eq(
          'item_type', type == ItemType.lost ? 'LOST' : 'FOUND');
    }
    if (query != null && query.trim().isNotEmpty) {
      final safeQuery = query.trim().replaceAll(',', ' ');
      request = request.or(
        'title.ilike.%$safeQuery%,description.ilike.%$safeQuery%,'
        'location.ilike.%$safeQuery%,brand.ilike.%$safeQuery%,'
        'reference_number.ilike.%$safeQuery%',
      );
    }
    request = request.order('created_at', ascending: false).limit(30);

    final rows = await request;
    return (rows as List)
        .map((row) => Item.fromMap(Map<String, dynamic>.from(row as Map)))
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final rows = await _client
        .from('categories')
        .select('id, name')
        .eq('is_active', true)
        .order('sort_order');
    return (rows as List)
        .map((row) => Map<String, dynamic>.from(row as Map))
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
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('You must be signed in to create a report.');
    }

    final row = await _client.from('items').insert({
      'user_id': userId,
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
    }).select('*, categories(name), item_images(public_url)').single();

    return Item.fromMap(Map<String, dynamic>.from(row));
  }

  Future<String> uploadImage({
    required String itemId,
    required String fileName,
    required List<int> bytes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AuthException('You must be signed in to upload an image.');
    }
    final path = '$userId/$itemId/$fileName';
    await _client.storage.from('item-images').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    final publicUrl = _client.storage.from('item-images').getPublicUrl(path);
    await _client.from('item_images').insert({
      'item_id': itemId,
      'storage_path': path,
      'public_url': publicUrl,
    });
    return publicUrl;
  }
}
