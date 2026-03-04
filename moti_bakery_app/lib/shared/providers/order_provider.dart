import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/order_service.dart';

class OrderController extends StateNotifier<AsyncValue<List<Order>>> {
  OrderController(this._service) : super(const AsyncValue.loading()) {
    loadQueue();
  }

  final OrderService _service;

  Future<void> loadQueue() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_service.fetchQueue);
  }

  Future<void> loadMyOrders(String userId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _service.fetchMyOrders(userId));
  }

  Future<Order> placeOrder(Order order) async {
    final created = await _service.placeOrder(order);
    await loadQueue();
    return created;
  }

  Future<void> updateStatus(String orderId, OrderStatus status) async {
    await _service.updateStatus(orderId: orderId, status: status);
    await loadQueue();
  }
}

final orderServiceProvider = Provider<OrderService>((ref) => OrderService());

final orderControllerProvider =
    StateNotifierProvider<OrderController, AsyncValue<List<Order>>>((ref) {
  return OrderController(ref.watch(orderServiceProvider));
});

final ordersByStatusProvider = Provider.family<List<Order>, OrderStatus>((ref, status) {
  final orders = ref.watch(orderControllerProvider).valueOrNull ?? <Order>[];
  final list = orders.where((order) => order.status == status).toList();

  switch (status) {
    case OrderStatus.newOrder:
      list.sort((a, b) => a.deliveryDate.compareTo(b.deliveryDate));
      break;
    case OrderStatus.inProgress:
      list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      break;
    case OrderStatus.prepared:
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      break;
  }
  return list;
});
