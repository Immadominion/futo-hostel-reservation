import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/admin_api.dart';
import '../../../core/api/roost_api.dart' show ApiException;
import '../../../core/demo/hostel_data.dart' show GenderLabel, Hostel, RoomType;
import '../../../core/theme/brightness_provider.dart';
import '../../../core/theme/squircle_button.dart';
import '../../../core/theme/surface_card.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/hostel_glyph.dart';
import '../../../core/widgets/roost_input.dart';
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

  Future<void> _createRoom() async {
    final created = await showRoostWavySheet<bool>(
      context: context,
      headerHeight: 130,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.bed(), size: 30, color: RoostColors.onAccent),
          const SizedBox(height: RoostSpacing.sm),
          Text('New room type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
        ],
      ),
      child: _RoomForm(hostelId: widget.hostelId),
    );
    if (created == true) _load();
  }

  Future<void> _editRoom(RoomType room) async {
    final saved = await showRoostWavySheet<bool>(
      context: context,
      headerHeight: 130,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.pencilSimple(), size: 30, color: RoostColors.onAccent),
          const SizedBox(height: RoostSpacing.sm),
          Text('Edit room type', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
        ],
      ),
      child: _RoomForm(hostelId: widget.hostelId, existing: room),
    );
    if (saved == true) _load();
  }

  Future<void> _deleteRoom(RoomType room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${room.name}"?'),
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
              Expanded(child: Text('Room types', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.2))),
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
              child: Text('No room types yet.', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
            ),
          for (final room in hostel.rooms) ...[
            _RoomRow(room: room, onEdit: () => _editRoom(room), onDelete: () => _deleteRoom(room)),
            const SizedBox(height: RoostSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onEdit, required this.onDelete});
  final RoomType room;
  final VoidCallback onEdit;
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
                Text(room.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text('${room.capacity} per room · ${room.bedsAvailable}/${room.bedsTotal} beds open',
                    style: TextStyle(fontSize: 12.5, color: RoostColors.textTertiary)),
              ],
            ),
          ),
          StatusPill(status),
          const SizedBox(width: RoostSpacing.sm),
          GestureDetector(
            onTap: onEdit,
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Icon(PhosphorIcons.pencilSimple(), size: 18, color: RoostColors.textSecondary),
            ),
          ),
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

class _RoomForm extends ConsumerStatefulWidget {
  const _RoomForm({required this.hostelId, this.existing});
  final String hostelId;
  final RoomType? existing;

  @override
  ConsumerState<_RoomForm> createState() => _RoomFormState();
}

class _RoomFormState extends ConsumerState<_RoomForm> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _capacity = TextEditingController(text: widget.existing?.capacity.toString() ?? '');
  late final _bedsTotal = TextEditingController(text: widget.existing?.bedsTotal.toString() ?? '');
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    _name.dispose();
    _capacity.dispose();
    _bedsTotal.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final capacity = int.tryParse(_capacity.text.trim());
    final bedsTotal = int.tryParse(_bedsTotal.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'Name is required.');
      return;
    }
    if (capacity == null || capacity < 1) {
      setState(() => _error = 'Enter a valid capacity.');
      return;
    }
    if (bedsTotal == null || bedsTotal < 1) {
      setState(() => _error = 'Enter a valid total bed count.');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final api = ref.read(adminApiProvider);
      if (_isEdit) {
        await api.updateRoom(widget.existing!.id, {'name': name, 'capacity': capacity, 'bedsTotal': bedsTotal});
      } else {
        await api.createRoom(hostelId: widget.hostelId, name: name, capacity: capacity, bedsTotal: bedsTotal);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _busy = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not save. Please try again.';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _label('Name'),
          RoostTextField(controller: _name, hint: '8-bed room'),
          const SizedBox(height: RoostSpacing.md),
          _label('Capacity (beds per physical room)'),
          RoostTextField(controller: _capacity, hint: '8', keyboardType: TextInputType.number),
          const SizedBox(height: RoostSpacing.md),
          _label('Total beds of this type in the hostel'),
          RoostTextField(controller: _bedsTotal, hint: '48', keyboardType: TextInputType.number),
          if (_isEdit) ...[
            const SizedBox(height: RoostSpacing.sm),
            Text('Shrinking this fails if occupied beds would be removed.',
                style: TextStyle(fontSize: 11.5, color: RoostColors.textTertiary)),
          ],
          if (_error != null) ...[
            const SizedBox(height: RoostSpacing.md),
            Text(_error!, style: TextStyle(fontSize: 12.5, color: RoostColors.negative)),
          ],
          const SizedBox(height: RoostSpacing.xl),
          RoostButton(
            label: _isEdit ? 'Save changes' : 'Create room type',
            isLoading: _busy,
            onPressed: _busy ? null : _submit,
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: RoostSpacing.sm, left: 2),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
      );
}
