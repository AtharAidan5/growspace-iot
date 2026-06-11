import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme.dart';
import 'moisture_gauge.dart';
import 'status_chip.dart';

class PlantCard extends StatelessWidget {
  final PlantSummary plant;
  final VoidCallback onTap;

  const PlantCard({super.key, required this.plant, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = statusColor(plant.status);
    final latest = plant.latest;

    return Hero(
      tag: 'plant-${plant.id}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                // thirsty plants glow so they jump out of the list
                color: plant.status == PlantStatus.dry
                    ? color.withOpacity(0.6)
                    : AppColors.surfaceLight,
              ),
              boxShadow: plant.status == PlantStatus.dry
                  ? [BoxShadow(color: color.withOpacity(0.15), blurRadius: 24)]
                  : null,
            ),
            child: Row(
              children: [
                MoistureGauge(
                  value: latest?.soilMoisture,
                  color: color,
                  size: 84,
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(plant.name,
                          style: Theme.of(context).textTheme.titleMedium),
                      if (plant.location != null) ...[
                        const SizedBox(height: 2),
                        Text(plant.location!,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          StatusChip(status: plant.status),
                          const SizedBox(width: 8),
                          if (latest?.temperatureC != null)
                            Text(
                              '${latest!.temperatureC!.toStringAsFixed(1)}°C',
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      if (latest?.pumpTriggered == true) ...[
                        const SizedBox(height: 8),
                        const Row(
                          children: [
                            Icon(Icons.water_drop,
                                size: 14, color: AppColors.wet),
                            SizedBox(width: 4),
                            Text(
                              'Watered on last reading',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.wet),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
