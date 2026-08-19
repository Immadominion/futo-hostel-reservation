import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/admin/admin_models.dart';
import '../../../core/api/admin_api.dart';
import '../../../core/api/roost_api.dart' show ApiException;
import '../../../core/session/admin_session_controller.dart';
import '../../../core/theme/brightness_provider.dart';
import '../../../core/theme/surface_card.dart';
import '../../../core/theme/tokens.dart';

/// Dashboard totals — direct mobile port of the web dashboard's Overview page:
/// stat cards up top, per-hostel occupancy bars below.
class AdminOverviewPage extends ConsumerStatefulWidget {
  const AdminOverviewPage({super.key});

  @override
  ConsumerState<AdminOverviewPage> createState() => _AdminOverviewPageState();
}

class _AdminOverviewPageState extends ConsumerState<AdminOverviewPage> {
  OccupancyStats? _stats;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final stats = await ref.read(adminApiProvider).occupancyStats();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load stats.';
        _loading = false;
      });
    }
  }

  Future<void> _signOut() async {
    await ref.read(adminSessionProvider.notifier).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(brightnessProvider);
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, 0),
            child: Row(
              children: [
                Expanded(child: Text('Overview', style: Theme.of(context).textTheme.headlineLarge)),
                GestureDetector(
                  onTap: _signOut,
                  behavior: HitTestBehavior.opaque,
                  child: Icon(PhosphorIcons.signOut(), size: 22, color: RoostColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(height: RoostSpacing.md),
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorView();
    final stats = _stats!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, 0, RoostSpacing.xl, RoostSpacing.xxl),
        children: [
          Wrap(
            spacing: RoostSpacing.md,
            runSpacing: RoostSpacing.md,
            children: [
              _StatCard(label: 'Total beds', value: '${stats.totalBeds}'),
              _StatCard(label: 'Occupied', value: '${stats.occupied}'),
              _StatCard(label: 'Available', value: '${stats.available}'),
              _StatCard(label: 'Occupancy', value: '${stats.occupancyPct}%'),
              _StatCard(label: 'Revenue', value: stats.revenueFull, wide: true),
            ],
          ),
          const SizedBox(height: RoostSpacing.xl),
          Text('By hostel', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
          const SizedBox(height: RoostSpacing.md),
          if (stats.perHostel.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: RoostSpacing.lg),
              child: Text('No hostels yet.', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
            ),
          for (final h in stats.perHostel) ...[
            _OccupancyRow(h: h),
            const SizedBox(height: RoostSpacing.md),
          ],
        ],
      ),
    );
  }

  Widget _errorView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.warningCircle(), size: 40, color: RoostColors.textTertiary),
            const SizedBox(height: RoostSpacing.md),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.xxl),
              child: Text(_error!, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: RoostColors.textSecondary)),
            ),
            const SizedBox(height: RoostSpacing.md),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.wide = false});
  final String label, value;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: wide ? double.infinity : 152,
      child: RoostSurfaceCard(
        floating: true,
        padding: const EdgeInsets.all(RoostSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: RoostColors.textPrimary, letterSpacing: -0.5)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: RoostColors.textTertiary, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

class _OccupancyRow extends StatelessWidget {
  const _OccupancyRow({required this.h});
  final HostelOccupancy h;

  @override
  Widget build(BuildContext context) {
    final pct = (h.pct * 100).round();
    return RoostSurfaceCard(
      floating: true,
      padding: const EdgeInsets.all(RoostSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(h.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
              Text('${h.occupied} / ${h.total} · $pct%',
                  style: TextStyle(fontSize: 13, color: RoostColors.textTertiary, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: RoostSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: h.pct.clamp(0, 1),
              minHeight: 6,
              backgroundColor: RoostColors.surface2,
              valueColor: AlwaysStoppedAnimation(pct > 90 ? RoostColors.negative : RoostColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
