import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  final String label;
  final Color? color;

  const StatusBadge({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.statusColor(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
      ),
    );
  }
}
