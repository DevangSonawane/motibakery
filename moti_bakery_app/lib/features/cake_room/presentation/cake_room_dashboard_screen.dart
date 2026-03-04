import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../shared/widgets/status_badge.dart';

class CakeRoomDashboardScreen extends ConsumerStatefulWidget {
  const CakeRoomDashboardScreen({super.key});

  @override
  ConsumerState<CakeRoomDashboardScreen> createState() =>
      _CakeRoomDashboardScreenState();
}

class _CakeRoomDashboardScreenState extends ConsumerState<CakeRoomDashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 3, vsync: this);
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderControllerProvider.notifier).loadQueue();
    });
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (mounted) {
        ref.read(orderControllerProvider.notifier).loadQueue();
      }
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderControllerProvider);
    final totalActive = (state.valueOrNull ?? const <Order>[])
        .where((o) => o.status != OrderStatus.prepared)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cake Room'),
        actions: [
          IconButton(
            onPressed: () => ref.read(authControllerProvider).logout(),
            icon: const Icon(Icons.logout_outlined),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textHint,
              tabs: [
                Tab(text: 'New (${ref.watch(ordersByStatusProvider(OrderStatus.newOrder)).length})'),
                Tab(
                  text:
                      'In Progress (${ref.watch(ordersByStatusProvider(OrderStatus.inProgress)).length})',
                ),
                Tab(text: 'Prepared (${ref.watch(ordersByStatusProvider(OrderStatus.prepared)).length})'),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Text(
              '$totalActive Active Orders',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: state.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (error, _) => Center(child: Text('Error: $error')),
              data: (_) => TabBarView(
                controller: _tabController,
                children: const <Widget>[
                  _OrderList(status: OrderStatus.newOrder),
                  _OrderList(status: OrderStatus.inProgress),
                  _OrderList(status: OrderStatus.prepared),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends ConsumerWidget {
  const _OrderList({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersByStatusProvider(status));

    if (orders.isEmpty) {
      return const Center(child: Text('No orders in this tab.'));
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => ref.read(orderControllerProvider.notifier).loadQueue(),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        itemCount: orders.length,
        separatorBuilder: (context, index) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final order = orders[index];
          final urgent = order.deliveryDate.difference(DateTime.now()).inHours <= 8;
          final overdue = order.deliveryDate.isBefore(DateTime.now()) &&
              status != OrderStatus.prepared;
          final borderColor = overdue
              ? AppColors.error
              : urgent
                  ? AppColors.warning
                  : AppColors.borderLight;

          return InkWell(
            onTap: () => context.push('/cake-room/order-detail', extra: order),
            borderRadius: BorderRadius.circular(12),
            child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: borderColor, width: 4)),
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
                  Row(
                    children: [
                      Text(
                        order.id,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontFamily: 'monospace',
                              color: AppColors.primary,
                            ),
                      ),
                      const Spacer(),
                      StatusBadge(status: order.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${order.cakeName} - ${order.weight.toStringAsFixed(1)} kg',
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${order.flavour} • Delivery: ${DateFormat('dd MMM, hh:mm a').format(order.deliveryDate)}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: overdue
                              ? AppColors.error
                              : urgent
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
