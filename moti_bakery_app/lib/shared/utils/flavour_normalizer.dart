const Map<String, String> _flavourAliases = {
  'butter scotch': 'Butter Scotch',
  'butter  scotch': 'Butter Scotch',
  'butterscotch': 'Butter Scotch',
  'butters cotch': 'Butter Scotch',
  'butter sotch': 'Butter Scotch',
  'btter scotch': 'Butter Scotch',
  'btterscotch': 'Butter Scotch',
  'butterscottch': 'Butter Scotch',
  'butterscoth': 'Butter Scotch',
  'pineapple': 'Pineapple',
  'pine apple': 'Pineapple',
  'pineaple': 'Pineapple',
  'strawberry': 'Strawberry',
  'stawberry': 'Strawberry',
  'staw berry': 'Strawberry',
  'blackforest': 'Black Forest',
  'black forest': 'Black Forest',
  'black forest cake': 'Black Forest',
  'whiteforest': 'White Forest',
  'white forest': 'White Forest',
  'mixfruit': 'Mix Fruit',
  'mix fruit': 'Mix Fruit',
  'almondhoney': 'Almond Honey',
  'almond honey': 'Almond Honey',
  'alomd honey': 'Almond Honey',
  'chococrunch': 'Choco Crunch',
  'choco crunch': 'Choco Crunch',
  'chocovanilla': 'Choco Vanilla',
  'choco vanilla': 'Choco Vanilla',
  'caramelcrunch': 'Caramel Crunch',
  'caramel crunch': 'Caramel Crunch',
  'redvelvet': 'Red Velvet',
  'red velvet': 'Red Velvet',
  'redvelvetcake': 'Red Velvet',
  'chocolatetruffle': 'Chocolate Truffle',
  'chocolate truffle': 'Chocolate Truffle',
  'chocolate truffle with coffee': 'Chocolate Truffle With Coffee',
  'chocolatetrufflewithcoffee': 'Chocolate Truffle With Coffee',
  'chocolatechiptruffle': 'Chocolate Chip Truffle',
  'chocolate chip truffle': 'Chocolate Chip Truffle',
  'royalchocolate': 'Royal Chocolate',
  'royal chocolate': 'Royal Chocolate',
  'oreochocolate': 'Oreo Chocolate',
  'oreo chocolate': 'Oreo Chocolate',
  'chocochipscake': 'Choco Chips Cake',
  'choco chips cake': 'Choco Chips Cake',
  'rainbow': 'Rainbow',
  'chocolatecreamcake': 'Chocolate Cream Cake',
  'chocolate cream cake': 'Chocolate Cream Cake',
  'chocolatecreamwithcoffee': 'Chocolate Cream With Coffee',
  'chocolate cream with coffee': 'Chocolate Cream With Coffee',
  'chocolate': 'Chocolate',
};

String flavourKey(String raw) {
  var value = raw.trim().toLowerCase();
  if (value.isEmpty) return '';

  value = value.replaceAll(RegExp(r'[\-_/]+'), ' ');
  value = value.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
  value = value.replaceAll(RegExp(r'\s+'), ' ');
  return value.replaceAll(' ', '');
}

String normalizeFlavourName(String raw) {
  final key = flavourKey(raw);
  if (key.isEmpty) return '';

  final alias = _flavourAliases[key] ?? _flavourAliases[raw.trim().toLowerCase()];
  if (alias != null) return alias;

  return raw.trim();
}

List<String> extractFlavourNames(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return const [];

  final separated = trimmed.split(RegExp(r'[,\n|/]+'));
  if (separated.length > 1) {
    final results = <String>[];
    for (final part in separated) {
      results.addAll(extractFlavourNames(part));
    }
    return results;
  }

  final normalized = normalizeFlavourName(trimmed);
  if (normalized.isNotEmpty && normalized != trimmed) {
    return [normalized];
  }

  final segmented = _segmentConcatenatedFlavours(trimmed);
  if (segmented.isNotEmpty) {
    return segmented;
  }

  return [trimmed];
}

List<String> _segmentConcatenatedFlavours(String raw) {
  final compact = flavourKey(raw);
  if (compact.isEmpty) return const [];

  final entries = _flavourAliases.entries.toList()
    ..sort((a, b) => b.key.length.compareTo(a.key.length));

  final results = <String>[];
  var index = 0;
  while (index < compact.length) {
    var matched = false;
    for (final entry in entries) {
      final key = entry.key;
      if (key.isEmpty) continue;
      if (compact.startsWith(key, index)) {
        results.add(entry.value);
        index += key.length;
        matched = true;
        break;
      }
    }
    if (!matched) {
      return const [];
    }
  }

  return results;
}
