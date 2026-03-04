import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../shared/models/cake.dart';
import '../../../shared/models/order.dart';
import '../../../shared/providers/auth_provider.dart';
import '../../../shared/providers/order_provider.dart';
import '../../../shared/providers/pricing_provider.dart';
import '../../../utils/price_calculator.dart';

class PlaceOrderScreen extends ConsumerStatefulWidget {
  const PlaceOrderScreen({super.key, required this.cake});

  final Cake cake;

  @override
  ConsumerState<PlaceOrderScreen> createState() => _PlaceOrderScreenState();
}

class _PlaceOrderScreenState extends ConsumerState<PlaceOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerController = TextEditingController();
  final _notesController = TextEditingController();
  final _weightController = TextEditingController();
  final _picker = ImagePicker();

  late String _selectedFlavour;
  late double _weight;
  DateTime _deliveryDate = DateTime.now();
  bool _isSubmitting = false;
  XFile? _referenceImage;

  @override
  void initState() {
    super.initState();
    _selectedFlavour = widget.cake.flavours.first;
    _weight = widget.cake.minWeight;
    _weightController.text = _weight.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _customerController.dispose();
    _notesController.dispose();
    _weightController.dispose();
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

  void _syncWeight(double value) {
    final next = value.clamp(widget.cake.minWeight, widget.cake.maxWeight);
    setState(() {
      _weight = next;
      _weightController.text = _weight.toStringAsFixed(1);
    });
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

  Future<void> _submit(double totalPrice) async {
    if (!_formKey.currentState!.validate() || _isSubmitting) {
      return;
    }

    final user = ref.read(authControllerProvider).state.user;
    if (user == null) {
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final random = Random();
      final now = DateTime.now();
      final order = Order(
        id: '#ORD-${now.year}-${1000 + random.nextInt(8999)}',
        cakeId: widget.cake.id,
        cakeName: widget.cake.name,
        flavour: _selectedFlavour,
        weight: _weight,
        deliveryDate: _deliveryDate,
        customerName:
            _customerController.text.trim().isEmpty ? null : _customerController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        imageUrl: _referenceImage?.path,
        totalPrice: totalPrice,
        status: OrderStatus.newOrder,
        createdAt: DateTime.now(),
        createdBy: user.id,
      );

      final created = await ref.read(orderControllerProvider.notifier).placeOrder(order);
      if (!mounted) {
        return;
      }
      HapticFeedback.heavyImpact();
      context.go('/order-confirmation', extra: created);
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placement failed. Please retry.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rules = ref.watch(pricingRulesProvider).valueOrNull ?? const [];
    final total = PriceCalculator.calculate(
      baseRate: widget.cake.baseRate ?? 0,
      weight: _weight,
      flavour: _selectedFlavour,
      categories: widget.cake.categories,
      rules: rules,
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Place Order')),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: AppColors.borderLight)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primaryPale,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) => SlideTransition(
                        position:
                            Tween(begin: const Offset(0, 0.35), end: Offset.zero).animate(animation),
                        child: FadeTransition(opacity: animation, child: child),
                      ),
                      child: Text(
                        key: ValueKey<double>(total),
                        NumberFormat.currency(
                          locale: 'en_IN',
                          symbol: '₹ ',
                          decimalDigits: 2,
                        ).format(total),
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _isSubmitting ? null : () => _submit(total),
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
            ],
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '${widget.cake.name} - $_selectedFlavour Flavour',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: 20),
              Text('Weight (kg)', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(hintText: 'Enter weight'),
                validator: (value) {
                  final parsed = double.tryParse(value ?? '');
                  if (parsed == null) {
                    return 'Enter a valid number';
                  }
                  if (parsed < widget.cake.minWeight || parsed > widget.cake.maxWeight) {
                    return 'Allowed range: ${widget.cake.minWeight} - ${widget.cake.maxWeight} kg';
                  }
                  return null;
                },
                onChanged: (value) {
                  final parsed = double.tryParse(value);
                  if (parsed != null) {
                    _syncWeight(parsed);
                  }
                },
              ),
              const SizedBox(height: 8),
              CupertinoSlider(
                value: _weight,
                min: widget.cake.minWeight,
                max: widget.cake.maxWeight,
                divisions: ((widget.cake.maxWeight - widget.cake.minWeight) * 10).round(),
                activeColor: AppColors.primary,
                thumbColor: AppColors.primary,
                onChanged: _syncWeight,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${widget.cake.minWeight} kg', style: Theme.of(context).textTheme.bodySmall),
                  Text('${widget.cake.maxWeight} kg', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedFlavour,
                decoration: const InputDecoration(labelText: 'Select flavour'),
                items: widget.cake.flavours
                    .map((flavour) => DropdownMenuItem(value: flavour, child: Text(flavour)))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedFlavour = value);
                  }
                },
              ),
              const SizedBox(height: 16),
              Text('Delivery Date', style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(8),
                child: Ink(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _customerController,
                decoration: const InputDecoration(
                  labelText: 'Customer Name (optional)',
                  hintText: 'Name...',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 4,
                maxLines: 8,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Special instructions...',
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _pickReferenceImage,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Attach Reference Image'),
              ),
              if (_referenceImage != null) ...[
                const SizedBox(height: 12),
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(_referenceImage!.path),
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      right: 0,
                      child: GestureDetector(
                        onTap: () => setState(() => _referenceImage = null),
                        child: const CircleAvatar(
                          radius: 10,
                          backgroundColor: Colors.black87,
                          child: Icon(Icons.close, size: 12, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
