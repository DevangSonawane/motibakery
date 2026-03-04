import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

final selectedInventoryCategoryProvider = StateProvider<String?>((ref) => null);

final inventoryProductsProvider = FutureProvider<List<Product>>((ref) async {
  return ref.watch(productServiceProvider).fetchProducts();
});

final inventoryCategoriesProvider = Provider<List<String>>((ref) {
  final products = ref.watch(inventoryProductsProvider).valueOrNull ?? const <Product>[];
  final categories = products
      .map((product) => product.category.trim())
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList();
  categories.sort();
  return categories;
});

final filteredInventoryProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(inventoryProductsProvider).valueOrNull ?? const <Product>[];
  final query = ref.watch(inventorySearchQueryProvider).trim().toLowerCase();
  final selectedCategory = ref.watch(selectedInventoryCategoryProvider);

  return products.where((product) {
    final matchesQuery = query.isEmpty ||
        product.displayTitle.toLowerCase().contains(query) ||
        product.handle.toLowerCase().contains(query);
    final matchesCategory =
        selectedCategory == null || product.category == selectedCategory;
    return matchesQuery && matchesCategory;
  }).toList(growable: false);
});

final selectedProductValueProvider =
    StateProvider.family<String?, String>((ref, productId) => null);
