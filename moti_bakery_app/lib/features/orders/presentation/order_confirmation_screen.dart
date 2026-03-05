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
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  late final ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
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
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width < 360 ? 16.0 : 24.0;
    final topSpacing = size.height < 700 ? 4.0 : 12.0;
    final lottieSize = size.width < 360 ? 150.0 : 200.0;

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
              LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  padding: EdgeInsets.all(horizontalPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SizedBox(height: topSpacing),
                        Center(
                          child: SizedBox(
                            height: lottieSize,
                            width: lottieSize,
                            child: Lottie.network(
                              'https://assets7.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                              repeat: false,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(
                                    Icons.check_circle,
                                    size: 120,
                                    color: AppColors.primary,
                                  ),
                            ),
                          ),
                        ),
                        SizedBox(height: size.height < 700 ? 8 : 12),
                        Text(
                          'Order Placed Successfully!',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.displayMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Order Summary',
                                  style: Theme.of(context).textTheme.headlineLarge,
                                ),
                                const SizedBox(height: 10),
                                _line(context, 'Order ID', order.id, mono: true),
                                _line(
                                  context,
                                  'Cake',
                                  '${order.cakeName} (${order.flavour})',
                                ),
                                _line(
                                  context,
                                  'Weight',
                                  '${order.weight.toStringAsFixed(1)} kg',
                                ),
                                _line(
                                  context,
                                  'Delivery',
                                  DateFormat(
                                    'dd MMMM yyyy',
                                  ).format(order.deliveryDate),
                                ),
                                _line(
                                  context,
                                  'Customer',
                                  order.customerName ?? '-',
                                ),
                                _line(context, 'Phone', order.customerPhone ?? '-'),
                                _line(
                                  context,
                                  'Total Paid',
                                  '₹ ${order.totalPrice.toStringAsFixed(2)}',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.go('/counter'),
                          child: const Text('Place Another Order'),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: () => context.go('/my-orders'),
                          child: const Text('View My Orders'),
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
              ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 25,
                colors: const [
                  AppColors.primary,
                  AppColors.primaryLight,
                  Colors.white,
                ],
                gravity: 0.2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _line(
    BuildContext context,
    String label,
    String value, {
    bool mono = false,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 340;
        final valueStyle =
            (mono
                    ? Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      )
                    : Theme.of(context).textTheme.bodyLarge)
                ?.copyWith(fontWeight: FontWeight.w600);

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: isNarrow
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$label:'),
                    const SizedBox(height: 2),
                    SelectableText(value, style: valueStyle),
                  ],
                )
              : Row(
                  children: [
                    SizedBox(width: 92, child: Text('$label:')),
                    Expanded(child: SelectableText(value, style: valueStyle)),
                  ],
                ),
        );
      },
    );
  }
}
