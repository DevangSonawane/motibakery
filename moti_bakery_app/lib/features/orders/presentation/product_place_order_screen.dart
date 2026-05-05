import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
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
  static const double _weightStepKg = 0.5;

  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final _picker = ImagePicker();

  late final List<String> _variants;
  late String _selectedVariant;
  int _quantity = 1;
  double _selectedWeightKg = 1;
  DateTime _deliveryDate = DateTime.now();
  bool _isSubmitting = false;
  XFile? _referenceImage;

  @override
  void initState() {
    super.initState();
    _variants = widget.product.optionValues;
    if (widget.initialVariant != null && _variants.contains(widget.initialVariant)) {
      _selectedVariant = widget.initialVariant!;
    } else {
      _selectedVariant = _variants.isNotEmpty ? _variants.first : 'Standard';
    }

    final range = widget.product.weightRangeKg;
    final minKg = range.minKg;
    final maxKg = range.maxKg;
    var initialKg = _weightInKg();
    if (minKg != null) initialKg = initialKg < minKg ? minKg : initialKg;
    if (maxKg != null) initialKg = initialKg > maxKg ? maxKg : initialKg;
    if (initialKg <= 0) initialKg = minKg ?? 1;
    initialKg = _snapToStepKg(initialKg);
    if (minKg != null) initialKg = max(initialKg, minKg);
    if (maxKg != null) initialKg = min(initialKg, maxKg);
    _selectedWeightKg = initialKg;
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

  Future<void> _pickReferenceImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cancel'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );

    if (source == null) {
      return;
    }

    final image = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 800,
    );
    if (image != null) {
      setState(() => _referenceImage = image);
    }
  }

  double _unitPrice() {
    return _resolveUnitPrice(widget.product, _selectedVariant);
  }

  double _totalPrice() => _unitPrice() * _quantity;

  double _perUnitWeightKg() {
    final variant = _selectedVariant.toLowerCase();
    final number = _extractFirstNumber(variant);
    if (number == null || number <= 0) {
      return 1;
    }

    if (variant.contains('kg')) {
      return number;
    }
    if (variant.contains('gm') ||
        variant.contains('gms') ||
        variant.contains('g')) {
      return number / 1000;
    }
    return 1;
  }

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

  double _snapToStepKg(double value) {
    return (value / _weightStepKg).round() * _weightStepKg;
  }

  (double, double) _effectiveWeightSliderBoundsKg() {
    final bounds = _weightSliderBoundsKg();
    final rawMinKg = bounds.$1;
    final rawMaxKg = bounds.$2;

    var minKg = (rawMinKg / _weightStepKg).ceil() * _weightStepKg;
    var maxKg = (rawMaxKg / _weightStepKg).floor() * _weightStepKg;

    // Fallback: if the allowed range is too small to fit a full step, keep the
    // raw bounds so the UI still works.
    if (maxKg <= minKg) {
      minKg = rawMinKg;
      maxKg = rawMaxKg;
    }

    return (minKg.toDouble(), maxKg.toDouble());
  }

  (double, double) _weightSliderBoundsKg() {
    final range = widget.product.weightRangeKg;
    final configuredMinKg = range.minKg;
    final configuredMaxKg = range.maxKg;
    final perUnitKg = _perUnitWeightKg();

    final minKg = ((configuredMinKg != null && configuredMinKg > 0)
        ? configuredMinKg
        : (perUnitKg > 0 ? perUnitKg : 1))
        .toDouble();
    var maxKg = (configuredMaxKg != null && configuredMaxKg > 0)
        ? configuredMaxKg
        : (perUnitKg > 0 ? perUnitKg * 10 : 10);
    if (maxKg <= minKg) {
      maxKg = minKg + (perUnitKg > 0 ? perUnitKg : 1);
    }
    return (minKg, maxKg.toDouble());
  }

  double _selectedWeightClampedKg() {
    final bounds = _effectiveWeightSliderBoundsKg();
    return _selectedWeightKg.clamp(bounds.$1, bounds.$2).toDouble();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    final user = ref.read(authControllerProvider).state.user;
    if (user == null) {
      return;
    }

    final range = widget.product.weightRangeKg;
    const epsilon = 1e-6;
    final selectedKg = _selectedWeightClampedKg();
    if (range.minKg != null && selectedKg + epsilon < range.minKg!) {
      final minText = range.minKg!.toStringAsFixed(2);
      final maxText = range.maxKg?.toStringAsFixed(2);
      await _showWeightAlert(
        title: 'Weight too low',
        message:
            maxText == null
                ? 'Please order at least $minText kg.'
                : 'Please order within $minText - $maxText kg.',
      );
      return;
    }
    if (range.maxKg != null && selectedKg - epsilon > range.maxKg!) {
      final minText = range.minKg?.toStringAsFixed(2);
      final maxText = range.maxKg!.toStringAsFixed(2);
      await _showWeightAlert(
        title: 'Weight too high',
        message:
            minText == null
                ? 'Please order no more than $maxText kg.'
                : 'Please order within $minText - $maxText kg.',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final now = DateTime.now();
      final scheduledDate = DateTime(_deliveryDate.year, _deliveryDate.month, _deliveryDate.day);
      final order = Order(
        id: '#ORD-${now.year}-${1000 + Random().nextInt(8999)}',
        cakeId: widget.product.id,
        cakeName: widget.product.displayTitle,
        flavour: _selectedVariant,
        weight: selectedKg,
        deliveryDate: scheduledDate,
        deliveryTime: null,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        notes: _buildNotes(),
        imageUrl: _referenceImage?.path,
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

  Future<void> _showWeightAlert({
    required String title,
    required String message,
  }) async {
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String? _buildNotes() {
    final raw = _notesController.text.trim();
    if (raw.isEmpty) {
      return null;
    }
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    final sliderBounds = _effectiveWeightSliderBoundsKg();
    final sliderMinKg = sliderBounds.$1;
    final sliderMaxKg = sliderBounds.$2;
    final showWeightSlider = sliderMinKg > 0 && sliderMaxKg > sliderMinKg;
    final selectedKg = _selectedWeightClampedKg();

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
                      _variantLabelWithPrice(_selectedVariant),
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
                          DropdownMenuItem(
                            value: variant,
                            child: Text(
                              _variantLabelWithPrice(variant),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
            if (showWeightSlider) ...[
              Text(
                'Weight (kg)',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 8),
              Slider(
                value: selectedKg,
                min: sliderMinKg,
                max: sliderMaxKg,
                divisions:
                    ((sliderMaxKg - sliderMinKg) / _weightStepKg)
                        .round()
                        .clamp(1, 500)
                        .toInt(),
                label: '${selectedKg.toStringAsFixed(1)} kg',
                onChanged: (value) {
                  final snapped = _snapToStepKg(value);
                  setState(() => _selectedWeightKg = snapped);
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${sliderMinKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${sliderMaxKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ],
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
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: _pickReferenceImage,
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('Attach Reference Image'),
            ),
            if (_referenceImage != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  File(_referenceImage!.path),
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 6),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => setState(() => _referenceImage = null),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remove image'),
                ),
              ),
            ],
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
                  Text('Weight: ${selectedKg.toStringAsFixed(2)} kg'),
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

  String _variantLabelWithPrice(String variant) {
    final price = _resolveUnitPrice(widget.product, variant);
    if (price <= 0) return variant;
    return '$variant • ${_currency(price)}';
  }

  double _resolveUnitPrice(Product product, String variant) {
    final normalizedRate = product.rate.trim();
    if (normalizedRate.isEmpty || normalizedRate == '-') {
      return 0;
    }

    final segments = normalizedRate.split('|');
    for (final segment in segments) {
      final parts = _splitKeyValue(segment);
      if (parts == null) continue;
      final key = _normalizeVariant(parts.$1);
      final value = _extractFirstNumber(parts.$2);
      if (key.isEmpty || value == null) continue;
      if (key == _normalizeVariant(variant)) return value;
    }

    final optionPrice = _priceFromOption2Json(product.option2Value, variant);
    if (optionPrice != null) {
      return optionPrice;
    }

    final fallback = _extractFirstNumber(normalizedRate);
    return fallback ?? 0;
  }

  (String, String)? _splitKeyValue(String segment) {
    final trimmed = segment.trim();
    if (trimmed.isEmpty) return null;

    int index = trimmed.indexOf(':');
    String delimiter = ':';
    if (index == -1) {
      index = trimmed.indexOf('=');
      delimiter = '=';
    }
    if (index == -1) {
      index = trimmed.indexOf(' - ');
      delimiter = ' - ';
    }
    if (index == -1) return null;
    final key = trimmed.substring(0, index).trim();
    final value = trimmed.substring(index + delimiter.length).trim();
    return (key, value);
  }

  String _normalizeVariant(String raw) {
    final lower = raw.toLowerCase();
    final buffer = StringBuffer();
    for (final codeUnit in lower.codeUnits) {
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isLower = codeUnit >= 97 && codeUnit <= 122;
      if (isDigit || isLower) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  double? _priceFromOption2Json(String? raw, String variant) {
    final normalizedVariant = _normalizeVariant(variant);
    if (normalizedVariant.isEmpty) return null;
    final value = raw?.trim() ?? '';
    if (value.isEmpty || !(value.startsWith('[') || value.startsWith('{'))) {
      return null;
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return null;
      for (final item in decoded) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? '';
        if (_normalizeVariant(name) != normalizedVariant) continue;
        final price = item['price']?.toString() ?? '';
        final parsed = double.tryParse(price.trim());
        if (parsed != null) return parsed;
      }
    } catch (_) {
      return null;
    }
    return null;
  }

  double? _extractFirstNumber(String raw) {
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (match == null) return null;
    return double.tryParse(match.group(1)!);
  }
}
