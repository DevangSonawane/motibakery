import 'dart:convert';

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
    this.minWeightKg,
    this.maxWeightKg,
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
      minWeightKg: _nullableDouble(map['min_weight']),
      maxWeightKg: _nullableDouble(map['max_weight']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'handle': handle,
      'title': title,
      'option1_name': option1Name,
      'option1_value': option1Value,
      'option2_name': option2Name,
      'option2_value': option2Value,
      'option3_name': option3Name,
      'option3_value': option3Value,
      'sku': sku,
      'hs_code': hsCode,
      'coo': coo,
      'location': location,
      'bin_name': binName,
      'incoming': incoming,
      'unavailable': unavailable,
      'committed': committed,
      'available': available,
      'on_hand_current': onHandCurrent,
      'on_hand_new': onHandNew,
      'name': name,
      'category': category,
      'rate': rate,
      'weight': weight,
      'flavours': flavours,
      'status': status,
      'image': image,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'min_weight': minWeightKg,
      'max_weight': maxWeightKg,
    };
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
  final double? minWeightKg;
  final double? maxWeightKg;

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

  /// Parsed min/max weight constraints (in kilograms) from the `weight` field.
  ///
  /// The backend currently stores weight as a free-form string (examples seen in
  /// uploads: `0.5-5 kg`, `0.5 kg - 3 kg`, `500g - 2kg`). This helper extracts
  /// up to two numeric values and converts grams to kg when the string appears
  /// to be in grams.
  ///
  /// If parsing fails, returns `(minKg: null, maxKg: null)`.
  ({double? minKg, double? maxKg}) get weightRangeKg {
    if (minWeightKg != null || maxWeightKg != null) {
      return (minKg: minWeightKg, maxKg: maxWeightKg);
    }
    return _parseWeightRangeKg(weight);
  }

  List<String> get optionValues {
    final values = <String>{};
    final option2Label = option2Name?.trim().toLowerCase();
    if (option2Label == 'flavours' || option2Label == 'flavors') {
      final raw = option2Value?.trim() ?? '';
      if (raw.isEmpty) return const [];
      try {
        final decoded = jsonDecode(raw);
        if (decoded is! List) return const [];
        final options = <String>[];
        for (final item in decoded) {
          if (item is Map) {
            final name = item['name']?.toString() ?? '';
            final customName = item['customName']?.toString() ?? '';
            final picked = name == '__custom__' ? customName : name;
            final trimmed = picked.trim();
            if (trimmed.isNotEmpty) {
              options.add(trimmed);
            }
            continue;
          }
          final value = _extractValue(item);
          if (value != null && value.trim().isNotEmpty) {
            options.add(value.trim());
          }
        }
        return options;
      } catch (_) {
        // Some uploads store flavours/variants as a plain delimited string (not JSON),
        // or as a "loose object" string like:
        // `[{name: Pineapple, price: 700.00, customName: }, ...]`.
        final extracted = _extractNamesFromLooseObjectString(raw);
        if (extracted.isNotEmpty) {
          return extracted;
        }
        return raw
            .split(RegExp(r'[,\n|]+'))
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toList(growable: false);
      }
    }

    void addRaw(String? raw) {
      final normalized = raw?.trim() ?? '';
      if (normalized.isEmpty) {
        return;
      }
      final parsed = _tryParseOptionValues(normalized);
      if (parsed.isNotEmpty) {
        values.addAll(parsed);
        return;
      }
      final extracted = _extractNamesFromLooseObjectString(normalized);
      if (extracted.isNotEmpty) {
        values.addAll(extracted);
        return;
      }
      for (final part in normalized.split(RegExp(r'[,\n|]+'))) {
        final next = part.trim();
        if (next.isNotEmpty) {
          values.add(next);
        }
      }
    }

    addRaw(option1Value);
    addRaw(option2Value);
    addRaw(option3Value);
    return values.toList(growable: false);
  }

  static List<String> _tryParseOptionValues(String raw) {
    if (!(raw.startsWith('{') || raw.startsWith('['))) {
      return const [];
    }
    try {
      final decoded = jsonDecode(raw);
      return _extractFromJson(decoded);
    } catch (_) {
      return const [];
    }
  }

  static List<String> _extractFromJson(dynamic data) {
    final results = <String>[];
    if (data is List) {
      for (final item in data) {
        if (item is Map) {
          final name = item['name']?.toString() ?? '';
          final customName = item['customName']?.toString() ?? '';
          final picked = name == '__custom__' ? customName : name;
          final trimmed = picked.trim();
          if (trimmed.isNotEmpty) {
            results.add(trimmed);
          }
          continue;
        }
        final value = _extractValue(item);
        if (value != null && value.trim().isNotEmpty) {
          results.add(value.trim());
        }
      }
      return results;
    }
    if (data is Map) {
      final listValue = _findListInMap(data);
      if (listValue != null) {
        return _extractFromJson(listValue);
      }
      final value = _labelFromMap(data);
      if (value != null && value.trim().isNotEmpty) {
        results.add(value.trim());
      }
      return results;
    }
    if (data is String && data.trim().isNotEmpty) {
      results.add(data.trim());
    }
    return results;
  }

  static dynamic _findListInMap(Map<dynamic, dynamic> map) {
    const keys = [
      'values',
      'options',
      'variants',
      'flavours',
      'flavors',
      'items',
      'data',
    ];
    for (final key in keys) {
      if (map.containsKey(key) && map[key] is List) {
        return map[key];
      }
    }
    return null;
  }

  static String? _extractValue(dynamic item) {
    if (item is String) return item;
    if (item is Map) return _labelFromMap(item);
    return null;
  }

  static String? _labelFromMap(Map<dynamic, dynamic> map) {
    const keys = ['flavour', 'flavor', 'name', 'label', 'title', 'value'];
    for (final key in keys) {
      final value = map[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }
    return null;
  }

  static List<String> _extractNamesFromLooseObjectString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return const [];
    if (!trimmed.contains('name:')) return const [];

    final results = <String>[];
    final matches = RegExp(r'name\s*:\s*([^,}\]]+)').allMatches(trimmed);
    for (final match in matches) {
      final value = match.group(1);
      if (value == null) continue;
      var next = value.trim();
      if (next.startsWith('"') && next.endsWith('"') && next.length >= 2) {
        next = next.substring(1, next.length - 1).trim();
      }
      if (next.startsWith("'") && next.endsWith("'") && next.length >= 2) {
        next = next.substring(1, next.length - 1).trim();
      }
      if (next.isNotEmpty && next != '__custom__') {
        results.add(next);
      }
    }
    return results;
  }

  static String _string(dynamic value) {
    if (value == null) return '';
    if (value is String) return value;
    if (value is num || value is bool) return value.toString();
    if (value is List || value is Map) {
      try {
        return jsonEncode(value);
      } catch (_) {
        return value.toString();
      }
    }
    return value.toString();
  }

  static String? _nullableString(dynamic value) {
    if (value == null) return null;
    final parsed = _string(value);
    if (parsed.trim().isEmpty) {
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

  static double? _nullableDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static ({double? minKg, double? maxKg}) _parseWeightRangeKg(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (minKg: null, maxKg: null);
    }

    final values = <double>[];
    for (final match in RegExp(r'(\d+(?:\.\d+)?)').allMatches(trimmed)) {
      final parsed = double.tryParse(match.group(1)!);
      if (parsed != null) {
        values.add(parsed);
      }
    }
    if (values.isEmpty) {
      return (minKg: null, maxKg: null);
    }

    final lower = trimmed.toLowerCase();
    final looksLikeGrams = (lower.contains('gm') ||
            lower.contains('gms') ||
            lower.contains('gram') ||
            lower.contains('grams')) &&
        !lower.contains('kg');
    final normalizedValues = looksLikeGrams
        ? values.map((value) => value / 1000).toList(growable: false)
        : values;

    if (normalizedValues.length >= 2) {
      normalizedValues.sort();
      return (minKg: normalizedValues.first, maxKg: normalizedValues.last);
    }

    final only = normalizedValues.first;
    final hasMin = lower.contains('min');
    final hasMax = lower.contains('max');
    if (hasMin && !hasMax) {
      return (minKg: only, maxKg: null);
    }
    if (hasMax && !hasMin) {
      return (minKg: null, maxKg: only);
    }
    return (minKg: only, maxKg: only);
  }
}
