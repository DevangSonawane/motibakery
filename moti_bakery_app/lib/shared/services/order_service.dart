import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import 'supabase_bootstrap.dart';

class OrderService {
  static const _selectColumns =
      'order_id,cake_id,cake_name,flavour,weight,delivery_date,delivery_time,customer_name,customer_phone,notes,reference_image_url,cake_image_url,base_rate_per_kg,flavour_increment_per_kg,total_price,status,created_at,created_by';

  Future<void> _requireConnected() async {
    if (SupabaseBootstrap.result.status == SupabaseBootstrapStatus.connected) {
      return;
    }

    if (SupabaseBootstrap.result.status == SupabaseBootstrapStatus.notConfigured) {
      throw const OrderException(
        'Supabase is not configured. Set SUPABASE_URL and SUPABASE_ANON_KEY.',
      );
    }

    throw OrderException(
      'Supabase connection failed. ${SupabaseBootstrap.result.message ?? ''}'.trim(),
    );
  }

  Future<List<Order>> fetchMyOrders(String userId) async {
    await _requireConnected();
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select(_selectColumns)
          .eq('created_by', userId)
          .order('created_at', ascending: false);
      return rows.map(_mapOrder).toList(growable: false);
    } on PostgrestException catch (error) {
      throw OrderException(error.message);
    } on AuthException catch (error) {
      throw OrderException(error.message);
    } catch (error) {
      throw OrderException(error.toString());
    }
  }

  Future<List<Order>> fetchQueue() async {
    await _requireConnected();
    try {
      final rows = await Supabase.instance.client
          .from('orders')
          .select(_selectColumns)
          .order('created_at', ascending: false);
      return rows.map(_mapOrder).toList(growable: false);
    } on PostgrestException catch (error) {
      throw OrderException(error.message);
    } on AuthException catch (error) {
      throw OrderException(error.message);
    } catch (error) {
      throw OrderException(error.toString());
    }
  }

  Future<Order> placeOrder(Order order) async {
    await _requireConnected();
    try {
      final payload = {
        'order_id': order.id,
        'cake_id': order.cakeId,
        'cake_name': order.cakeName,
        'flavour': order.flavour,
        'weight': order.weight,
        'delivery_date': order.deliveryDate.toIso8601String(),
        'delivery_time': order.deliveryTime?.toIso8601String(),
        'customer_name': order.customerName,
        'customer_phone': order.customerPhone,
        'notes': order.notes,
        'reference_image_url': order.imageUrl,
        'cake_image_url': order.cakeImageUrl,
        'base_rate_per_kg': order.baseRatePerKg,
        // DB column is NOT NULL; default to zero for product orders that do not set this.
        'flavour_increment_per_kg': order.flavourIncrementPerKg ?? 0,
        'total_price': order.totalPrice,
        'status': _statusToDb(order.status),
        'created_at': order.createdAt.toIso8601String(),
        'created_by': order.createdBy,
      };
      final row = await Supabase.instance.client
          .from('orders')
          .insert(payload)
          .select(_selectColumns)
          .single();
      return _mapOrder(row);
    } on PostgrestException catch (error) {
      throw OrderException(error.message);
    } on AuthException catch (error) {
      throw OrderException(error.message);
    } catch (error) {
      throw OrderException(error.toString());
    }
  }

  Future<Order> updateStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    await _requireConnected();
    try {
      final row = await Supabase.instance.client
          .from('orders')
          .update({
            'status': _statusToDb(status),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('order_id', orderId)
          .select(_selectColumns)
          .maybeSingle();

      if (row == null) {
        throw const OrderException('Order not found');
      }
      return _mapOrder(row);
    } on PostgrestException catch (error) {
      throw OrderException(error.message);
    } on AuthException catch (error) {
      throw OrderException(error.message);
    } catch (error) {
      if (error is OrderException) rethrow;
      throw OrderException(error.toString());
    }
  }

  Order _mapOrder(Map<String, dynamic> row) {
    return Order(
      id: row['order_id']?.toString() ?? row['id']?.toString() ?? '',
      cakeId: row['cake_id']?.toString() ?? '',
      cakeName: row['cake_name']?.toString() ?? '',
      flavour: row['flavour']?.toString() ?? '',
      weight: _toDouble(row['weight']),
      deliveryDate: _toDateTime(row['delivery_date']),
      deliveryTime: row['delivery_time'] == null ? null : _toDateTime(row['delivery_time']),
      customerName: row['customer_name']?.toString(),
      customerPhone: row['customer_phone']?.toString(),
      notes: row['notes']?.toString(),
      imageUrl: row['reference_image_url']?.toString(),
      cakeImageUrl: row['cake_image_url']?.toString(),
      baseRatePerKg: row['base_rate_per_kg'] == null ? null : _toDouble(row['base_rate_per_kg']),
      flavourIncrementPerKg: row['flavour_increment_per_kg'] == null
          ? null
          : _toDouble(row['flavour_increment_per_kg']),
      totalPrice: _toDouble(row['total_price']),
      status: _statusFromDb(row['status']?.toString()),
      createdAt: _toDateTime(row['created_at']),
      createdBy: row['created_by']?.toString() ?? '',
    );
  }

  DateTime _toDateTime(dynamic value) {
    if (value is DateTime) {
      return value.toLocal();
    }
    if (value is String) {
      return DateTime.parse(value).toLocal();
    }
    throw const OrderException('Invalid date value from backend.');
  }

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  OrderStatus _statusFromDb(String? value) {
    switch (value?.toLowerCase()) {
      case 'new':
      case 'new_order':
        return OrderStatus.newOrder;
      case 'in_progress':
      case 'inprogress':
        return OrderStatus.inProgress;
      case 'prepared':
        return OrderStatus.prepared;
      default:
        return OrderStatus.newOrder;
    }
  }

  String _statusToDb(OrderStatus status) {
    switch (status) {
      case OrderStatus.newOrder:
        return 'new';
      case OrderStatus.inProgress:
        return 'in_progress';
      case OrderStatus.prepared:
        return 'prepared';
    }
  }
}

class OrderException implements Exception {
  const OrderException(this.message);
  final String message;
}
