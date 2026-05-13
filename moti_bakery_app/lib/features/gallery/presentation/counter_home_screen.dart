import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/inventory_provider.dart';
import '../../../shared/services/product_service.dart';
import '../../../shared/widgets/counter_bottom_nav.dart';
import '../../../shared/widgets/counter_logout_button.dart';
import 'product_detail_screen.dart';

class CounterHomeScreen extends ConsumerStatefulWidget {
  const CounterHomeScreen({super.key});

  @override
  ConsumerState<CounterHomeScreen> createState() => _CounterHomeScreenState();
}

class _CounterHomeScreenState extends ConsumerState<CounterHomeScreen> {
  @override
  Widget build(BuildContext context) {
    final productsState = ref.watch(inventoryPagedProductsProvider);
    final filteredProducts = ref.watch(filteredInventoryProductsProvider);
    final categories = ref.watch(inventoryCategoriesProvider);
    final selectedCategory = ref.watch(selectedInventoryCategoryProvider);

    final loadedCount = productsState.valueOrNull?.products.length ?? 0;
    final totalCount = productsState.valueOrNull?.totalCount;
    final pageIndex = productsState.valueOrNull?.pageIndex ?? 0;
    final totalPages = productsState.valueOrNull?.totalPages ?? 1;
    final isLoadingPage = productsState.valueOrNull?.isLoadingPage ?? false;
    final pageError = productsState.valueOrNull?.pageError;

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
                          : 'Page ${pageIndex + 1} of $totalPages • Showing $loadedCount of $totalCount cakes',
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
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: _PaginationBar(
                  currentPage: pageIndex + 1,
                  totalPages: totalPages,
                  isLoading: isLoadingPage,
                  onPageSelected: (page) => ref
                      .read(inventoryPagedProductsProvider.notifier)
                      .goToPage(page),
                  onNext: () =>
                      ref.read(inventoryPagedProductsProvider.notifier).nextPage(),
                  onPrevious: () => ref
                      .read(inventoryPagedProductsProvider.notifier)
                      .previousPage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
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

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.currentPage,
    required this.totalPages,
    required this.isLoading,
    required this.onPageSelected,
    required this.onNext,
    required this.onPrevious,
  });

  final int currentPage;
  final int totalPages;
  final bool isLoading;
  final ValueChanged<int> onPageSelected;
  final VoidCallback onNext;
  final VoidCallback onPrevious;

  @override
  Widget build(BuildContext context) {
    final maxButtons = totalPages < 4 ? totalPages : 4;

    return Row(
      children: [
        IconButton(
          tooltip: 'Previous page',
          onPressed: currentPage > 1 && !isLoading ? onPrevious : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var page = 1; page <= maxButtons; page++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _PageButton(
                      page: page,
                      selected: page == currentPage,
                      onTap: isLoading ? null : () => onPageSelected(page),
                    ),
                  ),
                if (totalPages > 4) ...[
                  const Text('...'),
                  const SizedBox(width: 8),
                  _PageButton(
                    page: totalPages,
                    selected: totalPages == currentPage,
                    onTap: isLoading ? null : () => onPageSelected(totalPages),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isLoading)
          const SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        IconButton(
          tooltip: 'Next page',
          onPressed: currentPage < totalPages && !isLoading ? onNext : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.page,
    required this.selected,
    required this.onTap,
  });

  final int page;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Ink(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: selected ? null : Border.all(color: AppColors.borderLight),
        ),
        child: Center(
          child: Text(
            '$page',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: selected ? Colors.white : colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
