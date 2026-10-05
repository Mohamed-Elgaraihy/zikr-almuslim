import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 148});

  final double size;

  @override
  Widget build(BuildContext context) {
    final ring = size * 0.045;
    return Semantics(
      label: 'أيقونة ذكر المسلم',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.green,
          border: Border.all(color: const Color(0xFFD4B06A), width: ring),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: size * 0.12,
              offset: Offset(0, size * 0.04),
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: size * 0.84,
            height: size * 0.84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.85),
                width: ring * 0.45,
              ),
            ),
            child: Text(
              'ذكر',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: size * 0.32,
                fontWeight: FontWeight.w700,
                color: AppColors.paper,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
