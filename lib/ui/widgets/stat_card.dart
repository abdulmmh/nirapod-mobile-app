import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String icon;
  final String? subtext;
  final Color? accentColor;

  const StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtext,
    this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                icon,
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: accentColor ?? (isDark ? Colors.white : AppColors.textPrimary),
            ),
          ),
          if (subtext != null) ...[
            const SizedBox(height: 4),
            Text(
              subtext!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
