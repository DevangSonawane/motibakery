import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'supabase_bootstrap.dart';

class ProductService {
  Future<List<Product>> fetchProducts() async {
    if (SupabaseBootstrap.result.status != SupabaseBootstrapStatus.connected) {
      throw const ProductException(
        'Supabase is not connected. Run app with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY, then login with a valid Supabase user.',
      );
    }

    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select('*')
          .order('created_at', ascending: false);
      return rows.map(Product.fromMap).toList(growable: false);
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
