import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../shared/widgets/status_badge.dart';

class CakeRoomOrderDetailScreen extends ConsumerStatefulWidget {
  const CakeRoomOrderDetailScreen({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<CakeRoomOrderDetailScreen> createState() =>
      _CakeRoomOrderDetailScreenState();
}

class _CakeRoomOrderDetailScreenState
    extends ConsumerState<CakeRoomOrderDetailScreen> {
  bool _updating = false;

  Future<void> _confirmAndUpdate(OrderStatus status) async {
    final shouldProceed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.88),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '${status == OrderStatus.inProgress ? 'Start preparation for' : 'Mark prepared for'} ${widget.order.id}?',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Confirm'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (shouldProceed != true) {
      return;
    }

    setState(() => _updating = true);
    await ref.read(orderControllerProvider.notifier).updateStatus(widget.order.id, status);
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return Scaffold(
      appBar: AppBar(title: Text('Order ${order.id}')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: switch (order.status) {
          OrderStatus.newOrder => ElevatedButton(
              onPressed: _updating ? null : () => _confirmAndUpdate(OrderStatus.inProgress),
              child: const Text('Start Preparation'),
            ),
          OrderStatus.inProgress => ElevatedButton(
              onPressed: _updating ? null : () => _confirmAndUpdate(OrderStatus.prepared),
              child: const Text('Mark as Prepared'),
            ),
          OrderStatus.prepared => OutlinedButton(
              onPressed: null,
              child: const Text('Already Prepared'),
            ),
        },
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order.id,
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(color: AppColors.primary, fontFamily: 'monospace'),
              ),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 16),
          Text(order.cakeName, style: Theme.of(context).textTheme.displayMedium),
          const SizedBox(height: 8),
          Text(
            'Flavour: ${order.flavour}  |  Weight: ${order.weight.toStringAsFixed(1)} kg',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Delivery: ${DateFormat('dd MMM yyyy, hh:mm a').format(order.deliveryDate)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Customer: ${order.customerName ?? '-'}',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          Text('Notes', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Text(order.notes ?? '-', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Text('Reference Image', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          if (order.imageUrl != null)
            InkWell(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    insetPadding: const EdgeInsets.all(16),
                    child: InteractiveViewer(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(File(order.imageUrl!), fit: BoxFit.contain),
                      ),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(order.imageUrl!),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _imagePlaceholder(),
                ),
              ),
            )
          else
            _imagePlaceholder(),
          const SizedBox(height: 16),
          Text(
            'Total: ₹${order.totalPrice.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.camera_alt_outlined, color: AppColors.textHint, size: 40),
    );
  }
}
