import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Animates from 0 → value over 800ms with a gradient fill.
class ConfidenceBar extends StatelessWidget {
  final double value; // 0.0 → 1.0
  const ConfidenceBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // Track
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Fill
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: value),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (_, anim, __) {
                return Container(
                  height: 8,
                  width: constraints.maxWidth * anim,
                  decoration: BoxDecoration(
                    gradient: AppTheme.confidenceGradient,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accent.withValues(alpha: 0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
