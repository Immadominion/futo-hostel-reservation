import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/api/roost_api.dart';
import '../../core/config/app_config.dart';
import '../../core/demo/hostel_data.dart';
import '../../core/theme/brightness_provider.dart';
import '../../core/theme/squircle_button.dart';
import '../../core/theme/surface_card.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/status_pill.dart';
import '../../core/widgets/wavy_sheet.dart';

/// Choose room + bed, then pay (mock Remita) and get the allocation receipt
/// (FR7, FR8, FR9).
class ReservePage extends ConsumerStatefulWidget {
  const ReservePage({super.key, required this.hostelId});
  final String hostelId;

  @override
  ConsumerState<ReservePage> createState() => _ReservePageState();
}

class _ReservePageState extends ConsumerState<ReservePage> {
  int? _roomIdx;
  int? _bed;
  bool _paying = false;

  int _openBeds(RoomType r) => r.bedsAvailable == 0 ? 0 : (r.capacity <= 4 ? 2 : 3);
  // Live mode: the server tells us exactly which beds are taken. Demo mode
  // falls back to a stable heuristic.
  bool _isTaken(RoomType r, int bed) => r.occupiedBeds.isNotEmpty
      ? r.occupiedBeds.contains(bed)
      : bed <= r.capacity - _openBeds(r);

  Future<void> _pay(Hostel h, RoomType room) async {
    setState(() => _paying = true);
    HapticFeedback.mediumImpact();
    try {
      final res = await _reserveAndPay(h, room);
      if (!mounted) return;
      setState(() => _paying = false);
      await _showReceipt(h, res);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _paying = false);
      _snack(e.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _paying = false);
      _snack('Payment could not be completed. Please try again.');
    }
  }

  /// Reserve → pay → confirm. Demo mode fakes it in memory; live mode holds the
  /// bed (POST /reservations), confirms via the payment simulate endpoint, then
  /// reads back the paid reservation for the receipt.
  Future<Reservation> _reserveAndPay(Hostel h, RoomType room) async {
    final bed = _bed!;
    if (AppConfig.useDemoData) {
      await Future.delayed(const Duration(milliseconds: 1600)); // mock Remita gateway
      return ref
          .read(reservationsProvider.notifier)
          .reserveDemo(hostel: h, room: room, bed: bed, fee: h.price);
    }
    final api = ref.read(roostApiProvider);
    final created = await api.createReservation(hostelId: h.id, roomId: room.id, bed: bed);
    await api.simulatePayment(created.rrr, success: true);
    Reservation res;
    try {
      res = await api.reservation(created.id); // paid, with final reference/RRR
    } catch (_) {
      res = created.copyWith(status: RoostStatus.paid);
    }
    if (room.bedsAvailable > 0) room.bedsAvailable -= 1; // reflect availability locally
    ref.read(reservationsProvider.notifier).add(res);
    return res;
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _showReceipt(Hostel h, Reservation res) async {
    await showRoostWavySheet(
      context: context,
      dismissible: false,
      headerHeight: 158,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.sealCheck(PhosphorIconsStyle.fill), size: 40, color: RoostColors.onAccent),
          const SizedBox(height: RoostSpacing.sm),
          Text('Reservation confirmed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _row('Hostel', h.name),
            _row('Room', res.roomName),
            _row('Bed', 'Bed ${res.bed}'),
            _row('Reference', res.reference, mono: true),
            _row('Remita RRR', res.rrr, mono: true),
            _row('Amount paid', res.feeFull, strong: true),
            const SizedBox(height: RoostSpacing.lg),
            Container(
              padding: const EdgeInsets.all(RoostSpacing.md),
              decoration: ShapeDecoration(
                color: RoostColors.accentSubtle,
                shape: const SmoothRectangleBorder(
                  borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.md, cornerSmoothing: 0.6)),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(PhosphorIcons.info(), size: 16, color: RoostColors.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Show this allocation slip at the Student Affairs Unit to check in.',
                        style: TextStyle(fontSize: 12.5, color: RoostColors.accent, height: 1.35, fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: RoostSpacing.xl),
            RoostButton(
              label: 'Done',
              onPressed: () {
                Navigator.of(context).pop();
                context.go('/home?tab=1');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false, bool strong = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
            const Spacer(),
            Flexible(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: strong ? 15 : 13.5,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  color: strong ? RoostColors.accent : RoostColors.textPrimary,
                  fontFamily: mono ? 'monospace' : 'Montserrat',
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    ref.watch(brightnessProvider);
    final h = HostelData.byId(widget.hostelId);
    final room = _roomIdx == null ? null : h.rooms[_roomIdx!];
    final canPay = room != null && _bed != null && !_paying;

    return Scaffold(
      backgroundColor: RoostColors.surface0,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(RoostSpacing.md, RoostSpacing.sm, RoostSpacing.xl, RoostSpacing.sm),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(PhosphorIcons.caretLeft(), size: 22, color: RoostColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reserve a bed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RoostColors.textPrimary)),
                      Text(h.name, style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xl),
              children: [
                _stepLabel('1', 'Choose a room'),
                const SizedBox(height: RoostSpacing.md),
                for (var i = 0; i < h.rooms.length; i++) ...[
                  _RoomOption(
                    room: h.rooms[i],
                    selected: _roomIdx == i,
                    onTap: h.rooms[i].bedsAvailable == 0
                        ? null
                        : () => setState(() {
                              _roomIdx = i;
                              _bed = null;
                            }),
                  ),
                  const SizedBox(height: RoostSpacing.md),
                ],
                if (room != null) ...[
                  const SizedBox(height: RoostSpacing.sm),
                  _stepLabel('2', 'Pick a bed'),
                  const SizedBox(height: RoostSpacing.md),
                  _BedGrid(
                    capacity: room.capacity,
                    selected: _bed,
                    isTaken: (b) => _isTaken(room, b),
                    onPick: (b) => setState(() => _bed = b),
                  ),
                ],
                const SizedBox(height: RoostSpacing.xl),
                _FeeSummary(hostel: h, room: room, bed: _bed),
              ],
            ),
          ),
          _bottomBar(context, h, room, canPay),
        ],
      ),
    );
  }

  Widget _stepLabel(String n, String t) => Row(
        children: [
          Container(
            width: 22, height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: RoostColors.accent, shape: BoxShape.circle),
            child: Text(n, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
          ),
          const SizedBox(width: RoostSpacing.sm),
          Text(t, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
        ],
      );

  Widget _bottomBar(BuildContext context, Hostel h, RoomType? room, bool canPay) {
    return Container(
      decoration: BoxDecoration(
        color: RoostColors.surface1,
        border: Border(top: BorderSide(color: RoostColors.borderSubtle, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.md, RoostSpacing.xl, RoostSpacing.md),
          child: RoostButton(
            label: _paying ? 'Processing…' : 'Pay ${h.priceFull}',
            icon: _paying ? null : PhosphorIcons.lockSimple(PhosphorIconsStyle.fill),
            isLoading: _paying,
            onPressed: canPay ? () => _pay(h, room!) : null,
          ),
        ),
      ),
    );
  }
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({required this.room, required this.selected, required this.onTap});
  final RoomType room;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final disabled = room.bedsAvailable == 0;
    final status = disabled
        ? RoostStatus.full
        : room.bedsAvailable <= 4
            ? RoostStatus.limited
            : RoostStatus.available;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(RoostSpacing.lg),
          decoration: ShapeDecoration(
            color: selected ? RoostColors.accentSubtle : RoostColors.surface1,
            shadows: selected ? null : RoostShadows.card,
            shape: SmoothRectangleBorder(
              side: BorderSide(
                color: selected ? RoostColors.accent : RoostColors.borderSubtle,
                width: selected ? 1.4 : 0.5,
              ),
              borderRadius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.lg, cornerSmoothing: 0.6)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill) : PhosphorIcons.circle(),
                size: 22, color: selected ? RoostColors.accent : RoostColors.textTertiary,
              ),
              const SizedBox(width: RoostSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text('${room.capacity} per room  ·  ${room.bedsAvailable} beds open',
                        style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
                  ],
                ),
              ),
              StatusPill(status),
            ],
          ),
        ),
      ),
    );
  }
}

