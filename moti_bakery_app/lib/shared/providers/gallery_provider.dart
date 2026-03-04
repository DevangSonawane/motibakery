import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cake.dart';
import '../services/cake_service.dart';

final cakeServiceProvider = Provider<CakeService>((ref) => CakeService());

final searchQueryProvider = StateProvider<String>((ref) => '');

final selectedCategoriesProvider = StateProvider<Set<String>>((ref) => <String>{});

final cakesProvider = FutureProvider<List<Cake>>((ref) async {
  return ref.watch(cakeServiceProvider).fetchCakes();
});

final categoriesProvider = Provider<List<String>>((ref) {
  final cakes = ref.watch(cakesProvider).valueOrNull ?? <Cake>[];
  final set = <String>{};
  for (final cake in cakes) {
    set.addAll(cake.categories);
  }
  return set.toList()..sort();
});

final filteredCakesProvider = Provider<List<Cake>>((ref) {
  final cakes = ref.watch(cakesProvider).valueOrNull ?? <Cake>[];
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final selected = ref.watch(selectedCategoriesProvider);

  return cakes.where((cake) {
    final matchesQuery = cake.name.toLowerCase().contains(query);
    final matchesCategory =
        selected.isEmpty || selected.any((cat) => cake.categories.contains(cat));
    return matchesQuery && matchesCategory;
  }).toList();
});
