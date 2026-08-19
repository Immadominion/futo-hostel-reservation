import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/admin/admin_models.dart';
import '../../../core/api/admin_api.dart';
import '../../../core/api/roost_api.dart' show ApiException;
import '../../../core/demo/hostel_data.dart' show Hostel, Room;
import '../../../core/theme/brightness_provider.dart';
import '../../../core/theme/squircle_button.dart';
import '../../../core/theme/surface_card.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/wavy_sheet.dart';

/// All reservations, filterable, with an inline "Allocate" action for
/// anything still pending — the mobile port of both the web dashboard's
/// Reservations page *and* its separate Allocation queue (folded into one,
/// since they're the same underlying data — see the design discussion).
class AdminReservationsPage extends ConsumerStatefulWidget {
  const AdminReservationsPage({super.key});

  @override
  ConsumerState<AdminReservationsPage> createState() => _AdminReservationsPageState();
}

class _AdminReservationsPageState extends ConsumerState<AdminReservationsPage> {
  static const _filters = ['All', 'Pending', 'Paid', 'Cancelled'];
  String _filter = 'All';

  List<AdminReservation> _reservations = [];
  Map<String, String> _hostelNames = {};
  bool _loading = true;
  String? _error;

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
      final api = ref.read(adminApiProvider);
      final results = await Future.wait([api.reservations(), api.hostels()]);
      final reservations = results[0] as List<AdminReservation>;
      final hostels = results[1] as List<Hostel>;
      if (!mounted) return;
      setState(() {
        _reservations = reservations;
        _hostelNames = {for (final h in hostels) h.id: h.name};
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
        _error = 'Could not load reservations.';
        _loading = false;
      });
    }
  }

  List<AdminReservation> get _filtered => _reservations.where((r) {
        return switch (_filter) {
          'Pending' => r.isPending,
          'Paid' => r.status == RoostStatus.paid,
          'Cancelled' => r.status == RoostStatus.cancelled,
          _ => true,
        };
      }).toList();

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
            child: Text('Reservations', style: Theme.of(context).textTheme.headlineLarge),
          ),
          const SizedBox(height: RoostSpacing.md),
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
          Expanded(child: _body()),
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _errorView();
    final list = _filtered;
    if (list.isEmpty) return _emptyView();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, 0, RoostSpacing.xl, RoostSpacing.xxl),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: RoostSpacing.md),
        itemBuilder: (ctx, i) => _ReservationCard(
          reservation: list[i],
          hostelName: _hostelNames[list[i].hostelId] ?? list[i].hostelId,
          onTap: () => _showDetail(list[i]),
          onAllocate: list[i].isPending ? () => _allocate(list[i]) : null,
        ),
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

  Widget _emptyView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(PhosphorIcons.clipboardText(), size: 40, color: RoostColors.textTertiary),
            const SizedBox(height: RoostSpacing.md),
            Text('No reservations here', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
          ],
        ),
      );

  Future<void> _showDetail(AdminReservation r) async {
    final hostelName = _hostelNames[r.hostelId] ?? r.hostelId;
    await showRoostWavySheet(
      context: context,
      headerGradient: r.status == RoostStatus.paid ? RoostGradients.accentHeader : RoostGradients.graphiteHeader,
      headerForeground: r.status == RoostStatus.paid ? RoostColors.onAccent : RoostColors.textPrimary,
      headerHeight: 150,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.clipboardText(),
              size: 34, color: r.status == RoostStatus.paid ? RoostColors.onAccent : RoostColors.textPrimary),
          const SizedBox(height: RoostSpacing.sm),
          Text(hostelName,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700,
                  color: r.status == RoostStatus.paid ? RoostColors.onAccent : RoostColors.textPrimary)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: StatusPill(r.status)),
            const SizedBox(height: RoostSpacing.lg),
            _row('Student', r.studentDisplay),
            if (r.studentLevel != null) _row('Level', r.studentLevel!),
            _row('Room', r.roomIndex > 0 ? 'Room ${r.roomIndex}' : '—'),
            _row('Bed', r.bed > 0 ? 'Bed ${r.bed}' : '—'),
            _row('Reference', r.reference, mono: true),
            _row('Payment Reference', r.rrr, mono: true),
            _row('Amount', r.feeFull),
            _row('Date', r.dateDisplay),
            const SizedBox(height: RoostSpacing.xl),
            if (r.isPending)
              RoostButton(
                label: 'Allocate',
                icon: PhosphorIcons.bed(),
                onPressed: () {
                  Navigator.of(context).pop();
                  _allocate(r);
                },
              )
            else
              RoostButton(
                label: 'Close',
                variant: RoostButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool mono = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
            const Spacer(),
            Flexible(
              child: Text(value,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600, color: RoostColors.textPrimary,
                    fontFamily: mono ? 'monospace' : 'Montserrat',
                  )),
            ),
          ],
        ),
      );

  Future<void> _allocate(AdminReservation r) async {
    final done = await showRoostWavySheet<bool>(
      context: context,
      headerHeight: 130,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.bed(), size: 30, color: RoostColors.onAccent),
          const SizedBox(height: RoostSpacing.sm),
          Text('Allocate a bed', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
        ],
      ),
      child: _AllocateSheetContent(reservation: r),
    );
    if (done == true) _load();
  }
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

