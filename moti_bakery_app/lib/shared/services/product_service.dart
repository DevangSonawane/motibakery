import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import 'supabase_bootstrap.dart';

class ProductService {
  static const String _columns =
      'id,handle,title,option1_name,option1_value,option2_name,option2_value,option3_name,option3_value,name,category,rate,weight,min_weight,max_weight,flavours,status,image,created_at,updated_at';

  void clearCache() {
    // Intentionally a no-op for now. Caching is handled at the provider layer
    // for pagination.
  }

  /// Legacy (non-paginated) fetch. Prefer [fetchProductsPage] + pagination.
  Future<List<Product>> fetchProducts({int limit = 500}) async {
    if (SupabaseBootstrap.result.status != SupabaseBootstrapStatus.connected) {
      throw const ProductException(
        'Supabase is not connected. Run app with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY, then login with a valid Supabase user.',
      );
    }

    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select(_columns)
          .eq('status', 'active')
          .limit(limit)
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

  Future<PostgrestResponse<List<dynamic>>> fetchProductsPageWithCount({
    required int from,
    required int to,
  }) async {
    if (SupabaseBootstrap.result.status != SupabaseBootstrapStatus.connected) {
      throw const ProductException(
        'Supabase is not connected. Run app with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY, then login with a valid Supabase user.',
      );
    }

    try {
      return await Supabase.instance.client
          .from('products')
          .select(_columns)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(from, to)
          .count(CountOption.exact);
    } on PostgrestException catch (error) {
      throw ProductException(error.message);
    } on AuthException catch (error) {
      throw ProductException(error.message);
    } catch (error) {
      throw ProductException(error.toString());
    }
  }

  Future<List<Product>> fetchProductsPage({
    required int from,
    required int to,
  }) async {
    if (SupabaseBootstrap.result.status != SupabaseBootstrapStatus.connected) {
      throw const ProductException(
        'Supabase is not connected. Run app with --dart-define SUPABASE_URL and SUPABASE_ANON_KEY, then login with a valid Supabase user.',
      );
    }

    try {
      final rows = await Supabase.instance.client
          .from('products')
          .select(_columns)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(from, to);
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
