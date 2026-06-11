import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/plant.dart';
import '../theme.dart';
import '../widgets/history_chart.dart';
import '../widgets/moisture_gauge.dart';
import '../widgets/status_chip.dart';

class PlantDetailScreen extends StatefulWidget {
  final PlantSummary plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final _api = ApiClient();
  late PlantSummary _plant = widget.plant;
  PlantHistory? _history;
  int _hours = 24;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final current = await _api.fetchCurrent(_plant.id);
      final history = await _api.fetchHistory(_plant.id, hours: _hours);
      if (mounted) {
        setState(() {
          _plant = current;
          _history = history;
        });
      }
    } catch (_) {
      // keep showing last known data; dashboard surfaces connectivity errors
    }
  }

  void _setRange(int hours) {
    setState(() {
      _hours = hours;
      _history = null;
    });
    _refresh();
  }

  @override
  Widget build(BuildContext context) {
    final color = statusColor(_plant.status);
    final latest = _plant.latest;
    final readings = _history?.readings ?? const <Reading>[];
    final lastWatering =
        readings.where((r) => r.pumpTriggered).fold<Reading?>(null,
            (last, r) => last == null || r.recordedAt.isAfter(last.recordedAt) ? r : last);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(_plant.name,
            style: Theme.of(context).textTheme.headlineMedium),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(child: StatusChip(status: _plant.status)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          children: [
            // hero gauge
            Hero(
              tag: 'plant-${_plant.id}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    children: [
                      MoistureGauge(
                        value: latest?.soilMoisture,
                        color: color,
                        size: 170,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ideal ${_plant.thresholds.moistureMin.round()}–${_plant.thresholds.moistureMax.round()}%',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // temp + pump tiles
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    emoji: '🌡️',
                    label: 'Temperature',
                    value: latest?.temperatureC == null
                        ? '--'
                        : '${latest!.temperatureC!.toStringAsFixed(1)}°C',
                    sub:
                        'ideal ${_plant.thresholds.tempMinC.round()}–${_plant.thresholds.tempMaxC.round()}°C',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _MetricTile(
                    emoji: '🚿',
                    label: 'Last watered',
                    value: lastWatering == null
                        ? 'No events'
                        : _ago(lastWatering.recordedAt),
                    sub: lastWatering == null
                        ? 'in selected range'
                        : '${lastWatering.pumpDurationS ?? "?"}s burst',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // range selector
            Row(
              children: [
                Text('History', style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                for (final h in const [6, 24, 168]) ...[
                  _RangeChip(
                    label: h == 168 ? '7d' : '${h}h',
                    selected: _hours == h,
                    onTap: () => _setRange(h),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
            const SizedBox(height: 16),

            _ChartCard(
              title: 'Soil moisture',
              unit: '%',
              child: _history == null
                  ? const _ChartLoading()
                  : HistoryChart(
                      readings: readings,
                      selector: (r) => r.soilMoisture,
                      color: AppColors.accent,
                      minY: 0,
                      maxY: 100,
                      unit: '%',
                    ),
            ),
            const SizedBox(height: 14),
            _ChartCard(
              title: 'Temperature',
              unit: '°C',
              child: _history == null
                  ? const _ChartLoading()
                  : HistoryChart(
                      readings: readings,
                      selector: (r) => r.temperatureC,
                      color: AppColors.hot,
                      minY: 0,
                      maxY: 50,
                      unit: '°C',
                    ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'dashed lines = pump events  •  auto-refreshes every 30 s',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime t) {
    final d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    return '${d.inDays}d ago';
  }
}

class _MetricTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;

  const _MetricTile({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$emoji  $label',
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              value,
              key: ValueKey(value),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.background : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final String unit;
  final Widget child;

  const _ChartCard({
    required this.title,
    required this.unit,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ChartLoading extends StatelessWidget {
  const _ChartLoading();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 180,
      child: Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      ),
    );
  }
}
