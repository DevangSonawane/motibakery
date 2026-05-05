import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../shared/config/supabase_config.dart';
import '../../../shared/models/product.dart';
import '../../orders/presentation/product_place_order_screen.dart';

class ProductDetailArgs {
  const ProductDetailArgs({required this.products, required this.initialIndex});

  final List<Product> products;
  final int initialIndex;
}

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.products,
    this.initialIndex = 0,
  });

  factory ProductDetailScreen.single({Key? key, required Product product}) {
    return ProductDetailScreen(key: key, products: [product], initialIndex: 0);
  }

  final List<Product> products;
  final int initialIndex;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late int _index;
  late List<String> _variants;
  String? _selectedVariant;

  @override
  void initState() {
    super.initState();
    if (widget.products.isEmpty) {
      _index = 0;
      _variants = const [];
      _selectedVariant = null;
      return;
    }
    final maxIndex = widget.products.isEmpty ? 0 : widget.products.length - 1;
    _index = widget.initialIndex.clamp(0, maxIndex);
    _syncForProduct();
  }

  Product get _product => widget.products[_index];

  void _syncForProduct() {
    _variants = _product.optionValues;
    _selectedVariant = _variants.isNotEmpty ? _variants.first : null;
  }

  void _setProductIndex(int nextIndex) {
    if (nextIndex == _index) return;
    if (nextIndex < 0 || nextIndex >= widget.products.length) return;
    setState(() {
      _index = nextIndex;
      _syncForProduct();
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    final dx = details.velocity.pixelsPerSecond.dx;
    if (dx.abs() < 320) return;

    if (dx < 0) {
      _setProductIndex(_index + 1);
      return;
    }

    _setProductIndex(_index - 1);
  }

  void _openImagePreview() {
    final imagePath = _product.image.trim();
    if (imagePath.isEmpty) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: Text(_product.displayTitle),
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: ProductImageView(
                imagePath: _product.image,
                productName: _product.displayTitle,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.products.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: Center(
          child: Text(
            'No product found',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final product = _product;
    final selectedVariant = _selectedVariant;
    final selectedPrice = selectedVariant == null
        ? _fallbackPrice(product.rate)
        : _priceForVariant(product, selectedVariant);

    return Scaffold(
      appBar: AppBar(
        title: Text(product.displayTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: GestureDetector(
        onHorizontalDragEnd: _handleHorizontalDragEnd,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 320,
                child: Material(
                  color: Colors.white,
                  child: InkWell(
                    onTap: _openImagePreview,
                    child: ProductImageView(
                      imagePath: product.image,
                      productName: product.displayTitle,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              product.displayTitle,
              style: Theme.of(
                context,
              ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label: product.category.trim().isEmpty ? 'Product' : product.category,
                ),
              ],
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.18),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                key: ValueKey<String>('price_${selectedVariant ?? 'base'}_${product.id}'),
                selectedPrice,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('Select Variant', style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            if (_variants.isEmpty)
              Text(
                'No variants available',
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else if (_variants.length == 1)
              Align(
                alignment: Alignment.centerLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.primaryPale,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.primaryLight.withValues(alpha: 0.45),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Text(
                      '${_variantLabel(_variants.first, product)} • ${_priceForVariant(product, _variants.first)}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
            else
              Align(
                alignment: Alignment.centerLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 320),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0.96, end: 1),
                    duration: const Duration(milliseconds: 280),
                    curve: Curves.easeOutCubic,
                    builder: (context, scale, child) {
                      return Transform.scale(scale: scale, child: child);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.primary.withValues(alpha: 0.18),
                            AppColors.primaryLight.withValues(alpha: 0.1),
                          ],
                        ),
                      ),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedVariant,
                        isExpanded: true,
                        borderRadius: BorderRadius.circular(14),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        decoration: InputDecoration(
                          labelText: 'Variant',
                          isDense: true,
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                        items: _variants
                            .map(
                              (variant) => DropdownMenuItem<String>(
                                value: variant,
                                child: Text(
                                  '${_variantLabel(variant, product)} • ${_priceForVariant(product, variant)}',
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                            )
                            .toList(growable: false),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedVariant = value);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              onPressed: () => context.push(
                '/product-order',
                extra: ProductOrderArgs(
                  product: product,
                  initialVariant: _selectedVariant,
                ),
              ),
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('Order This Product'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Menu'),
            ),
          ],
        ),
      ),
    );
  }

  String _fallbackPrice(String rate) {
    return _normalizePrice(rate);
  }

  String _priceForVariant(Product product, String variant) {
    final normalizedRate = product.rate.trim();
    if (normalizedRate.isEmpty || normalizedRate == '-') {
      return 'Price on request';
    }

    final segments = normalizedRate.split('|');
    var matched = false;
    for (final segment in segments) {
      final parts = _splitKeyValue(segment);
      if (parts == null) continue;
      final key = _normalizeVariant(parts.$1);
      final value = parts.$2.trim();
      if (key.isEmpty || value.isEmpty) continue;
      if (key == _normalizeVariant(variant)) {
        matched = true;
        return _normalizePrice(value);
      }
    }

    if (!matched) {
      final optionPrice = _priceFromOption2Json(product.option2Value, variant);
      if (optionPrice != null) {
        return '₹$optionPrice';
      }
    }

    return _fallbackPrice(product.rate);
  }

  String _normalizePrice(String raw) {
    final clean = raw.trim();
    if (clean.isEmpty || clean == '-') return 'Price on request';

    final hasCurrency = clean.contains('₹');
    final fromRegex = RegExp(r'^\s*from\s+', caseSensitive: false);
    if (hasCurrency) {
      return clean.replaceFirst(fromRegex, '');
    }
    final withoutFrom = clean.replaceFirst(fromRegex, '');
    return '₹$withoutFrom';
  }

  (String, String)? _splitKeyValue(String segment) {
    final trimmed = segment.trim();
    if (trimmed.isEmpty) return null;

    int index = trimmed.indexOf(':');
    String delimiter = ':';
    if (index == -1) {
      index = trimmed.indexOf('=');
      delimiter = '=';
    }
    if (index == -1) {
      index = trimmed.indexOf(' - ');
      delimiter = ' - ';
    }
    if (index == -1) return null;
    final key = trimmed.substring(0, index).trim();
    final value = trimmed.substring(index + delimiter.length).trim();
    return (key, value);
  }

  String _normalizeVariant(String raw) {
    final lower = raw.toLowerCase();
    final buffer = StringBuffer();
    for (final codeUnit in lower.codeUnits) {
      final isDigit = codeUnit >= 48 && codeUnit <= 57;
      final isLower = codeUnit >= 97 && codeUnit <= 122;
      if (isDigit || isLower) {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  String _variantLabel(String variant, Product product) {
    final trimmed = variant.trim();
    if (trimmed.isEmpty) return product.displayTitle;
    return trimmed;
  }

  String? _priceFromOption2Json(String? raw, String variant) {
    final normalizedVariant = _normalizeVariant(variant);
    if (normalizedVariant.isEmpty) return null;
    final value = raw?.trim() ?? '';
    if (value.isEmpty || !(value.startsWith('[') || value.startsWith('{'))) {
      return null;
    }
    try {
      final decoded = jsonDecode(value);
      if (decoded is! List) return null;
      for (final item in decoded) {
        if (item is! Map) continue;
        final name = item['name']?.toString() ?? '';
        if (_normalizeVariant(name) != normalizedVariant) continue;
        final price = item['price']?.toString() ?? '';
        final trimmed = price.trim();
        if (trimmed.isEmpty) continue;
        return trimmed;
      }
    } catch (_) {
      return null;
    }
    return null;
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.primaryPale,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class ProductImageView extends StatelessWidget {
  const ProductImageView({
    super.key,
    required this.imagePath,
    required this.productName,
    this.fit = BoxFit.cover,
  });

  final String imagePath;
  final String productName;
  final BoxFit fit;
  static final Map<String, Uint8List> _dataUriCache = <String, Uint8List>{};

  @override
  Widget build(BuildContext context) {
    final trimmed = imagePath.trim();

    if (trimmed.isEmpty) {
      return _fallback();
    }

    if (_isDataUri(trimmed)) {
      final bytes = _decodeDataUri(trimmed);
      if (bytes != null) {
        return Image.memory(
          bytes,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        );
      }
      return _fallback();
    }

    if (_looksLikeAssetPath(trimmed)) {
      return Image.asset(
        trimmed,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    if (!kIsWeb &&
        (_looksLikeFilePath(trimmed) || trimmed.startsWith('file://'))) {
      final filePath = trimmed.startsWith('file://')
          ? Uri.parse(trimmed).toFilePath()
          : trimmed;
      return Image.file(
        File(filePath),
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _fallback(),
      );
    }

    final networkUrl = _resolveNetworkUrl(trimmed);
    if (networkUrl == null) {
      return _fallback();
    }

    return Image.network(
      networkUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _fallback(),
    );
  }

  bool _isDataUri(String value) => value.startsWith('data:image');

  bool _looksLikeAssetPath(String value) {
    return value.startsWith('assets/') || value.startsWith('images/');
  }

  bool _looksLikeFilePath(String value) {
    return value.startsWith('/') ||
        value.startsWith('./') ||
        value.startsWith('../');
  }

  Uint8List? _decodeDataUri(String value) {
    final cached = _dataUriCache[value];
    if (cached != null) {
      return cached;
    }

    final commaIndex = value.indexOf(',');
    if (commaIndex == -1) return null;
    final payload = value.substring(commaIndex + 1);
    try {
      final decoded = base64Decode(payload);
      // Keep a small in-memory cache to avoid repeated expensive base64 decode
      // for the same image while browsing cards/detail/order screens.
      if (_dataUriCache.length > 80) {
        _dataUriCache.remove(_dataUriCache.keys.first);
      }
      _dataUriCache[value] = decoded;
      return decoded;
    } catch (_) {
      return null;
    }
  }

  String? _resolveNetworkUrl(String value) {
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }

    if (value.startsWith('//')) {
      return 'https:$value';
    }

    final supabaseUrl = SupabaseConfig.fromEnvironment().url.trim();
    if (supabaseUrl.isEmpty) {
      return null;
    }

    if (value.startsWith('/storage/v1/object/')) {
      return '$supabaseUrl$value';
    }

    if (value.startsWith('storage/v1/object/')) {
      return '$supabaseUrl/$value';
    }

    // Accept raw "bucket/path/to/file.jpg" and convert to public storage URL.
    if (value.contains('/') && !value.contains(' ')) {
      return '$supabaseUrl/storage/v1/object/public/$value';
    }

    return null;
  }

  Widget _fallback() {
    return Container(
      color: AppColors.surfaceGray,
      alignment: Alignment.center,
      child: const Icon(
        Icons.local_cafe_outlined,
        color: AppColors.textHint,
        size: 30,
      ),
    );
  }
}
