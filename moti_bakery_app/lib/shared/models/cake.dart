class Cake {
  const Cake({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.flavours,
    required this.minWeight,
    required this.maxWeight,
    required this.categories,
    required this.isActive,
    this.description,
    this.baseRate,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String? description;
  final List<String> flavours;
  final double minWeight;
  final double maxWeight;
  final double? baseRate;
  final List<String> categories;
  final bool isActive;
}