class _BedGrid extends StatelessWidget {
  const _BedGrid({required this.capacity, required this.selected, required this.isTaken, required this.onPick});
  final int capacity;
  final int? selected;
  final bool Function(int bed) isTaken;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RoostSpacing.md,
      runSpacing: RoostSpacing.md,
      children: [
        for (var bed = 1; bed <= capacity; bed++)
          _BedTile(bed: bed, taken: isTaken(bed), selected: selected == bed, onTap: () => onPick(bed)),
      ],
    );
  }
}

class _BedTile extends StatelessWidget {
  const _BedTile({required this.bed, required this.taken, required this.selected, required this.onTap});
  final int bed;
  final bool taken;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color bg, fg, border;
    if (taken) {
      bg = RoostColors.surface2; fg = RoostColors.textDisabled; border = RoostColors.borderSubtle;
    } else if (selected) {
      bg = RoostColors.accent; fg = RoostColors.onAccent; border = RoostColors.accent;
    } else {
      bg = RoostColors.surface1; fg = RoostColors.textPrimary; border = RoostColors.borderDefault;
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: taken ? null : onTap,
      child: Container(
        width: 58, height: 58,
        alignment: Alignment.center,
        decoration: ShapeDecoration(
          color: bg,
          shape: SmoothRectangleBorder(
            side: BorderSide(color: border, width: selected ? 1.4 : 0.5),
            borderRadius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.md, cornerSmoothing: 0.6)),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(PhosphorIcons.bed(), size: 18, color: fg),
            const SizedBox(height: 2),
            Text('$bed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}

class _FeeSummary extends StatelessWidget {
  const _FeeSummary({required this.hostel, required this.room, required this.bed});
  final Hostel hostel;
  final RoomType? room;
  final int? bed;

  @override
  Widget build(BuildContext context) {
    return RoostSurfaceCard(
      elevated: true,
      child: Column(
        children: [
          _line('Hostel', hostel.name),
          _line('Room', room?.name ?? '—'),
          _line('Bed', bed == null ? '—' : 'Bed $bed'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: RoostSpacing.md),
            child: Divider(height: 1, color: RoostColors.borderSubtle),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Total', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
                    Text('per session', style: TextStyle(fontSize: 11, color: RoostColors.textTertiary)),
                  ],
                ),
              ),
              const SizedBox(width: RoostSpacing.md),
              Text(hostel.priceFull,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: RoostColors.accent, letterSpacing: -0.4)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _line(String l, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Text(l, style: TextStyle(fontSize: 13.5, color: RoostColors.textTertiary)),
            const Spacer(),
            Flexible(child: Text(v, textAlign: TextAlign.right, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          ],
        ),
      );
}
