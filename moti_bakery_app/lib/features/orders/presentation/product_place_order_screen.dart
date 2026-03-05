import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/models/order.dart';
import '../../../shared/models/product.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../shared/services/order_service.dart';

class ProductOrderArgs {
  const ProductOrderArgs({
    required this.product,
    this.initialVariant,
  });

  final Product product;
  final String? initialVariant;
}

class ProductPlaceOrderScreen extends ConsumerStatefulWidget {
  const ProductPlaceOrderScreen({
    super.key,
    required this.product,
    this.initialVariant,
  });

  final Product product;
  final String? initialVariant;

  @override
  ConsumerState<ProductPlaceOrderScreen> createState() =>
      _ProductPlaceOrderScreenState();
}

class _ProductPlaceOrderScreenState
    extends ConsumerState<ProductPlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  late final List<String> _variants;
  late String _selectedVariant;
  int _quantity = 1;
  DateTime _deliveryDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _variants = widget.product.optionValues;
    if (widget.initialVariant != null && _variants.contains(widget.initialVariant)) {
      _selectedVariant = widget.initialVariant!;
    } else {
      _selectedVariant = _variants.isNotEmpty ? _variants.first : 'Standard';
    }
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _deliveryDate = picked);
    }
  }

  double _unitPrice() {
    return _resolveUnitPrice(widget.product.rate, _selectedVariant);
  }

  double _totalPrice() => _unitPrice() * _quantity;

  double _weightInKg() {
    final variant = _selectedVariant.toLowerCase();
    final number = _extractFirstNumber(variant);
    if (number == null || number <= 0) {
      return _quantity.toDouble();
    }

    if (variant.contains('kg')) {
      return number * _quantity;
    }
    if (variant.contains('gm') ||
        variant.contains('gms') ||
        variant.contains('g')) {
      return (number / 1000) * _quantity;
    }
    return _quantity.toDouble();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    final user = ref.read(authControllerProvider).state.user;
    if (user == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final order = Order(
        id: '#ORD-${now.year}-${1000 + Random().nextInt(8999)}',
        cakeId: widget.product.id,
        cakeName: widget.product.displayTitle,
        flavour: _selectedVariant,
        weight: _weightInKg(),
        deliveryDate: _deliveryDate,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        notes: _buildNotes(),
        totalPrice: _totalPrice(),
        status: OrderStatus.newOrder,
        createdAt: now,
        createdBy: user.id,
      );

      final created = await ref
          .read(orderControllerProvider.notifier)
          .placeOrder(order);
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      context.go('/order-confirmation', extra: created);
    } catch (error) {
      if (!mounted) return;
      final message = error is OrderException
          ? error.message
          : 'Could not place order. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _buildNotes() {
    final raw = _notesController.text.trim();
    final quantityNote = 'Quantity: $_quantity';
    if (raw.isEmpty) {
      return quantityNote;
    }
    return '$quantityNote | $raw';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order Product')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submitOrder,
          child: _isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Confirm Order'),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Text(
              widget.product.displayTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 10),
            Text(
              'Customer Details',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _customerNameController,
              decoration: const InputDecoration(
                labelText: 'Customer Name',
                hintText: 'Enter name',
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return 'Customer name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _customerPhoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Customer Phone',
                hintText: '10-digit phone number',
              ),
              validator: (value) {
                final trimmed = (value ?? '').trim();
                if (trimmed.isEmpty) {
                  return 'Customer phone is required';
                }
                if (trimmed.length < 10) {
                  return 'Enter a valid 10-digit phone';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            if (_variants.length <= 1)
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      _selectedVariant,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedVariant,
                decoration: const InputDecoration(
                  labelText: 'Select variant/value',
                ),
                items: _variants
                    .map(
                      (variant) =>
                          DropdownMenuItem(value: variant, child: Text(variant)),
                    )
                    .toList(growable: false),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedVariant = value);
                  }
                },
              ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: const InputDecoration(
                labelText: 'Quantity',
                hintText: '1',
              ),
              onChanged: (value) {
                final parsed = int.tryParse(value) ?? 1;
                setState(() => _quantity = parsed.clamp(1, 999));
              },
            ),
            const SizedBox(height: 14),
            Text('Delivery Date', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(8),
              child: Ink(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderLight),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 20),
                    const SizedBox(width: 10),
                    Text(DateFormat('dd MMMM yyyy').format(_deliveryDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _notesController,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Special instructions...',
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryPale,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 6),
                  Text('Variant: $_selectedVariant'),
                  Text('Quantity: $_quantity'),
                  Text('Unit Price: ${_currency(_unitPrice())}'),
                  const SizedBox(height: 4),
                  Text(
                    'Total: ${_currency(_totalPrice())}',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _currency(double value) {
    return NumberFormat.currency(
      locale: 'en_IN',
      symbol: '₹ ',
      decimalDigits: 2,
    ).format(value);
  }

  double _resolveUnitPrice(String rate, String variant) {
    final normalizedRate = rate.trim();
    if (normalizedRate.isEmpty || normalizedRate == '-') {
      return 0;
    }

    final segments = normalizedRate.split('|');
    for (final segment in segments) {
      final parts = segment.split(':');
      if (parts.length < 2) continue;

      final key = parts.first.trim().toLowerCase();
      final value = _extractFirstNumber(parts.sublist(1).join(':'));
      if (value == null) continue;

      if (key == variant.toLowerCase()) {
        return value;
      }
    }

    final fallback = _extractFirstNumber(normalizedRate);
    return fallback ?? 0;
  }

  double? _extractFirstNumber(String raw) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }
}
