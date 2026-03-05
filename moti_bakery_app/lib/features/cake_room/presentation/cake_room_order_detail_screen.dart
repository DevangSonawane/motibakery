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

  String _displayOrderId(String rawId) {
    return rawId.startsWith('#') ? rawId : '#$rawId';
  }

  String _placedAtText(DateTime createdAt) {
    final now = DateTime.now();
    final isToday = _isSameDate(createdAt, now);
    final isYesterday = _isSameDate(
      createdAt,
      now.subtract(const Duration(days: 1)),
    );
    final dayText = isToday
        ? 'today'
        : isYesterday
        ? 'yesterday'
        : DateFormat('dd MMM yyyy').format(createdAt);
    return 'Placed at ${DateFormat('h:mm a').format(createdAt)} $dayText';
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _deliveryMoment(Order order) {
    if (order.deliveryTime != null) {
      return order.deliveryTime!;
    }
    final hasNoTime =
        order.deliveryDate.hour == 0 &&
        order.deliveryDate.minute == 0 &&
        order.deliveryDate.second == 0;
    if (hasNoTime) {
      return DateTime(
        order.deliveryDate.year,
        order.deliveryDate.month,
        order.deliveryDate.day,
        23,
        59,
      );
    }
    return order.deliveryDate;
  }

  ({Color color, IconData icon, String label}) _deliveryMeta(Order order) {
    final now = DateTime.now();
    final deliveryAt = _deliveryMoment(order);
    if (deliveryAt.isBefore(now)) {
      return (
        color: AppColors.error,
        icon: Icons.error_outline,
        label: 'Overdue',
      );
    }
    final isToday = _isSameDate(deliveryAt, now);
    final isUrgent = isToday && deliveryAt.difference(now).inHours <= 3;
    if (isUrgent) {
      return (
        color: AppColors.warning,
        icon: Icons.priority_high,
        label: 'Urgent today',
      );
    }
    return (
      color: AppColors.textSecondary,
      icon: Icons.schedule_outlined,
      label: 'Scheduled',
    );
  }

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
                    '${status == OrderStatus.inProgress ? 'Start preparation for' : 'Mark as prepared for'} ${_displayOrderId(widget.order.id)}?',
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
    try {
      await ref
          .read(orderControllerProvider.notifier)
          .updateStatus(widget.order.id, status);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update order status.')),
        );
      }
    }
  }

  void _openReferenceViewer(String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Reference Image'),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: _buildImage(imagePath, fit: BoxFit.contain),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String path, {required BoxFit fit}) {
    final uri = Uri.tryParse(path);
    final isHttp = uri != null &&
        (uri.scheme.toLowerCase() == 'http' || uri.scheme.toLowerCase() == 'https');

    if (isHttp) {
      return Image.network(
        path,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _imagePlaceholder(
          text: 'Unable to load image',
          icon: Icons.broken_image_outlined,
        ),
      );
    }

    return Image.file(
      File(path),
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _imagePlaceholder(
        text: 'Unable to load image',
        icon: Icons.broken_image_outlined,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final deliveryMeta = _deliveryMeta(order);
    final baseRate = order.baseRatePerKg ?? (order.totalPrice / order.weight);
    final flavourIncrement = order.flavourIncrementPerKg ?? 0;
    final displayOrderId = _displayOrderId(order.id);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Detail')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: order.status == OrderStatus.prepared
            ? Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.statusPreparedBg,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.statusPrepared),
                    const SizedBox(width: 8),
                    Text(
                      'This order is ready for pickup',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.statusPrepared,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              )
            : ElevatedButton(
                onPressed: _updating
                    ? null
                    : () => _confirmAndUpdate(
                        order.status == OrderStatus.newOrder
                            ? OrderStatus.inProgress
                            : OrderStatus.prepared,
                      ),
                child: Text(
                  order.status == OrderStatus.newOrder
                      ? 'Start Preparation'
                      : 'Mark as Prepared',
                ),
              ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  displayOrderId,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              StatusBadge(status: order.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            _placedAtText(order.createdAt),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  order.cakeName,
                  style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (order.cakeImageUrl != null) ...[
                const SizedBox(width: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: _buildImage(order.cakeImageUrl!, fit: BoxFit.cover),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Preparation Specs',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _specLine(
                  context,
                  label: 'Flavour',
                  value: order.flavour,
                  emphasize: true,
                ),
                const SizedBox(height: 10),
                _specLine(
                  context,
                  label: 'Weight',
                  value: '${order.weight.toStringAsFixed(1)} kg',
                  emphasize: true,
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(deliveryMeta.icon, size: 18, color: deliveryMeta.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Delivery: ${DateFormat('dd MMM yyyy, h:mm a').format(_deliveryMoment(order))}  •  ${deliveryMeta.label}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: deliveryMeta.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _specLine(
                  context,
                  label: 'Customer Name',
                  value: order.customerName?.trim().isNotEmpty == true
                      ? order.customerName!
                      : '-',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text('Notes', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryPale,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
            ),
            child: Text(
              order.notes?.trim().isNotEmpty == true
                  ? order.notes!
                  : 'No special instructions provided.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Reference Image',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 8),
          if (order.imageUrl?.trim().isNotEmpty == true)
            InkWell(
              onTap: () => _openReferenceViewer(order.imageUrl!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: double.infinity,
                  height: 240,
                  child: _buildImage(order.imageUrl!, fit: BoxFit.cover),
                ),
              ),
            )
          else
            _imagePlaceholder(
              text: 'No reference image attached',
              icon: Icons.image_not_supported_outlined,
            ),
          const SizedBox(height: 18),
          Text('Pricing Info', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceGray,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _priceRow(
                  context,
                  label: 'Base Rate',
                  value: '₹${baseRate.toStringAsFixed(0)} /kg',
                ),
                _priceRow(
                  context,
                  label: 'Flavour Increment',
                  value: '₹${flavourIncrement.toStringAsFixed(0)} /kg',
                ),
                _priceRow(
                  context,
                  label: 'Weight',
                  value: '${order.weight.toStringAsFixed(1)} kg',
                ),
                const Divider(height: 14),
                _priceRow(
                  context,
                  label: 'Total',
                  value: '₹${order.totalPrice.toStringAsFixed(2)}',
                  emphasize: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _specLine(
    BuildContext context, {
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceRow(
    BuildContext context, {
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: emphasize ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder({required String text, required IconData icon}) {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surfaceGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppColors.textHint,
            size: 38,
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textHint,
            ),
          ),
        ],
      ),
    );
  }
}
