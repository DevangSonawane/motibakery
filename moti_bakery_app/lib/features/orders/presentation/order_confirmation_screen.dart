import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';

import '../../../app/theme.dart';
import '../../../shared/models/order.dart';

class OrderConfirmationScreen extends StatefulWidget {
  const OrderConfirmationScreen({super.key, required this.order});

  final Order order;

  @override
  State<OrderConfirmationScreen> createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      HapticFeedback.heavyImpact();
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;

    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Order Confirmed'),
        ),
        body: SafeArea(
          child: Stack(
            alignment: Alignment.topCenter,
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 12),
                    Center(
                      child: SizedBox(
                        height: 200,
                        width: 200,
                        child: Lottie.network(
                          'https://assets7.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                          repeat: false,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.check_circle,
                            size: 120,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Order Placed Successfully!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order Summary', style: Theme.of(context).textTheme.headlineLarge),
                            const SizedBox(height: 10),
                            _line(context, 'Order ID', order.id, mono: true),
                            _line(context, 'Cake', '${order.cakeName} (${order.flavour})'),
                            _line(context, 'Weight', '${order.weight.toStringAsFixed(1)} kg'),
                            _line(
                              context,
                              'Delivery',
                              DateFormat('dd MMMM yyyy').format(order.deliveryDate),
                            ),
                            _line(context, 'Total Paid', '₹ ${order.totalPrice.toStringAsFixed(2)}'),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => context.go('/counter'),
                      child: const Text('Place Another Order'),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: () => context.go('/my-orders'),
                      child: const Text('View My Orders'),
                    ),
                  ],
                ),
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 25,
                colors: const [AppColors.primary, AppColors.primaryLight, Colors.white],
                gravity: 0.2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String label, String value, {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 92, child: Text('$label:')),
          Expanded(
            child: SelectableText(
              value,
              style: (mono
                      ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontFamily: 'monospace',
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          )
                      : Theme.of(context).textTheme.bodyLarge)
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
