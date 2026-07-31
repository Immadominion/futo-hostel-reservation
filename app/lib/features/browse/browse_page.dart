import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/demo/hostel_data.dart';
import '../../core/theme/brightness_provider.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/hostel_card.dart';
import '../../core/widgets/roost_input.dart';
import '../../core/widgets/status_pill.dart';

/// Browse + search + filter the hostels (FR4, FR5).
class BrowsePage extends ConsumerStatefulWidget {
  const BrowsePage({super.key});

  @override
  ConsumerState<BrowsePage> createState() => _BrowsePageState();
}

class _BrowsePageState extends ConsumerState<BrowsePage> {
  final _search = TextEditingController();
  String _q = '';
  String _filter = 'All';

  static const _filters = ['All', 'Male', 'Female', 'Mixed', 'Available'];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Hostel> get _filtered => HostelData.hostels.where((h) {
        final q = _q.trim().toLowerCase();
        final matchesQuery = q.isEmpty || h.name.toLowerCase().contains(q) || h.funder.toLowerCase().contains(q);
        final matchesFilter = switch (_filter) {
          'Male' => h.gender == Gender.male,
          'Female' => h.gender == Gender.female,
          'Mixed' => h.gender == Gender.mixed,
          'Available' => h.status != RoostStatus.full,
          _ => true,
        };
        return matchesQuery && matchesFilter;
      }).toList();

  @override
  Widget build(BuildContext context) {
    ref.watch(brightnessProvider);
    ref.watch(reservationsProvider); // reflect availability changes after a booking
    final list = _filtered;
    return SafeArea(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome back', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Find your space', style: Theme.of(context).textTheme.headlineLarge),
                const SizedBox(height: RoostSpacing.lg),
                RoostTextField(
                  controller: _search,
                  hint: 'Search hostels (A–E, NDDC, TETFund, PG)',
                  icon: PhosphorIcons.magnifyingGlass(),
                  onChanged: (v) => setState(() => _q = v),
                ),
                const SizedBox(height: RoostSpacing.md),
              ],
            ),
          ),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.xl),
              itemCount: _filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: RoostSpacing.sm),
              itemBuilder: (ctx, i) => _FilterChip(
                label: _filters[i],
                selected: _filter == _filters[i],
                onTap: () => setState(() => _filter = _filters[i]),
              ),
            ),
          ),
          const SizedBox(height: RoostSpacing.md),
          Expanded(
            child: list.isEmpty
                ? _empty()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.sm, RoostSpacing.xl, RoostSpacing.xxl),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: RoostSpacing.lg),
                    itemBuilder: (ctx, i) => HostelCard(
                      hostel: list[i],
                      onTap: () => context.push('/hostel/${list[i].id}'),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.magnifyingGlass(), size: 40, color: RoostColors.textTertiary),
            const SizedBox(height: RoostSpacing.md),
            Text('No hostels match', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Try a different filter or search.', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
          ],
        ),
      );
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.lg),
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: selected ? RoostColors.accentSubtle : RoostColors.surface1,
          shape: SmoothRectangleBorder(
            side: BorderSide(
              color: selected ? RoostColors.accent.withValues(alpha: 0.4) : RoostColors.borderDefault,
              width: selected ? 1 : 0.5,
            ),
            borderRadius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.pill, cornerSmoothing: 1)),
          ),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: selected ? RoostColors.accent : RoostColors.textSecondary,
            )),
      ),
    );
  }
}
