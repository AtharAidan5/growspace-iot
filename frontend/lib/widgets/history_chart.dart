import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../theme.dart';

/// Smooth line chart for one telemetry series. X axis = time.
/// Vertical lime lines mark pump trigger events.
class HistoryChart extends StatelessWidget {
  final List<Reading> readings;
  final double? Function(Reading) selector;
  final Color color;
  final double minY;
  final double maxY;
  final String unit;

  const HistoryChart({
    super.key,
    required this.readings,
    required this.selector,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[];
    final pumpLines = <VerticalLine>[];

    for (final r in readings) {
      final x = r.recordedAt.millisecondsSinceEpoch.toDouble();
      final y = selector(r);
      if (y != null) points.add(FlSpot(x, y));
      if (r.pumpTriggered) {
        pumpLines.add(VerticalLine(
          x: x,
          color: AppColors.accent.withOpacity(0.5),
          strokeWidth: 1.5,
          dashArray: [4, 4],
        ));
      }
    }

    if (points.length < 2) {
      return const SizedBox(
        height: 180,
        child: Center(
          child: Text('Not enough data yet',
              style: TextStyle(color: AppColors.textSecondary)),
        ),
      );
    }

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
              color: AppColors.surfaceLight,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: _timeInterval(points),
                getTitlesWidget: (value, meta) {
                  final t =
                      DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(verticalLines: pumpLines),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              tooltipBgColor: AppColors.surfaceLight,
              getTooltipItems: (spots) => spots
                  .map((s) => LineTooltipItem(
                        '${s.y.toStringAsFixed(1)} $unit',
                        const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600),
                      ))
                  .toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: points,
              isCurved: true,
              curveSmoothness: 0.3,
              barWidth: 3,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color.withOpacity(0.25), color.withOpacity(0.0)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _timeInterval(List<FlSpot> points) {
    final span = points.last.x - points.first.x;
    return span <= 0 ? 1 : span / 4; // ~5 labels across the axis
  }
}
