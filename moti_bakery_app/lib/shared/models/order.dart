enum OrderStatus { newOrder, inProgress, prepared }

class Order {
  const Order({
    required this.id,
    required this.cakeId,
    required this.cakeName,
    required this.flavour,
    required this.weight,
    required this.deliveryDate,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.createdBy,
    this.deliveryTime,
    this.customerName,
    this.notes,
    this.imageUrl,
  });

  final String id;
  final String cakeId;
  final String cakeName;
  final String flavour;
  final double weight;
  final DateTime deliveryDate;
  final DateTime? deliveryTime;
  final String? customerName;
  final String? notes;
  final String? imageUrl;
  final double totalPrice;
  final OrderStatus status;
  final DateTime createdAt;
  final String createdBy;

  Order copyWith({OrderStatus? status}) {
    return Order(
      id: id,
      cakeId: cakeId,
      cakeName: cakeName,
      flavour: flavour,
      weight: weight,
      deliveryDate: deliveryDate,
      deliveryTime: deliveryTime,
      customerName: customerName,
      notes: notes,
      imageUrl: imageUrl,
      totalPrice: totalPrice,
      status: status ?? this.status,
      createdAt: createdAt,
      createdBy: createdBy,
    );
  }
}
