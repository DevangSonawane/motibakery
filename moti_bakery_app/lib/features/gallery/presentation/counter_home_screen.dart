import 'dart:async';

import 'package:flutter/material.dart';
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
          // Too-large cacheExtent forces lots of offscreen build/layout/image
          // decode work while flinging. Keep it moderate for smoother scroll.
          cacheExtent: 1200,
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
                              key: ValueKey(product.id),
                              product: product,
                              products: filteredProducts,
                              index: index,
                            );
                          },
                          childCount: filteredProducts.length,
                          addAutomaticKeepAlives: false,
                          addRepaintBoundaries: true,
                          addSemanticIndexes: false,
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
        // Prefetch newly appended items, not just the first page.
        // Using the tail avoids a bug where prefetch never re-runs after
        // pagination because the first items stay the same.
        .reversed
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
    for (final product in products.reversed.take(12)) {
      final url = resolveProductImageNetworkUrl(product.image);
      if (url == null) continue;
      if (_prefetchedImageUrls.contains(url)) continue;
      candidates.add(url);
    }

    // Prefetch concurrently (bounded) so slow connections don't serialize each
    // image fetch and block the whole prefetch window.
    if (candidates.isEmpty) return;
    var nextIndex = 0;
    // Keep this low to avoid competing with scrolling/decoding work.
    final workerCount = candidates.length < 2 ? candidates.length : 2;

    Future<void> worker() async {
      while (mounted) {
        final current = nextIndex;
        if (current >= candidates.length) return;
        nextIndex = current + 1;

        final url = candidates[current];
        _prefetchedImageUrls.add(url);
        try {
          await precacheImage(CachedNetworkImageProvider(url), context);
        } catch (_) {
          // Best-effort prefetch; ignore failures.
        }
      }
    }

    await Future.wait(List<Future<void>>.generate(workerCount, (_) => worker()));
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
              period: const Duration(milliseconds: 1200),
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
    super.key,
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

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(
        '/product-detail',
        extra: ProductDetailArgs(products: products, initialIndex: index),
      ),
      child: Container(
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
                clipBehavior: Clip.hardEdge,
                child: Container(
                  foregroundDecoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.26),
                      ],
                    ),
                  ),
                  child: _ProductThumbnailView(
                    imagePath: product.image,
                    fit: BoxFit.cover,
                  ),
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
    );
  }

}

class _ProductThumbnailView extends StatelessWidget {
  const _ProductThumbnailView({
    required this.imagePath,
    required this.fit,
  });

  final String imagePath;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final url = resolveProductImageNetworkUrl(imagePath);
    if (url == null) {
      return const ColoredBox(color: AppColors.surfaceGray);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final dpr = MediaQuery.devicePixelRatioOf(context);
        final cacheWidth = constraints.hasBoundedWidth && constraints.maxWidth.isFinite
            ? (constraints.maxWidth * dpr).round().clamp(1, 1200)
            : null;
        final cacheHeight =
            constraints.hasBoundedHeight && constraints.maxHeight.isFinite
                ? (constraints.maxHeight * dpr).round().clamp(1, 1200)
                : null;

        final baseProvider = CachedNetworkImageProvider(url);
        final ImageProvider provider = (cacheWidth != null || cacheHeight != null)
            ? ResizeImage(baseProvider, width: cacheWidth, height: cacheHeight)
            : baseProvider;

        return Image(
          image: provider,
          fit: fit,
          gaplessPlayback: true,
          filterQuality: FilterQuality.none,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded || frame != null) return child;
            return const ColoredBox(color: AppColors.surfaceGray);
          },
          errorBuilder: (context, error, stackTrace) =>
              const ColoredBox(color: AppColors.surfaceGray),
        );
      },
    );
  }
}
