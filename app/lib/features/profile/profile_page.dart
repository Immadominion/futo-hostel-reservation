import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/demo/hostel_data.dart';
import '../../core/theme/brightness_provider.dart';
import '../../core/theme/squircle_button.dart';
import '../../core/theme/surface_card.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/hostel_glyph.dart';
import '../../core/widgets/roost_avatar.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/wavy_sheet.dart';

/// Profile + settings (identity, current stay, appearance toggle, sign out).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(brightnessProvider);
    final reservations = ref.watch(reservationsProvider);
    final activeList = reservations.where((r) => r.status == RoostStatus.paid).toList();
    final active = activeList.isEmpty ? null : activeList.first;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
        children: [
          Row(
            children: [
              Text('Profile', style: Theme.of(context).textTheme.headlineLarge),
              const Spacer(),
              GestureDetector(
                onTap: () => _settingsSheet(context, ref),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  width: 42, height: 42,
                  alignment: Alignment.center,
                  decoration: ShapeDecoration(
                    color: RoostColors.surface1,
                    shape: SmoothRectangleBorder(
                      side: BorderSide(color: RoostColors.borderSubtle, width: 0.5),
                      borderRadius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.md, cornerSmoothing: 0.6)),
                    ),
                  ),
                  child: Icon(PhosphorIcons.gearSix(), size: 20, color: RoostColors.textSecondary),
                ),
              ),
            ],
          ),
          const SizedBox(height: RoostSpacing.lg),
          RoostSurfaceCard(
            floating: true,
            child: Column(
              children: [
                Row(
                  children: [
                    RoostAvatar(label: HostelData.studentName, size: 60, accent: true),
                    const SizedBox(width: RoostSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(HostelData.studentName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text(HostelData.studentRegNo, style: TextStyle(fontSize: 14, color: RoostColors.textTertiary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: RoostSpacing.lg),
                Divider(height: 1, color: RoostColors.borderSubtle),
                const SizedBox(height: RoostSpacing.md),
                _kv('Department', HostelData.studentDept),
                _kv('Level', HostelData.studentLevel),
                _kv('School email', HostelData.studentEmail),
              ],
            ),
          ),
          const SizedBox(height: RoostSpacing.lg),
          Text('Your stay', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: RoostSpacing.md),
          if (active != null)
            RoostSurfaceCard(
              floating: true,
              padding: const EdgeInsets.all(RoostSpacing.lg),
              child: Row(
                children: [
                  HostelGlyph(code: HostelData.byId(active.hostelId).code, size: 46, accent: true),
                  const SizedBox(width: RoostSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(HostelData.byId(active.hostelId).name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text('${active.roomName}  ·  Bed ${active.bed}', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
                      ],
                    ),
                  ),
                  StatusPill(RoostStatus.paid),
                ],
              ),
            )
          else
            RoostSurfaceCard(
              floating: true,
              padding: const EdgeInsets.all(RoostSpacing.lg),
              child: Row(
                children: [
                  Icon(PhosphorIcons.bed(), size: 24, color: RoostColors.textTertiary),
                  const SizedBox(width: RoostSpacing.md),
                  Expanded(
                    child: Text('No active booking yet — reserve a bed to see your allocation here.',
                        style: TextStyle(fontSize: 13.5, color: RoostColors.textSecondary, height: 1.35)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: RoostSpacing.lg),
          RoostSurfaceCard(
            floating: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                _MenuItem(icon: PhosphorIcons.question(), label: 'Help & support'),
                _MenuItem(icon: PhosphorIcons.info(), label: 'About Roost'),
                _MenuItem(icon: PhosphorIcons.fileText(), label: 'Terms & privacy', last: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k, style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
            const Spacer(),
            Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600))),
          ],
        ),
      );

  void _settingsSheet(BuildContext context, WidgetRef ref) {
    showRoostWavySheet(
      context: context,
      headerGradient: RoostGradients.graphiteHeader,
      headerForeground: RoostColors.textPrimary,
      headerHeight: 132,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.gearSix(), size: 28, color: RoostColors.textPrimary),
          const SizedBox(height: 6),
          Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RoostColors.textPrimary)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
            const SizedBox(height: RoostSpacing.sm),
            const _AppearanceToggle(),
            const SizedBox(height: RoostSpacing.xl),
            RoostButton(
              label: 'Sign out',
              variant: RoostButtonVariant.destructive,
              icon: PhosphorIcons.signOut(),
              onPressed: () {
                Navigator.of(context).maybePop();
                context.go('/');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.icon, required this.label, this.last = false});
  final IconData icon;
  final String label;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.lg, vertical: RoostSpacing.md),
          child: Row(
            children: [
              Icon(icon, size: 20, color: RoostColors.textSecondary),
              const SizedBox(width: RoostSpacing.md),
              Expanded(child: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500))),
              Icon(PhosphorIcons.caretRight(), size: 16, color: RoostColors.textTertiary),
            ],
          ),
        ),
        if (!last) Padding(
          padding: const EdgeInsets.only(left: 52),
          child: Divider(height: 1, color: RoostColors.borderSubtle),
        ),
      ],
    );
  }
}

class _AppearanceToggle extends ConsumerWidget {
  const _AppearanceToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    final isLight = brightness == Brightness.light;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: ShapeDecoration(
        color: RoostColors.surface2,
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.md, cornerSmoothing: 0.6)),
        ),
      ),
      child: Row(
        children: [
          _seg(ref, 'Light', PhosphorIcons.sun(), isLight, Brightness.light),
          _seg(ref, 'Dark', PhosphorIcons.moon(), !isLight, Brightness.dark),
        ],
      ),
    );
  }

  Widget _seg(WidgetRef ref, String label, IconData icon, bool selected, Brightness b) {
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => ref.read(brightnessProvider.notifier).set(b),
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: ShapeDecoration(
            color: selected ? RoostColors.surface1 : Colors.transparent,
            shadows: selected ? RoostShadows.card : null,
            shape: const SmoothRectangleBorder(
              borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.sm, cornerSmoothing: 0.6)),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: selected ? RoostColors.accent : RoostColors.textTertiary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? RoostColors.textPrimary : RoostColors.textTertiary,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
