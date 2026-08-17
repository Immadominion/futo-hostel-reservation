import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../../core/session/session_controller.dart';
import '../../core/theme/brightness_provider.dart';
import '../../core/theme/squircle_button.dart';
import '../../core/theme/surface_card.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/roost_input.dart';
import '../../core/widgets/wavy_sheet.dart';

/// Login. Sign in with reg-number or school email + password (FR1), with a
/// Face ID / fingerprint option (FR3) and a create-account sheet (FR2).
class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

final _regNoRe = RegExp(r'^\d{11}$');
final _emailRe = RegExp(r'^[a-z]+\.[a-z]+\.\d{11}@futo\.edu\.ng$', caseSensitive: false);
bool validIdentifier(String s) => _regNoRe.hasMatch(s.trim()) || _emailRe.hasMatch(s.trim());
bool validPassword(String s) => s.length >= 8 && RegExp(r'[A-Za-z]').hasMatch(s) && RegExp(r'\d').hasMatch(s);

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  bool _obscure = true;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final id = _id.text.trim();
    if (!validIdentifier(id)) {
      setState(() => _error = 'Enter your reg number (e.g. 20211234567) or school email.');
      return;
    }
    if (!validPassword(_pw.text)) {
      setState(() => _error = 'Password must be at least 8 characters with a letter and a number.');
      return;
    }
    await _authenticate(id, _pw.text, register: false);
  }

  /// Sign in (or register) via the session controller, then bootstrap + navigate.
  /// In demo mode this returns instantly; live mode may pause on a cold backend.
  Future<void> _authenticate(String identifier, String password, {required bool register}) async {
    setState(() {
      _error = null;
      _busy = true;
    });
    final err = await ref
        .read(sessionProvider.notifier)
        .signIn(identifier: identifier, password: password, register: register);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err == null) {
      context.go('/home');
    } else {
      setState(() => _error = err);
    }
  }

  Future<void> _biometric() async {
    final auth = LocalAuthentication();
    try {
      final supported = await auth.isDeviceSupported();
      final canCheck = await auth.canCheckBiometrics;
      final ok = (supported || canCheck)
          ? await auth.authenticate(
              localizedReason: 'Unlock Roost to view your hostel',
              options: const AuthenticationOptions(stickyAuth: true),
            )
          : true; // fallback on devices/web without biometrics
      if (!ok || !mounted) return;
      setState(() {
        _error = null;
        _busy = true;
      });
      final restored = await ref.read(sessionProvider.notifier).restoreSession();
      if (!mounted) return;
      setState(() => _busy = false);
      if (restored) {
        context.go('/home');
      } else {
        setState(() => _error =
            'Sign in with your password once — then Face ID / fingerprint unlocks next time.');
      }
    } catch (_) {
      if (mounted) setState(() => _busy = false);
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
            constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.vertical - 48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 56),
                _Wordmark(),
                const SizedBox(height: RoostSpacing.sm),
                Text('FUTO Hostel Reservation',
                    style: TextStyle(fontSize: 16, color: RoostColors.textSecondary, fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text('Find a bed, pay, and get your allocation — from your phone.',
                    style: TextStyle(fontSize: 14, color: RoostColors.textTertiary, height: 1.4)),
                const SizedBox(height: RoostSpacing.xxxl),
                RoostSurfaceCard(
                  floating: true,
                  padding: const EdgeInsets.all(RoostSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label('Reg number or school email'),
                      RoostTextField(
                        controller: _id,
                        hint: '20211234567',
                        icon: PhosphorIcons.identificationCard(),
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
                      const SizedBox(height: RoostSpacing.md),
                      RoostButton(
                        label: 'Use Face ID / Fingerprint',
                        variant: RoostButtonVariant.secondary,
                        icon: PhosphorIcons.fingerprint(),
                        onPressed: _busy ? null : _biometric,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: RoostSpacing.xl),
                Center(
                  child: GestureDetector(
                    onTap: _openSignUp,
                    behavior: HitTestBehavior.opaque,
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 14, color: RoostColors.textSecondary, fontFamily: 'Montserrat'),
                        children: [
                          const TextSpan(text: 'New here?  '),
                          TextSpan(text: 'Create account',
                              style: TextStyle(color: RoostColors.accent, fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
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
                        child: Text('Secured for FUTO students',
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

  void _openSignUp() {
    showRoostWavySheet(
      context: context,
      headerHeight: 150,
      header: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(PhosphorIcons.userPlus(), size: 30, color: RoostColors.onAccent),
          const SizedBox(height: RoostSpacing.sm),
          Text('Create account', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: RoostColors.onAccent)),
        ],
      ),
      child: _SignUpForm(
        onSubmit: (identifier, password) {
          Navigator.of(context).pop();
          _authenticate(identifier, password, register: true);
        },
      ),
    );
  }
}

/// The create-account form. Its own stateful widget so each password field has an
/// independent show/hide toggle, and it scrolls so the focused field lifts above
/// the keyboard (the sheet itself is keyboard-aware — see [showRoostWavySheet]).
class _SignUpForm extends StatefulWidget {
  const _SignUpForm({required this.onSubmit});
  final void Function(String identifier, String password) onSubmit;

  @override
  State<_SignUpForm> createState() => _SignUpFormState();
}

class _SignUpFormState extends State<_SignUpForm> {
  final _id = TextEditingController();
  final _pw = TextEditingController();
  final _confirm = TextEditingController();
  bool _pwObscure = true;
  bool _confirmObscure = true;
  String? _error;

  @override
  void dispose() {
    _id.dispose();
    _pw.dispose();
    _confirm.dispose();
    super.dispose();
  }

  void _submit() {
    if (!validIdentifier(_id.text.trim())) {
      setState(() => _error = 'Enter a valid reg number or school email.');
      return;
    }
    if (!validPassword(_pw.text)) {
      setState(() => _error = 'Password needs 8+ characters with a letter and a number.');
      return;
    }
    if (_pw.text != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    widget.onSubmit(_id.text.trim(), _pw.text);
  }

  Widget _eye(bool obscure, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Icon(obscure ? PhosphorIcons.eye() : PhosphorIcons.eyeSlash(),
            size: 20, color: RoostColors.textTertiary),
      );

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(RoostSpacing.xl, RoostSpacing.lg, RoostSpacing.xl, RoostSpacing.xxl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RoostTextField(
            controller: _id,
            hint: 'Reg number or school email',
            icon: PhosphorIcons.identificationCard(),
            keyboardType: TextInputType.emailAddress,
            action: TextInputAction.next,
          ),
          const SizedBox(height: RoostSpacing.md),
          RoostTextField(
            controller: _pw,
            hint: 'Password (8+ chars, a letter & a number)',
            icon: PhosphorIcons.lockSimple(),
            obscure: _pwObscure,
            action: TextInputAction.next,
            suffix: _eye(_pwObscure, () => setState(() => _pwObscure = !_pwObscure)),
          ),
          const SizedBox(height: RoostSpacing.md),
          RoostTextField(
            controller: _confirm,
            hint: 'Confirm password',
            icon: PhosphorIcons.lockSimple(),
            obscure: _confirmObscure,
            action: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            suffix: _eye(_confirmObscure, () => setState(() => _confirmObscure = !_confirmObscure)),
          ),
          if (_error != null) ...[
            const SizedBox(height: RoostSpacing.md),
            Text(_error!, style: TextStyle(fontSize: 12.5, color: RoostColors.negative, height: 1.3)),
          ],
          const SizedBox(height: RoostSpacing.xl),
          RoostButton(label: 'Create account', onPressed: _submit),
        ],
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(fontFamily: 'Montserrat', fontSize: 48, fontWeight: FontWeight.w800, letterSpacing: -1.5),
        children: [
          TextSpan(text: 'Roost', style: TextStyle(color: RoostColors.textPrimary)),
          TextSpan(text: '.', style: TextStyle(color: RoostColors.accent)),
        ],
      ),
    );
  }
}
