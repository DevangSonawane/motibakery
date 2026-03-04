class PricingRule {
  const PricingRule({
    required this.id,
    required this.incrementAmount,
    required this.isActive,
    this.flavour,
    this.category,
    this.incrementPercent,
  });

  final String id;
  final String? flavour;
  final String? category;
  final double incrementAmount;
  final double? incrementPercent;
  final bool isActive;
}
