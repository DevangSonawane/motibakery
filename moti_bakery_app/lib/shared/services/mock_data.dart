import '../models/cake.dart';
import '../models/order.dart';
import '../models/pricing_rule.dart';

final List<Cake> mockCakes = <Cake>[
  const Cake(
    id: 'cake-001',
    name: 'Black Forest Signature',
    imageUrl:
        'https://images.unsplash.com/photo-1606890737304-57a1ca8a5b62?auto=format&fit=crop&w=1200&q=80',
    description: 'Classic black forest with rich cream and cherry layers.',
    flavours: <String>['Vanilla', 'Chocolate', 'Truffle'],
    minWeight: 0.5,
    maxWeight: 5.0,
    baseRate: 850,
    categories: <String>['Classic', 'Premium'],
    isActive: true,
  ),
  const Cake(
    id: 'cake-002',
    name: 'Butterscotch Delight',
    imageUrl:
        'https://images.unsplash.com/photo-1578985545062-69928b1d9587?auto=format&fit=crop&w=1200&q=80',
    description: 'Crunchy praline and smooth butterscotch sponge.',
    flavours: <String>['Butterscotch', 'Vanilla'],
    minWeight: 0.5,
    maxWeight: 3.0,
    baseRate: 780,
    categories: <String>['Classic'],
    isActive: true,
  ),
  const Cake(
    id: 'cake-003',
    name: 'Red Velvet Royale',
    imageUrl:
        'https://images.unsplash.com/photo-1614707267537-b85aaf00c4b7?auto=format&fit=crop&w=1200&q=80',
    description: 'Velvety sponge with cream cheese frosting.',
    flavours: <String>['Vanilla', 'Truffle'],
    minWeight: 1.0,
    maxWeight: 4.0,
    baseRate: 980,
    categories: <String>['Premium'],
    isActive: true,
  ),
];

final List<PricingRule> mockPricingRules = <PricingRule>[
  const PricingRule(
    id: 'rule-001',
    flavour: 'Chocolate',
    incrementAmount: 50,
    isActive: true,
  ),
  const PricingRule(
    id: 'rule-002',
    flavour: 'Truffle',
    incrementAmount: 0,
    incrementPercent: 10,
    isActive: true,
  ),
  const PricingRule(
    id: 'rule-003',
    category: 'Premium',
    incrementAmount: 100,
    isActive: true,
  ),
];

final List<Order> mockOrders = <Order>[
  Order(
    id: 'ORD-1001',
    cakeId: 'cake-001',
    cakeName: 'Black Forest Signature',
    flavour: 'Chocolate',
    weight: 1.5,
    deliveryDate: DateTime.now().add(const Duration(days: 1)),
    totalPrice: 1500,
    status: OrderStatus.newOrder,
    createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
    createdBy: 'usr-counter-01',
    customerName: 'Riya',
  ),
  Order(
    id: 'ORD-1002',
    cakeId: 'cake-003',
    cakeName: 'Red Velvet Royale',
    flavour: 'Truffle',
    weight: 2.0,
    deliveryDate: DateTime.now(),
    totalPrice: 2356,
    status: OrderStatus.inProgress,
    createdAt: DateTime.now().subtract(const Duration(hours: 1, minutes: 15)),
    createdBy: 'usr-counter-02',
    customerName: 'Aarav',
  ),
];
