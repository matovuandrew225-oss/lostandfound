import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found/models/item.dart';

void main() {
  group('Item', () {
    test('parses a lost item and nested category/image data', () {
      final item = Item.fromMap({
        'id': 'item-1',
        'user_id': 'user-1',
        'item_type': 'LOST',
        'title': 'Blue notebook',
        'description': 'Ruled pages',
        'date_lost_or_found': '2026-09-19',
        'location': 'Library',
        'reference_number': 'LF-2026-000001',
        'status': 'ACTIVE',
        'categories': {'name': 'Books'},
        'item_images': [
          {'public_url': 'https://example.com/notebook.jpg'},
        ],
      });

      expect(item.isLost, isTrue);
      expect(item.category, 'Books');
      expect(item.referenceNumber, 'LF-2026-000001');
      expect(item.imageUrl, 'https://example.com/notebook.jpg');
    });

    test('defaults malformed status to active', () {
      final item = Item.fromMap({
        'id': 'item-1',
        'user_id': 'user-1',
        'item_type': 'FOUND',
        'title': 'Keys',
        'description': '',
        'date_lost_or_found': 'not-a-date',
        'location': 'Hall',
        'status': 'UNKNOWN',
      });

      expect(item.itemType, ItemType.found);
      expect(item.status, ItemStatus.active);
    });
  });
}
