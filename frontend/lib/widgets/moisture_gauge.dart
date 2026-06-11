import 'package:flutter/material.dart';

import '../theme.dart';

/// Animated circular gauge. Sweeps from 0 to [value] whenever the value changes.
class MoistureGauge extends StatelessWidget {
  final double? value; // 0-100, null = no data
  final double size;
  final Color color;

  const MoistureGauge({
    super.key,
    required this.value,
    required this.color,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: (value ?? 0) / 100),
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: 1,
                strokeWidth: size / 12,
                color: AppColors.surfaceLight,
              ),
              CircularProgressIndicator(
                value: animated,
                strokeWidth: size / 12,
                color: color,
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      value == null ? '--' : '${(animated * 100).round()}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontSize: size / 4,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    Text(
                      '% soil',
                      style: TextStyle(
                        fontSize: size / 10,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
