import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../shared/services/order_service.dart';
import '../../../shared/widgets/status_badge.dart';

class OrderDetailScreen extends ConsumerStatefulWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  bool _updating = false;
  Order? _order;

  @override
  void initState() {
    super.initState();
    _order = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final order = _order ?? widget.order;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.transparent,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFFFF2EC), Color(0xFFFFFFFF)],
              ),
            ),
          ),
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.12),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryLight.withValues(alpha: 0.14),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: <Widget>[
                _buildHeroCard(context, order),
                const SizedBox(height: 14),
                _buildSectionCard(
                  context: context,
                  title: 'Cake Details',
                  icon: Icons.cake_outlined,
                  children: [
                    _line(context, 'Cake', order.cakeName),
                    _line(context, 'Weight', '${order.weight.toStringAsFixed(1)} kg'),
                    _line(context, 'Total', '₹ ${order.totalPrice.toStringAsFixed(2)}'),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  context: context,
                  title: 'Delivery',
                  icon: Icons.local_shipping_outlined,
                  children: [
                    _line(
                      context,
                      'Date',
                      DateFormat('EEE, dd MMM yyyy').format(_asIst(order.deliveryDate)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _buildSectionCard(
                  context: context,
                  title: 'Customer',
                  icon: Icons.person_outline,
                  children: [
                    _line(context, 'Name', order.customerName ?? '-'),
                    _line(context, 'Phone', order.customerPhone ?? '-'),
                    _line(context, 'Notes', _userNotesOnly(order.notes)),
                  ],
                ),
                if (order.status == OrderStatus.prepared) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _updating ? null : () => _markDelivered(order),
                    icon: _updating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.task_alt),
                    label: Text(_updating ? 'Updating...' : 'Mark Delivered'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD94F1E), Color(0xFFF28B5B)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order.id,
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '₹ ${order.totalPrice.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: StatusBadge(status: order.status),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 30,
                width: 30,
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.primary, size: 17),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textHint,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DateTime _asIst(DateTime value) {
    return value.toUtc().add(const Duration(hours: 5, minutes: 30));
  }

  String _userNotesOnly(String? notes) {
    final raw = notes?.trim() ?? '';
    if (raw.isEmpty) {
      return '-';
    }

    final quantityPrefix = RegExp(r'^\s*quantity\s*:\s*\d+\s*(\|\s*)?', caseSensitive: false);
    final cleaned = raw.replaceFirst(quantityPrefix, '').trim();
    return cleaned.isEmpty ? '-' : cleaned;
  }

  Future<void> _markDelivered(Order order) async {
    setState(() => _updating = true);
    try {
      await ref
          .read(orderControllerProvider.notifier)
          .updateStatus(order.id, OrderStatus.delivered);
      setState(() => _order = order.copyWith(status: OrderStatus.delivered));
      final user = ref.read(authControllerProvider).state.user;
      if (user != null && mounted) {
        await ref.read(orderControllerProvider.notifier).loadMyOrders(user.id, last15Only: true);
      }
    } catch (error) {
      if (mounted) {
        final message =
            error is OrderException ? error.message : 'Failed to mark order as delivered.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _updating = false);
      }
    }
  }
}
