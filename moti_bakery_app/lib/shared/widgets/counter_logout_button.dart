import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_provider.dart';

class CounterLogoutButton extends ConsumerWidget {
  const CounterLogoutButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Logout',
      onPressed: () => ref.read(authControllerProvider).logout(),
      icon: const Icon(Icons.logout_outlined),
    );
  }
}
