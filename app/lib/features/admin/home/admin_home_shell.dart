import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/theme/brightness_provider.dart';
import '../../../core/theme/tokens.dart';
import '../hostels/admin_hostels_page.dart';
import '../overview/admin_overview_page.dart';
import '../reservations/admin_reservations_page.dart';

/// The signed-in admin home: bottom nav over Overview / Reservations / Hostels
/// — the full-port mobile equivalent of the web dashboard's three pages
/// (Allocation is folded into Reservations as an action, not a 4th tab).
class AdminHomeShell extends ConsumerStatefulWidget {
  const AdminHomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<AdminHomeShell> createState() => _AdminHomeShellState();
}

class _AdminHomeShellState extends ConsumerState<AdminHomeShell> {
  late int _index = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    ref.watch(brightnessProvider);
    return Scaffold(
      backgroundColor: RoostColors.surface0,
      body: IndexedStack(
        index: _index,
        children: const [AdminOverviewPage(), AdminReservationsPage(), AdminHostelsPage()],
      ),
      bottomNavigationBar: _NavBar(index: _index, onChanged: (i) => setState(() => _index = i)),
    );
  }
}

class _NavBar extends StatelessWidget {
  const _NavBar({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final items = [
      (PhosphorIcons.chartBar(), 'Overview'),
      (PhosphorIcons.clipboardText(), 'Reservations'),
      (PhosphorIcons.buildings(), 'Hostels'),
    ];
    return Container(
      decoration: BoxDecoration(
        color: RoostColors.surface1,
        border: Border(top: BorderSide(color: RoostColors.borderSubtle, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onChanged(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(items[i].$1, size: 24,
                            color: i == index ? RoostColors.accent : RoostColors.textTertiary),
                        const SizedBox(height: 4),
                        Text(items[i].$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: i == index ? FontWeight.w700 : FontWeight.w500,
                              color: i == index ? RoostColors.accent : RoostColors.textTertiary,
                            )),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
