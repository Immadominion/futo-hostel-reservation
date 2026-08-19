import 'package:figma_squircle/figma_squircle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/api/admin_api.dart';
import '../../../core/api/roost_api.dart' show ApiException;
import '../../../core/demo/hostel_data.dart' show Gender, GenderLabel, Hostel;
import '../../../core/theme/brightness_provider.dart';
import '../../../core/theme/squircle_button.dart';
import '../../../core/theme/surface_card.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/hostel_glyph.dart';
import '../../../core/widgets/roost_input.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../core/widgets/wavy_sheet.dart';

/// A small preset of on-brand gradient pairs. Raw ARGB cover colours aren't a
/// field an admin should type by hand — one is picked automatically per new
/// hostel, cycling through the set (editing the exact colour later isn't
/// exposed here; it's a cosmetic-only field).
const _kCoverPresets = [
  (0xFF1E3A8A, 0xFF2563EB),
  (0xFF0F766E, 0xFF0EA5A4),
  (0xFF1D4ED8, 0xFF3B82F6),
  (0xFF134E4A, 0xFF0D9488),
  (0xFF4C1D95, 0xFF6D28D9),
  (0xFF155E75, 0xFF0891B2),
];

/// All hostels — the mobile port of the web dashboard's Hostels page, plus
/// full create/edit/delete (the web dashboard only has "add", not edit).
class AdminHostelsPage extends ConsumerStatefulWidget {
  const AdminHostelsPage({super.key});

  @override
  ConsumerState<AdminHostelsPage> createState() => _AdminHostelsPageState();
}

class _AdminHostelsPageState extends ConsumerState<AdminHostelsPage> {
  List<Hostel> _hostels = [];
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
      final hostels = await ref.read(adminApiProvider).hostels();
      if (!mounted) return;
      setState(() {
        _hostels = hostels;
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
        _error = 'Could not load hostels.';
        _loading = false;
      });
    }
  }

  Future<void> _create() async {
    final created = await showRoostWavySheet<bool>(
      context: context,
      headerHeight: 130,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.buildings(), size: 30, color: RoostColors.onAccent),
          const SizedBox(height: RoostSpacing.sm),
          Text('New hostel', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
        ],
      ),
      child: const HostelForm(),
    );
    if (created == true) _load();
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
                Expanded(child: Text('Hostels', style: Theme.of(context).textTheme.headlineLarge)),
                GestureDetector(
                  onTap: _create,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 36, height: 36,
                    alignment: Alignment.center,
                    decoration: ShapeDecoration(
                      color: RoostColors.accent,
                      shape: const SmoothRectangleBorder(
                        borderRadius: SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.sm, cornerSmoothing: 0.6)),
                      ),
                    ),
                    child: Icon(PhosphorIcons.plus(), size: 20, color: RoostColors.onAccent),
                  ),
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
    if (_hostels.isEmpty) return _emptyView();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, 0, RoostSpacing.xl, RoostSpacing.xxl),
        itemCount: _hostels.length,
        separatorBuilder: (_, _) => const SizedBox(height: RoostSpacing.md),
        itemBuilder: (ctx, i) => _HostelRow(
          hostel: _hostels[i],
          onTap: () => context.push('/hostel/${_hostels[i].id}'),
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
            Icon(PhosphorIcons.buildings(), size: 40, color: RoostColors.textTertiary),
            const SizedBox(height: RoostSpacing.md),
            Text('No hostels yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
            const SizedBox(height: 4),
            Text('Tap + to add the first one.', style: TextStyle(fontSize: 13, color: RoostColors.textTertiary)),
          ],
        ),
      );
}

