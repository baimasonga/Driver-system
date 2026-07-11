import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Widget? trailing;
  final String? subtitle;

  const SectionHeader({super.key, required this.title, this.icon, this.trailing, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: AppColors.amber500),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(subtitle!, style: const TextStyle(color: AppColors.neutral400, fontSize: 11)),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;

  const EmptyState({super.key, required this.message, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.neutral700),
            const SizedBox(height: 8),
            Text(message, style: const TextStyle(color: AppColors.neutral400, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
