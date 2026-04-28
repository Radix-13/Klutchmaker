import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class KmChip extends StatelessWidget {
  final String label;
  final Color? color;
  const KmChip({super.key, required this.label, this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: (color ?? AppTheme.accent).withOpacity(.2),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color ?? AppTheme.accent2,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      );
}