class _ReservationCard extends StatelessWidget {
  const _ReservationCard({
    required this.reservation,
    required this.hostelName,
    required this.onTap,
    this.onAllocate,
  });
  final AdminReservation reservation;
  final String hostelName;
  final VoidCallback onTap;
  final VoidCallback? onAllocate;

  @override
  Widget build(BuildContext context) {
    return RoostSurfaceCard(
      floating: true,
      padding: const EdgeInsets.all(RoostSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(reservation.studentDisplay,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2))),
                        if (reservation.isPriority) ...[
                          const SizedBox(width: 6),
                          _PriorityTag(),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$hostelName  ·  ${reservation.roomIndex > 0 ? "Room ${reservation.roomIndex}" : "—"}',
                      style: TextStyle(fontSize: 12.5, color: RoostColors.textTertiary),
                    ),
                  ],
                ),
              ),
              StatusPill(reservation.status),
            ],
          ),
          if (onAllocate != null) ...[
            const SizedBox(height: RoostSpacing.md),
            SizedBox(
              width: double.infinity,
              child: RoostButton(
                label: 'Allocate',
                variant: RoostButtonVariant.secondary,
                icon: PhosphorIcons.bed(),
                fullWidth: true,
                onPressed: onAllocate,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityTag extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: ShapeDecoration(
        color: RoostColors.warningSubtle,
        shape: const SmoothRectangleBorder(
          borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.pill, cornerSmoothing: 1)),
        ),
      ),
      child: Text('Priority',
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: RoostColors.warning, letterSpacing: 0.2)),
    );
  }
}

/// Room → bed picker for a pending reservation, scoped to its hostel.
/// Same interaction pattern as the student reserve flow, driving
/// `POST /admin/reservations/:id/allocate` instead of `POST /reservations`.
class _AllocateSheetContent extends ConsumerStatefulWidget {
  const _AllocateSheetContent({required this.reservation});
  final AdminReservation reservation;

  @override
  ConsumerState<_AllocateSheetContent> createState() => _AllocateSheetContentState();
}

class _AllocateSheetContentState extends ConsumerState<_AllocateSheetContent> {
  List<Room> _rooms = [];
  bool _loading = true;
  String? _error;
  int? _roomIdx;
  int? _bed;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final rooms = await ref.read(adminApiProvider).rooms(hostelId: widget.reservation.hostelId);
      if (!mounted) return;
      setState(() {
        _rooms = rooms;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load rooms for this hostel.';
        _loading = false;
      });
    }
  }

  Future<void> _submit() async {
    final room = _rooms[_roomIdx!];
    setState(() => _submitting = true);
    try {
      await ref.read(adminApiProvider).allocate(widget.reservation.id, roomId: room.id, bed: _bed!);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not allocate. Please try again.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(RoostSpacing.xxl),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(RoostSpacing.xxl),
        child: Text(_error!, style: TextStyle(color: RoostColors.textSecondary)),
      );
    }

    final room = _roomIdx == null ? null : _rooms[_roomIdx!];
    final canSubmit = room != null && _bed != null && !_submitting;

    return Padding(
      padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.reservation.studentDisplay} — ${widget.reservation.studentRegNo ?? ""}',
              style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
          const SizedBox(height: RoostSpacing.lg),
          for (var i = 0; i < _rooms.length; i++) ...[
            _RoomOption(
              room: _rooms[i],
              selected: _roomIdx == i,
              onTap: _rooms[i].bedsAvailable == 0
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
            Text('Pick a bed', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: RoostSpacing.md),
            _BedGrid(
              capacity: room.bedsTotal,
              selected: _bed,
              isTaken: room.isTaken,
              onPick: (b) => setState(() => _bed = b),
            ),
          ],
          const SizedBox(height: RoostSpacing.xl),
          RoostButton(
            label: 'Confirm allocation',
            isLoading: _submitting,
            onPressed: canSubmit ? _submit : null,
          ),
        ],
      ),
    );
  }
}

class _RoomOption extends StatelessWidget {
  const _RoomOption({required this.room, required this.selected, required this.onTap});
  final Room room;
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
                    Text('Room ${room.index}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                    const SizedBox(height: 2),
                    Text('${room.bedsAvailable} of ${room.bedsTotal} beds open',
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
        width: 52, height: 52,
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
            Icon(PhosphorIcons.bed(), size: 16, color: fg),
            const SizedBox(height: 2),
            Text('$bed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
          ],
        ),
      ),
    );
  }
}
