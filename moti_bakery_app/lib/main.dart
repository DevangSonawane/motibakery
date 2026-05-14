import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';
import 'shared/services/supabase_bootstrap.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reduce image "vanishing" on scroll by allowing a larger in-memory image
  // cache. Combined with sized decoding in ProductImageView, this keeps cards
  // stable while scrolling through many products.
  PaintingBinding.instance.imageCache.maximumSize = 2000;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 150 << 20; // 150 MiB
  await SupabaseBootstrap.initialize();
  SupabaseBootstrap.logStatus();
  runApp(const ProviderScope(child: MotiBakeryApp()));
}

class MotiBakeryApp extends ConsumerWidget {
  const MotiBakeryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Motibakery',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      routerConfig: router,
    );
  }
}
