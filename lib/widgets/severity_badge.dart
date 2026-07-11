import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SeverityBadge extends StatelessWidget {
  final String severity;

  const SeverityBadge({super.key, required this.severity});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.severityColor(severity);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: c.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, size: 12, color: c),
          const SizedBox(width: 4),
          Text(severity, style: TextStyle(color: c, fontSize: 10.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
