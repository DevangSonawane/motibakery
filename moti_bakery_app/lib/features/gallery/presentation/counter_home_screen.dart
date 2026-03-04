import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

import '../../../app/theme.dart';
import '../../../shared/models/cake.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/gallery_provider.dart';
import '../../../shared/widgets/counter_bottom_nav.dart';

class CounterHomeScreen extends ConsumerWidget {
  const CounterHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cakesState = ref.watch(cakesProvider);
    final filtered = ref.watch(filteredCakesProvider);
    final categories = ref.watch(categoriesProvider);
    final selected = ref.watch(selectedCategoriesProvider);

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
            onPressed: () {},
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: () => ref.read(authControllerProvider).logout(),
            icon: const Icon(Icons.person_outline),
          ),
        ],
      ),
      bottomNavigationBar: const CounterBottomNav(currentIndex: 0),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.refresh(cakesProvider.future),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search cakes...',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _CategoryChip(
                    label: 'All',
                    selected: selected.isEmpty,
                    onTap: () =>
                        ref.read(selectedCategoriesProvider.notifier).state = <String>{},
                  ),
                  for (final category in categories)
                    _CategoryChip(
                      label: category,
                      selected: selected.contains(category),
                      onTap: () {
                        ref.read(selectedCategoriesProvider.notifier).state = <String>{
                          category,
                        };
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            cakesState.when(
              loading: _buildLoading,
              error: (error, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Unable to load cakes: $error'),
              ),
              data: (_) {
                if (filtered.isEmpty) {
                  return SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.45,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.cake_outlined, size: 80, color: AppColors.textHint),
                        const SizedBox(height: 12),
                        Text('No cakes found', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Try a different search or filter',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemBuilder: (context, index) {
                    final cake = filtered[index];
                    return _CakeCard(cake: cake, index: index);
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 4,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.68,
      ),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: AppColors.surfaceGray,
          highlightColor: AppColors.borderLight,
          period: 1200.ms,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderLight),
              color: Colors.white,
            ),
          ),
        );
      },
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
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

class _CakeCard extends StatelessWidget {
  const _CakeCard({required this.cake, required this.index});

  final Cake cake;
  final int index;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/cake-detail', extra: cake),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 7,
              child: Hero(
                tag: 'cake_image_${cake.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: CachedNetworkImage(
                    imageUrl: cake.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorWidget: (context, url, error) => const ColoredBox(
                      color: AppColors.primaryPale,
                      child: Icon(Icons.cake, color: AppColors.primary),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      cake.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            height: 1.15,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${cake.minWeight} kg - ${cake.maxWeight} kg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.2,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹${(cake.baseRate ?? 0).toStringAsFixed(0)}/kg',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            height: 1.2,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      )
          .animate(delay: Duration(milliseconds: 60 * index))
          .fadeIn(duration: 250.ms)
          .slideY(begin: 0.2, end: 0, duration: 250.ms),
    );
  }
}
