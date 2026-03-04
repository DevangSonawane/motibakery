import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pricing_rule.dart';
import '../services/pricing_service.dart';

final pricingServiceProvider = Provider<PricingService>((ref) => PricingService());

final pricingRulesProvider = FutureProvider<List<PricingRule>>((ref) async {
  return ref.watch(pricingServiceProvider).fetchRules();
});
