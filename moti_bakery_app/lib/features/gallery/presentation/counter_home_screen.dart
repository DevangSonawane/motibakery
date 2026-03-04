import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/inventory_provider.dart';
import '../../../shared/services/product_service.dart';
import '../../../shared/widgets/counter_bottom_nav.dart';

class CounterHomeScreen extends ConsumerWidget {
  const CounterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsState = ref.watch(inventoryProductsProvider);
    final filteredProducts = ref.watch(filteredInventoryProductsProvider);
    final categories = ref.watch(inventoryCategoriesProvider);
    final selectedCategory = ref.watch(selectedInventoryCategoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: RichText(
          text: TextSpan(
            style: Theme.of(context).textTheme.displayMedium,
            children: const [
              TextSpan(
                text: 'moti',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
              ),
              TextSpan(
                text: ' bakery',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider).logout(),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      bottomNavigationBar: const CounterBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(inventoryProductsProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search inventory...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(inventorySearchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: selectedCategory == null,
                    onTap: () =>
                        ref.read(selectedInventoryCategoryProvider.notifier).state = null,
                  ),
                  for (final category in categories)
                    _FilterChip(
                      label: category,
                      selected: selectedCategory == category,
                      onTap: () {
                        ref.read(selectedInventoryCategoryProvider.notifier).state = category;
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            productsState.when(
              loading: _buildLoading,
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load inventory: ${_errorMessage(error)}'),
              ),
              data: (_) {
                if (filteredProducts.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.45,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined,
                            size: 80, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No products found',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Try a different search or filter',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredProducts.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final product = filteredProducts[index];
                    return _InventoryCard(product: product, index: index);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoading() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceGray,
          highlightColor: AppColors.borderLight,
          period: 1200.ms,
          child: Container(
            height: 88,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
              color: Colors.white,
            ),
          ),
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

class _InventoryCard extends ConsumerWidget {
  const _InventoryCard({required this.product, required this.index});

  final Product product;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final values = product.optionValues;
    final selected = ref.watch(selectedProductValueProvider(product.id));
    final dropdownValue = selected != null && values.contains(selected)
        ? selected
        : (values.isNotEmpty ? values.first : null);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.displayTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
          ),
          if (!product.isCake && dropdownValue != null) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: dropdownValue,
              decoration: const InputDecoration(
                labelText: 'Value',
                isDense: true,
              ),
              items: values
                  .map(
                    (value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (next) {
                ref.read(selectedProductValueProvider(product.id).notifier).state = next;
              },
            ),
          ],
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: 40 * index))
        .fadeIn(duration: 220.ms)
        .slideY(begin: 0.1, end: 0, duration: 220.ms);
  }
}
