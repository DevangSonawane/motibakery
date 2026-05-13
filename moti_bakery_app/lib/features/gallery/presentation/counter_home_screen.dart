import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../app/theme.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/inventory_provider.dart';
import '../../../shared/services/product_service.dart';
import '../../../shared/utils/product_image_resolver.dart';
import '../../../shared/widgets/counter_bottom_nav.dart';
import '../../../shared/widgets/counter_logout_button.dart';
import 'product_detail_screen.dart';

class CounterHomeScreen extends ConsumerStatefulWidget {
  const CounterHomeScreen({super.key});

  @override
  ConsumerState<CounterHomeScreen> createState() => _CounterHomeScreenState();
}

class _CounterHomeScreenState extends ConsumerState<CounterHomeScreen> {
  final Set<String> _prefetchedImageUrls = <String>{};
  String? _lastPrefetchSignature;
  final ScrollController _scrollController = ScrollController();
  Timer? _loadMoreDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _loadMoreDebounce?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (!position.hasContentDimensions) return;

    // Load next page slightly before reaching the bottom to avoid the "hard stop"
    // feeling while content loads, and debounce rapid scroll updates.
    if (position.extentAfter <= 900) {
      _loadMoreDebounce?.cancel();
      _loadMoreDebounce = Timer(const Duration(milliseconds: 120), () {
        if (!mounted) return;
        ref.read(inventoryPagedProductsProvider.notifier).loadNextPage();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(inventoryPagedProductsProvider);
    final filteredProducts = ref.watch(filteredInventoryProductsProvider);
    final categories = ref.watch(inventoryCategoriesProvider);
    final selectedCategory = ref.watch(selectedInventoryCategoryProvider);

    final loadedCount = productsState.valueOrNull?.products.length ?? 0;
    final totalCount = productsState.valueOrNull?.totalCount;
    final isLoadingPage = productsState.valueOrNull?.isLoadingPage ?? false;
    final pageError = productsState.valueOrNull?.pageError;

    _scheduleImagePrefetch(context, productsState.valueOrNull?.products);

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displayMedium,
            children: const [
              TextSpan(
                text: 'moti',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(
                text: ' bakery',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        actions: const [CounterLogoutButton()],
      ),
      bottomNavigationBar: const CounterBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.read(productServiceProvider).clearCache();
          await ref.read(inventoryPagedProductsProvider.notifier).refresh();
        },
        child: CustomScrollView(
          controller: _scrollController,
          cacheExtent: 2000,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search inventory...',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        ref
                            .read(inventorySearchQueryProvider.notifier)
                            .state = value;
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      totalCount == null
                          ? 'Loaded $loadedCount cakes'
                          : 'Loaded $loadedCount of $totalCount cakes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    if (isLoadingPage) ...[
                      const SizedBox(height: 10),
                      const LinearProgressIndicator(minHeight: 3),
                    ],
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: 'All',
                            selected: selectedCategory == null,
                            onTap: () => ref
                                .read(
                                  selectedInventoryCategoryProvider.notifier,
                                )
                                .state = null,
                          ),
                          for (final category in categories)
                            _FilterChip(
                              label: category,
                              selected: selectedCategory == category,
                              onTap: () {
                                ref
                                    .read(
                                      selectedInventoryCategoryProvider.notifier,
                                    )
                                    .state = category;
                              },
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            productsState.when(
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverToBoxAdapter(child: _buildLoading()),
              ),
              error: (error, _) => SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverToBoxAdapter(
                  child: Text(
                    'Unable to load inventory: ${_errorMessage(error)}',
                  ),
                ),
              ),
              data: (_) {
                if (filteredProducts.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: AppColors.textHint,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No products found',
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try a different search or filter',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  sliver: SliverLayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount =
                          constraints.crossAxisExtent >= 900 ? 3 : 2;

                      return SliverGrid(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = filteredProducts[index];
                            return _InventoryCard(
                              product: product,
                              products: filteredProducts,
                              index: index,
                            );
                          },
                          childCount: filteredProducts.length,
                        ),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: crossAxisCount == 3 ? 0.78 : 0.7,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            if (pageError != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Text(
                    'Unable to load page: $pageError',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.redAccent,
                        ),
                  ),
                ),
              ),
            if (isLoadingPage)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Center(
                    child: SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _scheduleImagePrefetch(BuildContext context, List<Product>? products) {
    if (products == null || products.isEmpty) return;

    final signature = products
        .take(12)
        .map((product) => product.image.trim())
        .where((value) => value.isNotEmpty)
        .join('|');
    if (signature.isEmpty || signature == _lastPrefetchSignature) {
      return;
    }
    _lastPrefetchSignature = signature;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _prefetchImages(context, products);
    });
  }

  Future<void> _prefetchImages(BuildContext context, List<Product> products) async {
    final candidates = <String>[];
    for (final product in products.take(12)) {
      final url = resolveProductImageNetworkUrl(product.image);
      if (url == null) continue;
      if (_prefetchedImageUrls.contains(url)) continue;
      candidates.add(url);
    }

    for (final url in candidates) {
      _prefetchedImageUrls.add(url);
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (_) {
        // Best-effort prefetch; ignore failures.
      }
    }
  }

  Widget _buildLoading() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900 ? 3 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: crossAxisCount * 3,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 3 ? 0.78 : 0.7,
          ),
          itemBuilder: (context, index) {
            return Shimmer.fromColors(
              baseColor: AppColors.surfaceGray,
              highlightColor: AppColors.borderLight,
              period: 1200.ms,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderLight),
                  color: Colors.white,
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _errorMessage(Object error) {
    if (error is ProductException) {
      return error.message;
    }
    return error.toString();
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: selected ? null : Border.all(color: AppColors.borderLight),
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.product,
    required this.products,
    required this.index,
  });

  final Product product;
  final List<Product> products;
  final int index;

  @override
  Widget build(BuildContext context) {
    // Only show product name; no category or variant detail.

    return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => context.push(
              '/product-detail',
              extra: ProductDetailArgs(products: products, initialIndex: index),
            ),
              child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ProductImageView(
                            imagePath: product.image,
                            productName: product.displayTitle,
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.26),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    product.displayTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 280.ms)
        .slideY(
          begin: 0.12,
          end: 0,
          duration: 280.ms,
          curve: Curves.easeOutCubic,
        )
        .scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 280.ms,
          curve: Curves.easeOutBack,
        );
  }

}
