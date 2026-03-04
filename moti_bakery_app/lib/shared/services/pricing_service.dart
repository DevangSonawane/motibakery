import '../models/pricing_rule.dart';
import 'mock_data.dart';

class PricingService {
  Future<List<PricingRule>> fetchRules() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    return mockPricingRules.where((r) => r.isActive).toList(growable: false);
  }
}
