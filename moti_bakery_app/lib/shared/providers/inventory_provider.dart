import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/inventory_cache_service.dart';
import '../services/product_service.dart';

final productServiceProvider = Provider<ProductService>((ref) => ProductService());
final inventoryCacheServiceProvider =
    Provider<InventoryCacheService>((ref) => InventoryCacheService());

final inventorySearchQueryProvider = StateProvider<String>((ref) => '');

final selectedInventoryCategoryProvider = StateProvider<String?>((ref) => null);

class InventoryProductsState {
  const InventoryProductsState({
    required this.products,
    required this.totalCount,
    required this.pageIndex,
    required this.pageSize,
    required this.isLoadingPage,
    this.pageError,
  });

  final List<Product> products;
  final int totalCount;
  final int pageIndex;
  final int pageSize;
  final bool isLoadingPage;
  final String? pageError;

  int get totalPages {
    if (totalCount <= 0) return 1;
    return (totalCount / pageSize).ceil();
  }

  bool get hasPreviousPage => pageIndex > 0;
  bool get hasNextPage => pageIndex + 1 < totalPages;

  InventoryProductsState copyWith({
    List<Product>? products,
    int? totalCount,
    int? pageIndex,
    int? pageSize,
    bool? isLoadingPage,
    String? pageError,
  }) {
    return InventoryProductsState(
      products: products ?? this.products,
      totalCount: totalCount ?? this.totalCount,
      pageIndex: pageIndex ?? this.pageIndex,
      pageSize: pageSize ?? this.pageSize,
      isLoadingPage: isLoadingPage ?? this.isLoadingPage,
      pageError: pageError,
    );
  }
}

final inventoryPagedProductsProvider =
    AsyncNotifierProvider<InventoryPagedProductsNotifier, InventoryProductsState>(
  InventoryPagedProductsNotifier.new,
);

class InventoryPagedProductsNotifier
    extends AsyncNotifier<InventoryProductsState> {
  static const int _pageSize = 10;

  @override
  Future<InventoryProductsState> build() async {
    final cache = await ref.read(inventoryCacheServiceProvider).readPageIfFresh(0);
    if (cache != null) {
      final cachedState = InventoryProductsState(
        products: cache.products,
        totalCount: cache.totalCount,
        pageIndex: 0,
        pageSize: _pageSize,
        isLoadingPage: false,
      );
      unawaited(_refreshFirstPageInBackground());
      return cachedState;
    }

    final first = await _fetchPage(pageIndex: 0);
    return first;
  }

  Future<void> refresh() async {
    await ref.read(inventoryCacheServiceProvider).clear();
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Infinite scroll: appends the next page onto the existing list.
  Future<void> loadNextPage() async {
    final initial = state.valueOrNull;
    if (initial == null) return;
    if (initial.isLoadingPage) return;
    if (!initial.hasNextPage) return;

    final nextPageIndex = initial.pageIndex + 1;

    state = AsyncData(initial.copyWith(isLoadingPage: true, pageError: null));

    final cache = ref.read(inventoryCacheServiceProvider);
    final cached = await cache.readPageIfFresh(nextPageIndex);
    if (cached != null) {
      final latest = state.valueOrNull ?? initial;
      final merged = <Product>[...latest.products, ...cached.products];
      state = AsyncData(
        latest.copyWith(
          products: merged,
          totalCount: cached.totalCount,
          pageIndex: nextPageIndex,
          isLoadingPage: false,
        ),
      );
      unawaited(_refreshPageInBackground(pageIndex: nextPageIndex));
      return;
    }

    try {
      final next = await _fetchPage(pageIndex: nextPageIndex);
      final latest = state.valueOrNull ?? initial;
      final merged = <Product>[...latest.products, ...next.products];
      state = AsyncData(
        latest.copyWith(
          products: merged,
          totalCount: next.totalCount,
          pageIndex: nextPageIndex,
          isLoadingPage: false,
        ),
      );
    } catch (error) {
      state = AsyncData(
        initial.copyWith(
          isLoadingPage: false,
          pageError: error.toString(),
        ),
      );
    }
  }

  Future<InventoryProductsState> _fetchPage({required int pageIndex}) async {
    final service = ref.read(productServiceProvider);
    final cache = ref.read(inventoryCacheServiceProvider);

    final from = pageIndex * _pageSize;
    final to = from + _pageSize - 1;

    final response = await service.fetchProductsPageWithCount(from: from, to: to);
    final products = response.data
        .map((row) => Product.fromMap(row as Map<String, dynamic>))
        .toList(growable: false);

    unawaited(
      cache.write(
        pageIndex: pageIndex,
        products: products,
        totalCount: response.count,
      ),
    );

    return InventoryProductsState(
      products: products,
      totalCount: response.count,
      pageIndex: pageIndex,
      pageSize: _pageSize,
      isLoadingPage: false,
    );
  }

  Future<void> _refreshFirstPageInBackground() async {
    final startState = state.valueOrNull;
    if (startState == null) return;
    if (startState.isLoadingPage) return;
    if (startState.pageIndex != 0) return;
    if (startState.products.length > _pageSize) return;

    try {
      final next = await _fetchPage(pageIndex: 0);
      final latest = state.valueOrNull;
      if (latest == null) return;
      if (latest.products.length > _pageSize) return;
      try {
        state = AsyncData(next);
      } catch (_) {
        // Ignore updates after disposal.
      }
    } catch (_) {
      // Keep cached data if the network fetch fails.
    }
  }

  Future<void> _refreshPageInBackground({required int pageIndex}) async {
    final startState = state.valueOrNull;
    if (startState == null) return;
    if (startState.isLoadingPage) return;
    if (pageIndex < 0) return;
    if (pageIndex > startState.pageIndex) return;

    try {
      final refreshed = await _fetchPage(pageIndex: pageIndex);

      final start = pageIndex * _pageSize;
      final latest = state.valueOrNull;
      if (latest == null) return;
      if (latest.isLoadingPage) return;
      if (start >= latest.products.length) return;

      final before = latest.products.take(start).toList(growable: false);
      final afterStart = start + refreshed.products.length;
      final after = afterStart < latest.products.length
          ? latest.products.sublist(afterStart)
          : const <Product>[];

      final merged = <Product>[...before, ...refreshed.products, ...after];

      try {
        state = AsyncData(
          latest.copyWith(
            products: merged,
            totalCount: refreshed.totalCount,
          ),
        );
      } catch (_) {
        // Ignore updates after disposal.
      }
    } catch (_) {
      // Keep cached data if the network fetch fails.
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
