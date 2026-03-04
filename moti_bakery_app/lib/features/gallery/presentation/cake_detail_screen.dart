import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/models/cake.dart';

class CakeDetailScreen extends StatefulWidget {
  const CakeDetailScreen({super.key, required this.cake});

  final Cake cake;

  @override
  State<CakeDetailScreen> createState() => _CakeDetailScreenState();
}

class _CakeDetailScreenState extends State<CakeDetailScreen> {
  late String _selectedFlavour;

  @override
  void initState() {
    super.initState();
    _selectedFlavour = widget.cake.flavours.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cake Detail')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: ElevatedButton(
          onPressed: () => context.push('/place-order', extra: widget.cake),
          child: const Text('Place Order'),
        ),
      ),
      body: ListView(
        children: <Widget>[
          Stack(
            children: [
              Hero(
                tag: 'cake_image_${widget.cake.id}',
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: CachedNetworkImage(
                    imageUrl: widget.cake.imageUrl,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.92),
                      ],
                      stops: const [0.55, 1],
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.cake.name,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.cake.description ?? 'No description available.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Text('Select Flavour', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.cake.flavours.map((flavour) {
                    final selected = flavour == _selectedFlavour;
                    return ChoiceChip(
                      label: Text(flavour),
                      selected: selected,
                      onSelected: (_) => setState(() => _selectedFlavour = flavour),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Text(
                  'Weight Range  ${widget.cake.minWeight} kg - ${widget.cake.maxWeight} kg',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                Text(
                  'Base Rate: ₹${(widget.cake.baseRate ?? 0).toStringAsFixed(0)}/kg',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
