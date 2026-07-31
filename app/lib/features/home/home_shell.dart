import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/theme/tokens.dart';
import '../../core/theme/brightness_provider.dart';
import '../browse/browse_page.dart';
import '../profile/profile_page.dart';
import '../reservations/reservations_page.dart';

/// The signed-in home: a bottom nav over Browse / Reservations / Profile.
/// Detail + reserve screens are pushed on top of this shell.
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, this.initialTab = 0});
  final int initialTab;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  late int _index = widget.initialTab;

  @override
  Widget build(BuildContext context) {
    ref.watch(brightnessProvider);
    return Scaffold(
      backgroundColor: RoostColors.surface0,
      body: IndexedStack(
        index: _index,
        children: const [BrowsePage(), ReservationsPage(), ProfilePage()],
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
      (PhosphorIcons.buildings(), 'Browse'),
      (PhosphorIcons.ticket(), 'Bookings'),
      (PhosphorIcons.user(), 'Profile'),
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
