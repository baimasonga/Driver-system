import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? accent;
  final String? sublabel;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.accent,
    this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.amber500;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.neutral900,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neutral800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.neutral400,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 14, color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
          if (sublabel != null) ...[
            const SizedBox(height: 2),
            Text(sublabel!, style: const TextStyle(color: AppColors.neutral400, fontSize: 11)),
          ],
        ],
      ),
    );
  }
}
