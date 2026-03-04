import '../models/order.dart';
import 'mock_data.dart';

class OrderService {
  final List<Order> _orders = List<Order>.from(mockOrders);

  Future<List<Order>> fetchMyOrders(String userId) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _orders.where((order) => order.createdBy == userId).toList();
  }

  Future<List<Order>> fetchQueue() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return List<Order>.from(_orders);
  }

  Future<Order> placeOrder(Order order) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _orders.insert(0, order);
    return order;
  }

  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw const OrderException('Order not found');
    }
    final updated = _orders[index].copyWith(status: status);
    _orders[index] = updated;
    return updated;
  }
}

class OrderException implements Exception {
  const OrderException(this.message);
  final String message;
}
