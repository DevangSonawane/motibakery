class Product {
  const Product({
    required this.id,
    required this.handle,
    required this.title,
    required this.option1Name,
    required this.option1Value,
    required this.option2Name,
    required this.option2Value,
    required this.option3Name,
    required this.option3Value,
    required this.sku,
    required this.hsCode,
    required this.coo,
    required this.location,
    required this.binName,
    required this.incoming,
    required this.unavailable,
    required this.committed,
    required this.available,
    required this.onHandCurrent,
    required this.onHandNew,
    required this.name,
    required this.category,
    required this.rate,
    required this.weight,
    required this.flavours,
    required this.status,
    required this.image,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: _string(map['id']),
      handle: _string(map['handle']),
      title: _string(map['title']),
      option1Name: _nullableString(map['option1_name']),
      option1Value: _nullableString(map['option1_value']),
      option2Name: _nullableString(map['option2_name']),
      option2Value: _nullableString(map['option2_value']),
      option3Name: _nullableString(map['option3_name']),
      option3Value: _nullableString(map['option3_value']),
      sku: _nullableString(map['sku']),
      hsCode: _nullableString(map['hs_code']),
      coo: _nullableString(map['coo']),
      location: _nullableString(map['location']),
      binName: _nullableString(map['bin_name']),
      incoming: _int(map['incoming']),
      unavailable: _int(map['unavailable']),
      committed: _int(map['committed']),
      available: _int(map['available']),
      onHandCurrent: _int(map['on_hand_current']),
      onHandNew: _nullableInt(map['on_hand_new']),
      name: _string(map['name']),
      category: _string(map['category']),
      rate: _string(map['rate']),
      weight: _string(map['weight']),
      flavours: _int(map['flavours'], fallback: 1),
      status: _string(map['status']),
      image: _string(map['image']),
      createdAt: _nullableString(map['created_at']),
      updatedAt: _nullableString(map['updated_at']),
    );
  }

  final String id;
  final String handle;
  final String title;
  final String? option1Name;
  final String? option1Value;
  final String? option2Name;
  final String? option2Value;
  final String? option3Name;
  final String? option3Value;
  final String? sku;
  final String? hsCode;
  final String? coo;
  final String? location;
  final String? binName;
  final int incoming;
  final int unavailable;
  final int committed;
  final int available;
  final int onHandCurrent;
  final int? onHandNew;
  final String name;
  final String category;
  final String rate;
  final String weight;
  final int flavours;
  final String status;
  final String image;
  final String? createdAt;
  final String? updatedAt;

  String get displayTitle {
    if (title.trim().isNotEmpty) {
      return title;
    }
    if (name.trim().isNotEmpty) {
      return name;
    }
    return handle;
  }

  bool get isCake {
    final categoryValue = category.toLowerCase();
    final titleValue = displayTitle.toLowerCase();
    return categoryValue.contains('cake') || titleValue.contains('cake');
  }

  List<String> get optionValues {
    final values = <String>{
      if ((option1Value ?? '').trim().isNotEmpty) option1Value!.trim(),
      if ((option2Value ?? '').trim().isNotEmpty) option2Value!.trim(),
      if ((option3Value ?? '').trim().isNotEmpty) option3Value!.trim(),
    };
    return values.toList(growable: false);
  }

  static String _string(dynamic value) {
    return value?.toString() ?? '';
  }

  static String? _nullableString(dynamic value) {
    final parsed = value?.toString();
    if (parsed == null || parsed.trim().isEmpty) {
      return null;
    }
    return parsed;
  }

  static int _int(dynamic value, {int fallback = 0}) {
    if (value is int) {
      return value;
    }
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is int) {
      return value;
    }
    return int.tryParse(value.toString());
  }
}
