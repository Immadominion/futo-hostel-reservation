import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/demo/hostel_data.dart';
import '../../core/theme/brightness_provider.dart';
import '../../core/theme/squircle_button.dart';
import '../../core/theme/surface_card.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/status_pill.dart';

/// Hostel detail: cover, description, location (Google Maps), rooms, reserve CTA
/// (FR6). The reserve button enforces "one active reservation" (FR7).
class HostelDetailPage extends ConsumerWidget {
  const HostelDetailPage({super.key, required this.hostelId});
  final String hostelId;

  Future<void> _openMap(Hostel h) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${h.lat},${h.lng}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(brightnessProvider);
    ref.watch(reservationsProvider);
    final h = HostelData.byId(hostelId);
    final hasActive = ref.read(reservationsProvider.notifier).hasActive;
    final full = h.status == RoostStatus.full;

    return Scaffold(
      backgroundColor: RoostColors.surface0,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _cover(context, h),
                Padding(
                  padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.xl, RoostSpacing.xl, RoostSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(h.name, style: Theme.of(context).textTheme.headlineLarge),
                                const SizedBox(height: 4),
                                Text('${h.gender.label}  ·  ${h.roomSize}',
                                    style: TextStyle(fontSize: 14, color: RoostColors.textSecondary)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(h.priceFull,
                                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: RoostColors.accent, letterSpacing: -0.5)),
                              Text('per session', style: TextStyle(fontSize: 12, color: RoostColors.textTertiary)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: RoostSpacing.lg),
                      Text(h.blurb, style: TextStyle(fontSize: 15, height: 1.5, color: RoostColors.textSecondary)),
                      const SizedBox(height: RoostSpacing.xl),
                      RoostButton(
                        label: 'View on map',
                        variant: RoostButtonVariant.secondary,
                        icon: PhosphorIcons.mapPin(),
                        onPressed: () => _openMap(h),
                      ),
                      const SizedBox(height: RoostSpacing.xl),
                      _AvailabilityHero(h: h),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _bottomBar(context, h, full: full, hasActive: hasActive),
        ],
      ),
    );
  }

  Widget _cover(BuildContext context, Hostel h) {
    return SizedBox(
      height: 220,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft, end: Alignment.bottomRight,
                colors: [Color(h.coverA), Color(h.coverB)],
              ),
            ),
          ),
          Center(child: Icon(PhosphorIcons.buildings(), size: 84, color: Colors.white.withValues(alpha: 0.9))),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(RoostSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 40, height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.22), shape: BoxShape.circle),
                      child: Icon(PhosphorIcons.caretLeft(), size: 20, color: Colors.white),
                    ),
                  ),
                  StatusPill(h.status),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomBar(BuildContext context, Hostel h, {required bool full, required bool hasActive}) {
    return Container(
      decoration: BoxDecoration(
        color: RoostColors.surface1,
        border: Border(top: BorderSide(color: RoostColors.borderSubtle, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.md, RoostSpacing.xl, RoostSpacing.md),
          child: full
              ? RoostButton(label: 'Fully booked', onPressed: null)
              : hasActive
                  ? RoostButton(
                      label: 'View my booking',
                      variant: RoostButtonVariant.secondary,
                      icon: PhosphorIcons.ticket(),
                      onPressed: () => context.go('/home?tab=1'),
                    )
                  : RoostButton(
                      label: 'Reserve a bed',
                      icon: PhosphorIcons.bed(),
                      onPressed: () => context.push('/hostel/${h.id}/reserve'),
                    ),
        ),
      ),
    );
  }
}

class _AvailabilityHero extends StatelessWidget {
  const _AvailabilityHero({required this.h});
  final Hostel h;

  @override
  Widget build(BuildContext context) {
    final frac = h.bedsTotal == 0 ? 0.0 : h.bedsAvailable / h.bedsTotal;
    return RoostSurfaceCard(
      floating: true,
      glow: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${h.bedsAvailable}',
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: RoostColors.accent, height: 1, letterSpacing: -1)),
              const SizedBox(width: 6),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('of ${h.bedsTotal} beds open',
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 14, color: RoostColors.textSecondary, fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
          const SizedBox(height: RoostSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 8,
              backgroundColor: RoostColors.surface2,
              valueColor: AlwaysStoppedAnimation(RoostColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
