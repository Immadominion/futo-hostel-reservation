import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../../core/session/admin_session_controller.dart';
import '../../../core/theme/brightness_provider.dart';
import '../../../core/theme/squircle_button.dart';
import '../../../core/theme/surface_card.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/roost_input.dart';

/// Admin sign-in. No self-registration (admins are provisioned, not
/// self-signed-up) and no biometric (desk-bound office use, per
/// REQUIREMENTS.md — FR3 biometric is student-only).
class AdminLoginPage extends ConsumerStatefulWidget {
  const AdminLoginPage({super.key});

  @override
  ConsumerState<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends ConsumerState<AdminLoginPage> {
  final _email = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _email.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address.');
      return;
    }
    if (_pw.text.length < 8) {
      setState(() => _error = 'Password must be at least 8 characters.');
      return;
    }
    setState(() {
      _error = null;
      _busy = true;
    });
    final err = await ref.read(adminSessionProvider.notifier).signIn(email: email, password: _pw.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      context.go('/home');
    } else {
      setState(() => _error = err);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(brightnessProvider);
    return Scaffold(
      backgroundColor: RoostColors.surface0,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(RoostSpacing.xxl, 0, RoostSpacing.xxl, RoostSpacing.xxl),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 48,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                _Wordmark(),
                const SizedBox(height: RoostSpacing.sm),
                Text('Hostel Officer Admin',
                    style: TextStyle(fontSize: 16, color: RoostColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Occupancy, reservations, and allocation — from your phone.',
                    style: TextStyle(fontSize: 14, color: RoostColors.textTertiary, height: 1.4)),
                const SizedBox(height: RoostSpacing.xxxl),
                RoostSurfaceCard(
                  floating: true,
                  padding: const EdgeInsets.all(RoostSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Email'),
                      RoostTextField(
                        controller: _email,
                        hint: 'admin@futohostel.com',
                        icon: PhosphorIcons.envelopeSimple(),
                        keyboardType: TextInputType.emailAddress,
                        action: TextInputAction.next,
                      ),
                      const SizedBox(height: RoostSpacing.lg),
                      _label('Password'),
                      RoostTextField(
                        controller: _pw,
                        hint: '••••••••',
                        icon: PhosphorIcons.lockSimple(),
                        obscure: _obscure,
                        action: TextInputAction.done,
                        onSubmitted: (_) => _signIn(),
                        suffix: GestureDetector(
                          onTap: () => setState(() => _obscure = !_obscure),
                          child: Icon(_obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
                              size: 20, color: RoostColors.textTertiary),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: RoostSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(PhosphorIcons.warningCircle(), size: 16, color: RoostColors.negative),
                            const SizedBox(width: 6),
                            Expanded(child: Text(_error!, style: TextStyle(fontSize: 12.5, color: RoostColors.negative, height: 1.3))),
                          ],
                        ),
                      ],
                      const SizedBox(height: RoostSpacing.xl),
                      RoostButton(
                        label: 'Sign in',
                        isLoading: _busy,
                        onPressed: _busy ? null : _signIn,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RoostSpacing.xxxl),
                Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.shieldCheck(), size: 16, color: RoostColors.textTertiary),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text('Student Affairs Unit — FUTO',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 12, color: RoostColors.textTertiary, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: RoostSpacing.sm, left: 2),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: RoostColors.textSecondary)),
      );
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 40, fontWeight: FontWeight.w800, letterSpacing: -1.2),
        children: [
          TextSpan(text: 'Roost', style: TextStyle(color: RoostColors.textPrimary)),
          TextSpan(text: ' Admin', style: TextStyle(color: RoostColors.accent)),
        ],
      ),
    );
  }
}
