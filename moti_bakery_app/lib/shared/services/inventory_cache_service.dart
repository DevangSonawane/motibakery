import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class InventoryCachePayload {
  const InventoryCachePayload({
    required this.products,
    required this.totalCount,
    required this.savedAt,
  });

  final List<Product> products;
  final int totalCount;
  final DateTime savedAt;
}

class InventoryCacheService {
  static String _productsKey(int pageIndex) =>
      'inventory_cache_v1_products_page_$pageIndex';
  static String _totalCountKey(int pageIndex) =>
      'inventory_cache_v1_total_count_page_$pageIndex';
  static String _savedAtKey(int pageIndex) =>
      'inventory_cache_v1_saved_at_ms_page_$pageIndex';

  static const Duration maxAge = Duration(hours: 12);

  Future<InventoryCachePayload?> readPageIfFresh(int pageIndex) async {
    final prefs = await SharedPreferences.getInstance();
    final savedAtMs = prefs.getInt(_savedAtKey(pageIndex));
    if (savedAtMs == null) return null;

    final savedAt = DateTime.fromMillisecondsSinceEpoch(savedAtMs);
    if (DateTime.now().difference(savedAt) > maxAge) {
      return null;
    }

    final productsJson = prefs.getString(_productsKey(pageIndex));
    final totalCount = prefs.getInt(_totalCountKey(pageIndex));
    if (productsJson == null || totalCount == null) return null;

    try {
      final decoded = jsonDecode(productsJson);
      if (decoded is! List) return null;
      final products = decoded
          .whereType<Map>()
          .map((item) => Product.fromMap(item.cast<String, dynamic>()))
          .toList(growable: false);
      return InventoryCachePayload(
        products: products,
        totalCount: totalCount,
        savedAt: savedAt,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> write({
    required int pageIndex,
    required List<Product> products,
    required int totalCount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode(products.map((product) => product.toMap()).toList());
    await prefs.setString(_productsKey(pageIndex), payload);
    await prefs.setInt(_totalCountKey(pageIndex), totalCount);
    await prefs.setInt(
      _savedAtKey(pageIndex),
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clear({int? pageIndex}) async {
    final prefs = await SharedPreferences.getInstance();
    if (pageIndex != null) {
      await prefs.remove(_productsKey(pageIndex));
      await prefs.remove(_totalCountKey(pageIndex));
      await prefs.remove(_savedAtKey(pageIndex));
      return;
    }

    // Best-effort: clear a handful of recently visited pages.
    for (var index = 0; index < 10; index++) {
      await prefs.remove(_productsKey(index));
      await prefs.remove(_totalCountKey(index));
      await prefs.remove(_savedAtKey(index));
    }
  }
}
