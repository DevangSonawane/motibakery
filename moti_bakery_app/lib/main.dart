import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() {
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
