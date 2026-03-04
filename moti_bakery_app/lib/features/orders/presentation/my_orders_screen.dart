import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../shared/widgets/counter_bottom_nav.dart';
import '../../../shared/widgets/status_badge.dart';

class MyOrdersScreen extends ConsumerStatefulWidget {
  const MyOrdersScreen({super.key});

  @override
  ConsumerState<MyOrdersScreen> createState() => _MyOrdersScreenState();
}

class _MyOrdersScreenState extends ConsumerState<MyOrdersScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadOrders());
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _loadOrders());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    final user = ref.read(authControllerProvider).state.user;
    if (user != null && mounted) {
      await ref.read(orderControllerProvider.notifier).loadMyOrders(user.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(orderControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      bottomNavigationBar: const CounterBottomNav(currentIndex: 1),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _loadOrders,
        child: ordersState.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (error, _) => Center(child: Text('Error: $error')),
          data: (orders) {
            if (orders.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.sizeOf(context).height * 0.5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.assignment_outlined,
                            size: 60, color: AppColors.textHint),
                        const SizedBox(height: 10),
                        Text('No orders yet', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Browse the gallery to place your first order',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.go('/counter'),
                          child: const Text('Go to Gallery'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final order = orders[index];
                return InkWell(
                  onTap: () => context.push('/order-detail', extra: order),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.id,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      fontFamily: 'monospace',
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                order.cakeName,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${order.weight.toStringAsFixed(1)} kg • ${order.flavour} • ${DateFormat('dd MMM').format(order.deliveryDate)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: order.status),
                      ],
                    ),
                  ),
                )
                    .animate(delay: Duration(milliseconds: 40 * index))
                    .fadeIn(duration: 200.ms)
                    .slideX(begin: 0.03, end: 0, duration: 200.ms);
              },
            );
          },
        ),
      ),
    );
  }
}
