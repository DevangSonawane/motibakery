import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'supabase_bootstrap.dart';

class ProductService {
  static List<Product>? _cachedProducts;
  static DateTime? _cacheTime;
  static const Duration _cacheTtl = Duration(minutes: 10);

  Future<List<Product>> fetchProducts() async {
    final now = DateTime.now();
    if (_cachedProducts != null &&
        _cacheTime != null &&
        now.difference(_cacheTime!) < _cacheTtl) {
      return _cachedProducts!;
    }

    if (SupabaseBootstrap.result.status != SupabaseBootstrapStatus.connected) {
      throw const ProductException(
        'Supabase is not connected. Run app with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY, then login with a valid Supabase user.',
      );
    }

    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select(
            'id,handle,title,option1_name,option1_value,option2_name,option2_value,option3_name,option3_value,name,category,rate,weight,flavours,status,image,created_at,updated_at',
          )
          .eq('status', 'active')
          .limit(120)
          .order('created_at', ascending: false);
      final products = rows.map(Product.fromMap).toList(growable: false);
      _cachedProducts = products;
      _cacheTime = now;
      return products;
    } on PostgrestException catch (error) {
      throw ProductException(error.message);
    } on AuthException catch (error) {
      throw ProductException(error.message);
    } catch (error) {
      throw ProductException(error.toString());
    }
  }
}

class ProductException implements Exception {
  const ProductException(this.message);
  final String message;

  @override
  String toString() => message;
}
