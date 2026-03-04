import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class CounterBottomNav extends StatelessWidget {
  const CounterBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.borderLight)),
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          if (index == currentIndex) {
            return;
          }
          if (index == 0) {
            context.go('/counter');
          } else {
            context.go('/my-orders');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.cake_outlined),
            activeIcon: Icon(Icons.cake),
            label: 'Gallery',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'My Orders',
          ),
        ],
      ),
    );
  }
}