class _HostelRow extends StatelessWidget {
  const _HostelRow({required this.hostel, required this.onTap});
  final Hostel hostel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RoostSurfaceCard(
      floating: true,
      padding: const EdgeInsets.all(RoostSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          HostelGlyph(code: hostel.code, size: 44),
          const SizedBox(width: RoostSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hostel.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: -0.2)),
                const SizedBox(height: 2),
                Text('${hostel.funder} · ${hostel.gender.label} · ${hostel.priceFull}',
                    style: TextStyle(fontSize: 12.5, color: RoostColors.textTertiary)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(hostel.status),
              const SizedBox(height: 6),
              Text('${hostel.bedsAvailable}/${hostel.bedsTotal} beds', style: TextStyle(fontSize: 11, color: RoostColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Create/edit form. Pass [existing] to edit (id becomes read-only, fields
/// pre-filled, submits a PATCH); omit it to create (submits a POST). Public —
/// reused from [AdminHostelDetailPage] for editing.
class HostelForm extends ConsumerStatefulWidget {
  const HostelForm({super.key, this.existing});
  final Hostel? existing;

  @override
  ConsumerState<HostelForm> createState() => _HostelFormState();
}

class _HostelFormState extends ConsumerState<HostelForm> {
  late final _id = TextEditingController(text: widget.existing?.id ?? '');
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _code = TextEditingController(text: widget.existing?.code ?? '');
  late final _funder = TextEditingController(text: widget.existing?.funder ?? 'School');
  late final _price = TextEditingController(text: widget.existing?.price.toString() ?? '');
  late final _roomSize = TextEditingController(text: widget.existing?.roomSize ?? '');
  late final _blurb = TextEditingController(text: widget.existing?.blurb ?? '');
  late final _lat = TextEditingController(text: (widget.existing?.lat ?? 5.3865).toString());
  late final _lng = TextEditingController(text: (widget.existing?.lng ?? 7.0350).toString());
  late Gender _gender = widget.existing?.gender ?? Gender.male;
  bool _busy = false;
  String? _error;

  bool get _isEdit => widget.existing != null;

  @override
  void dispose() {
    for (final c in [_id, _name, _code, _funder, _price, _roomSize, _blurb, _lat, _lng]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    final id = _id.text.trim();
    final name = _name.text.trim();
    final code = _code.text.trim();
    final price = int.tryParse(_price.text.trim());
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());

    if (id.isEmpty || name.isEmpty || code.isEmpty) {
      setState(() => _error = 'ID, name, and code are required.');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Enter a valid price.');
      return;
    }
    if (lat == null || lng == null) {
      setState(() => _error = 'Enter valid coordinates.');
      return;
    }

    setState(() {
      _error = null;
      _busy = true;
    });
    try {
      final api = ref.read(adminApiProvider);
      if (_isEdit) {
        await api.updateHostel(widget.existing!.id, {
          'name': name, 'code': code, 'funder': _funder.text.trim(), 'gender': _genderStr(_gender),
          'price': price, 'roomSize': _roomSize.text.trim(), 'blurb': _blurb.text.trim(),
          'lat': lat, 'lng': lng,
        });
      } else {
        final preset = _kCoverPresets[id.hashCode.abs() % _kCoverPresets.length];
        await api.createHostel(
          id: id, name: name, code: code, funder: _funder.text.trim(), gender: _gender,
          price: price, roomSize: _roomSize.text.trim(), blurb: _blurb.text.trim(),
          lat: lat, lng: lng, coverA: preset.$1, coverB: preset.$2,
        );
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

  String _genderStr(Gender g) => switch (g) {
        Gender.male => 'male', Gender.female => 'female', Gender.mixed => 'mixed', Gender.postgrad => 'postgrad',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isEdit) ...[
              _label('ID (short code, e.g. "F")'),
              RoostTextField(controller: _id, hint: 'F'),
              const SizedBox(height: RoostSpacing.md),
            ],
            _label('Name'),
            RoostTextField(controller: _name, hint: 'Hostel F'),
            const SizedBox(height: RoostSpacing.md),
            _label('Badge'),
            RoostTextField(controller: _code, hint: 'F'),
            const SizedBox(height: RoostSpacing.md),
            _label('Funder'),
            RoostTextField(controller: _funder, hint: 'School'),
            const SizedBox(height: RoostSpacing.md),
            _label('Gender'),
            _GenderPicker(value: _gender, onChanged: (g) => setState(() => _gender = g)),
            const SizedBox(height: RoostSpacing.md),
            _label('Price (₦ per session)'),
            RoostTextField(controller: _price, hint: '42000', keyboardType: TextInputType.number),
            const SizedBox(height: RoostSpacing.md),
            _label('Room size (display text)'),
            RoostTextField(controller: _roomSize, hint: '8–10 per room'),
            const SizedBox(height: RoostSpacing.md),
            _label('Blurb'),
            RoostTextField(controller: _blurb, hint: 'A short description of the block'),
            const SizedBox(height: RoostSpacing.md),
            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Latitude'),
                  RoostTextField(controller: _lat, hint: '5.3865', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                ])),
                const SizedBox(width: RoostSpacing.md),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _label('Longitude'),
                  RoostTextField(controller: _lng, hint: '7.0350', keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true)),
                ])),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: RoostSpacing.md),
              Text(_error!, style: TextStyle(fontSize: 12.5, color: RoostColors.negative)),
            ],
            const SizedBox(height: RoostSpacing.xl),
            RoostButton(
              label: _isEdit ? 'Save changes' : 'Create hostel',
              isLoading: _busy,
              onPressed: _busy ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: RoostSpacing.sm, left: 2),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
      );
}

class _GenderPicker extends StatelessWidget {
  const _GenderPicker({required this.value, required this.onChanged});
  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: RoostSpacing.sm,
      runSpacing: RoostSpacing.sm,
      children: [
        for (final g in Gender.values)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(g),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: RoostSpacing.lg, vertical: 9),
              decoration: ShapeDecoration(
                color: value == g ? RoostColors.accentSubtle : RoostColors.surface1,
                shape: SmoothRectangleBorder(
                  side: BorderSide(color: value == g ? RoostColors.accent : RoostColors.borderDefault, width: value == g ? 1 : 0.5),
                  borderRadius: const SmoothBorderRadius.all(SmoothRadius(cornerRadius: RoostRadius.pill, cornerSmoothing: 1)),
                ),
              ),
              child: Text(g.label,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: value == g ? RoostColors.accent : RoostColors.textSecondary)),
            ),
          ),
      ],
    );
  }
}
