import '../shared/models/pricing_rule.dart';

class PriceCalculator {
  static double calculate({
    required double baseRate,
    required double weight,
    required String flavour,
    required List<String> categories,
    required List<PricingRule> rules,
  }) {
    var adjustedRate = baseRate;

    for (final rule in rules) {
      final flavourMatch = rule.flavour != null &&
          rule.flavour!.toLowerCase() == flavour.toLowerCase();
      final categoryMatch =
          rule.category != null && categories.contains(rule.category);

      if (!flavourMatch && !categoryMatch) {
        continue;
      }

      adjustedRate += rule.incrementAmount;
      if (rule.incrementPercent != null) {
        adjustedRate += baseRate * (rule.incrementPercent! / 100);
      }
    }

    return double.parse((adjustedRate * weight).toStringAsFixed(2));
  }
}
