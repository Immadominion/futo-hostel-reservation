import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/admin_api.dart';
import '../../../core/api/roost_api.dart' show ApiException;
import '../../../core/demo/hostel_data.dart' show GenderLabel, Hostel, Room;
import '../../../core/theme/brightness_provider.dart';
import '../../../core/theme/surface_card.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/hostel_glyph.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/wavy_sheet.dart';
import 'admin_hostels_page.dart' show HostelForm;

/// One hostel: header + full room-type CRUD — the part the web dashboard
/// doesn't have at all (it only supports adding a hostel with one default
/// room; the backend has always supported full room CRUD, this is the first
/// UI for it).
class AdminHostelDetailPage extends ConsumerStatefulWidget {
  const AdminHostelDetailPage({super.key, required this.hostelId});
  final String hostelId;

  @override
  ConsumerState<AdminHostelDetailPage> createState() => _AdminHostelDetailPageState();
}

class _AdminHostelDetailPageState extends ConsumerState<AdminHostelDetailPage> {
  Hostel? _hostel;
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
      final hostel = await ref.read(adminApiProvider).hostel(widget.hostelId);
      if (!mounted) return;
      setState(() {
        _hostel = hostel;
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
        _error = 'Could not load this hostel.';
        _loading = false;
      });
    }
  }

  Future<void> _edit() async {
    final saved = await showRoostWavySheet<bool>(
      context: context,
      headerHeight: 130,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.pencilSimple(), size: 30, color: RoostColors.onAccent),
          const SizedBox(height: RoostSpacing.sm),
          Text('Edit hostel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
        ],
      ),
      child: HostelForm(existing: _hostel),
    );
    if (saved == true) _load();
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this hostel?'),
        content: Text('This fails if it has active reservations. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: RoostColors.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminApiProvider).deleteHostel(widget.hostelId);
      if (mounted) context.pop();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete. Please try again.')));
      }
    }
  }

  /// Capacity is fixed per hostel now, so adding a room has nothing to
  /// configure — it's just "add one more room the same size as the rest."
  Future<void> _createRoom() async {
    final hostel = _hostel;
    if (hostel == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a room?'),
        content: Text('Adds one more room with ${hostel.capacity} beds, same as every other room here.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Add')),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminApiProvider).createRoom(hostelId: widget.hostelId);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not add. Please try again.')));
      }
    }
  }

  Future<void> _deleteRoom(Room room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete Room ${room.index}?'),
        content: const Text('This fails if it has active reservations. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Delete', style: TextStyle(color: RoostColors.negative)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(adminApiProvider).deleteRoom(room.id);
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not delete. Please try again.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(brightnessProvider);
    return Scaffold(
      backgroundColor: RoostColors.surface0,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(context),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _topBar(BuildContext context) {
    return Padding(
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
          Expanded(
            child: Text(_hostel?.name ?? widget.hostelId,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: RoostColors.textPrimary)),
          ),
          if (_hostel != null) ...[
            GestureDetector(
              onTap: _edit,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(PhosphorIcons.pencilSimple(), size: 20, color: RoostColors.textSecondary),
              ),
            ),
            GestureDetector(
              onTap: _delete,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(PhosphorIcons.trash(), size: 20, color: RoostColors.negative),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _body() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_error!, style: TextStyle(color: RoostColors.textSecondary)),
            const SizedBox(height: RoostSpacing.md),
            TextButton(onPressed: _load, child: const Text('Retry')),
          ],
        ),
      );
    }
    final hostel = _hostel!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, 0, RoostSpacing.xl, RoostSpacing.xxl),
        children: [
          RoostSurfaceCard(
            floating: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HostelGlyph(code: hostel.code, size: 48),
                    const SizedBox(width: RoostSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${hostel.funder} · ${hostel.gender.label}', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
                          Text(hostel.priceFull, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: RoostColors.accent)),
                        ],
                      ),
                    ),
                    StatusPill(hostel.status),
                  ],
                ),
                if (hostel.blurb.isNotEmpty) ...[
                  const SizedBox(height: RoostSpacing.md),
                  Text(hostel.blurb, style: TextStyle(fontSize: 13, color: RoostColors.textSecondary, height: 1.4)),
                ],
                const SizedBox(height: RoostSpacing.md),
                Text('${hostel.bedsAvailable} of ${hostel.bedsTotal} beds available',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: RoostColors.textTertiary)),
              ],
            ),
          ),
          const SizedBox(height: RoostSpacing.xl),
          Row(
            children: [
              Expanded(
                child: Text('Rooms · ${hostel.capacity} per room',
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
              ),
              GestureDetector(
                onTap: _createRoom,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  children: [
                    Icon(PhosphorIcons.plus(), size: 16, color: RoostColors.accent),
                    const SizedBox(width: 4),
                    Text('Add', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: RoostColors.accent)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: RoostSpacing.md),
          if (hostel.rooms.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: RoostSpacing.lg),
              child: Text('No rooms yet.', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
            ),
          for (final room in hostel.rooms) ...[
            _RoomRow(room: room, onDelete: () => _deleteRoom(room)),
            const SizedBox(height: RoostSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onDelete});
  final Room room;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final status = room.bedsAvailable == 0
        ? RoostStatus.full
        : room.bedsAvailable <= 4
            ? RoostStatus.limited
            : RoostStatus.available;
    return RoostSurfaceCard(
      floating: true,
      padding: const EdgeInsets.all(RoostSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Room ${room.index}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text('${room.bedsAvailable}/${room.bedsTotal} beds open',
                    style: TextStyle(fontSize: 12.5, color: RoostColors.textTertiary)),
              ],
            ),
          ),
          StatusPill(status),
          const SizedBox(width: RoostSpacing.sm),
          GestureDetector(
            onTap: onDelete,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(PhosphorIcons.trash(), size: 18, color: RoostColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}
