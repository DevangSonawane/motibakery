import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

final selectedInventoryCategoryProvider = StateProvider<String?>((ref) => null);

class InventoryProductsState {
  const InventoryProductsState({
    required this.products,
    required this.totalCount,
    required this.isLoadingMore,
    required this.hasMore,
    this.loadMoreError,
  });

  final List<Product> products;
  final int totalCount;
  final bool isLoadingMore;
  final bool hasMore;
  final String? loadMoreError;

  InventoryProductsState copyWith({
    List<Product>? products,
    int? totalCount,
    bool? isLoadingMore,
    bool? hasMore,
    String? loadMoreError,
  }) {
    return InventoryProductsState(
      products: products ?? this.products,
      totalCount: totalCount ?? this.totalCount,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      loadMoreError: loadMoreError,
    );
  }
}

final inventoryPagedProductsProvider =
    AsyncNotifierProvider<InventoryPagedProductsNotifier, InventoryProductsState>(
  InventoryPagedProductsNotifier.new,
);

class InventoryPagedProductsNotifier
    extends AsyncNotifier<InventoryProductsState> {
  static const int _pageSize = 60;

  @override
  Future<InventoryProductsState> build() async {
    final service = ref.read(productServiceProvider);
    final first = await service.fetchProductsPageWithCount(
      from: 0,
      to: _pageSize - 1,
    );

    final products = first.data
        .map((row) => Product.fromMap(row as Map<String, dynamic>))
        .toList(growable: false);

    final totalCount = first.count;
    final hasMore = products.length < totalCount;

    return InventoryProductsState(
      products: products,
      totalCount: totalCount,
      isLoadingMore: false,
      hasMore: hasMore,
    );
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isLoadingMore || !current.hasMore) return;

    state = AsyncData(current.copyWith(isLoadingMore: true, loadMoreError: null));

    try {
      final offset = current.products.length;
      final nextProducts = await ref.read(productServiceProvider).fetchProductsPage(
            from: offset,
            to: offset + _pageSize - 1,
          );

      final merged = <Product>[...current.products, ...nextProducts];
      final hasMore = merged.length < current.totalCount;

      state = AsyncData(
        current.copyWith(
          products: merged,
          isLoadingMore: false,
          hasMore: hasMore,
          loadMoreError: null,
        ),
      );
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          loadMoreError: error.toString(),
        ),
      );
    }
  }
}

final inventoryCategoriesProvider = Provider<List<String>>((ref) {
  final products =
      ref.watch(inventoryPagedProductsProvider).valueOrNull?.products ??
          const <Product>[];
  final categories = products
      .map((product) => product.category.trim())
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList();
  categories.sort();
  return categories;
});

final filteredInventoryProductsProvider = Provider<List<Product>>((ref) {
  final products =
      ref.watch(inventoryPagedProductsProvider).valueOrNull?.products ??
          const <Product>[];
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
