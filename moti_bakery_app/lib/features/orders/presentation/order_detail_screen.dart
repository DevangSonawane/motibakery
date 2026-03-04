import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/widgets/status_badge.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                order.id,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontFamily: 'monospace',
                    ),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _line(context, 'Cake', order.cakeName),
                  _line(context, 'Flavour', order.flavour),
                  _line(context, 'Weight', '${order.weight.toStringAsFixed(1)} kg'),
                  _line(
                    context,
                    'Delivery',
                    DateFormat('dd MMM yyyy').format(order.deliveryDate),
                  ),
                  _line(context, 'Customer', order.customerName ?? '-'),
                  _line(context, 'Notes', order.notes ?? '-'),
                  _line(context, 'Total', '₹ ${order.totalPrice.toStringAsFixed(2)}'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 98,
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
