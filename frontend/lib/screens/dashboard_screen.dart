import 'dart:async';

import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../models/plant.dart';
import '../theme.dart';
import '../widgets/plant_card.dart';
import 'plant_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _api = ApiClient();
  List<PlantSummary>? _plants;
  Object? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    // Live-ish dashboard: poll every 30 s (devices report every 60 s).
    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final plants = await _api.fetchPlants();
      if (mounted) {
        setState(() {
          _plants = plants;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plants = _plants;
    final thirsty =
        plants?.where((p) => p.status == PlantStatus.dry).length ?? 0;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 140,
              backgroundColor: AppColors.background,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    const EdgeInsets.only(left: 20, bottom: 14, right: 20),
                title: Text('GrowSpace 🌿',
                    style: Theme.of(context).textTheme.headlineMedium),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF14241C), AppColors.background],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: _SummaryBanner(
                  total: plants?.length,
                  thirsty: thirsty,
                ),
              ),
            ),
            if (_error != null && plants == null)
              SliverFillRemaining(child: _ErrorState(onRetry: _load))
            else if (plants == null)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              )
            else if (plants.isEmpty)
              const SliverFillRemaining(child: _EmptyState())
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final plant = plants[index];
                      // staggered entrance: each card slides up slightly later
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration:
                            Duration(milliseconds: 350 + index * 80),
                        curve: Curves.easeOutCubic,
                        builder: (context, t, child) => Opacity(
                          opacity: t,
                          child: Transform.translate(
                            offset: Offset(0, 24 * (1 - t)),
                            child: child,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: PlantCard(
                            plant: plant,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PlantDetailScreen(plant: plant),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: plants.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final int? total;
  final int thirsty;

  const _SummaryBanner({required this.total, required this.thirsty});

  @override
  Widget build(BuildContext context) {
    final String message;
    if (total == null) {
      message = 'Checking on your plants...';
    } else if (total == 0) {
      message = 'No plants registered yet';
    } else if (thirsty == 0) {
      message = 'All $total plants are vibing ✨';
    } else {
      message = '$thirsty of $total plants need water 💦';
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Text(
        message,
        key: ValueKey(message),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 16),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🪴', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text('No plants yet',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Add a plant profile in Supabase with your\nESP32 device_id to see it here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('📡', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 12),
          Text("Can't reach the greenhouse",
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          const Text(
            'Backend offline or wrong API_BASE\n(${ApiClient.baseUrl})',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
