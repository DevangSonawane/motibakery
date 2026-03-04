import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../models/order.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, bg, fg) = switch (status) {
      OrderStatus.newOrder => (
          'New',
          Icons.schedule,
          AppColors.surfaceGray,
          AppColors.textHint,
        ),
      OrderStatus.inProgress => (
          'In Progress',
          Icons.local_fire_department_outlined,
          AppColors.statusProgressBg,
          AppColors.statusProgress,
        ),
      OrderStatus.prepared => (
          'Prepared',
          Icons.check_circle_outline,
          AppColors.statusPreparedBg,
          AppColors.statusPrepared,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(color: fg),
          ),
        ],
      ),
    );
  }
}
