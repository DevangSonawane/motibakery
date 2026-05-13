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
    final first = await _fetchPage(pageIndex: 0);
    return first;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  Future<void> goToPage(int pageNumber) async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (current.isLoadingPage) return;

    final pageIndex = pageNumber - 1;
    if (pageIndex < 0) return;
    if (pageIndex == current.pageIndex) return;
    if (pageIndex >= current.totalPages) return;

    state = AsyncData(
      current.copyWith(isLoadingPage: true, pageError: null),
    );

    try {
      final next = await _fetchPage(pageIndex: pageIndex);
      state = AsyncData(next);
    } catch (error) {
      state = AsyncData(
        current.copyWith(
          isLoadingPage: false,
          pageError: error.toString(),
        ),
      );
    }
  }

  Future<void> nextPage() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasNextPage) return;
    await goToPage(current.pageIndex + 2);
  }

  Future<void> previousPage() async {
    final current = state.valueOrNull;
    if (current == null) return;
    if (!current.hasPreviousPage) return;
    await goToPage(current.pageIndex);
  }

  Future<InventoryProductsState> _fetchPage({required int pageIndex}) async {
    final service = ref.read(productServiceProvider);

    final from = pageIndex * _pageSize;
    final to = from + _pageSize - 1;

    final response = await service.fetchProductsPageWithCount(from: from, to: to);
    final products = response.data
        .map((row) => Product.fromMap(row as Map<String, dynamic>))
        .toList(growable: false);

    return InventoryProductsState(
      products: products,
      totalCount: response.count,
      pageIndex: pageIndex,
      pageSize: _pageSize,
      isLoadingPage: false,
    );
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
