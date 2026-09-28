import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Zámek trenérského režimu PINem (nastaveným při prvním spuštění).
///
/// PIN se chce jednou po spuštění aplikace a znovu po každém přepnutí
/// režimu. Chrání data klientů, když se k počítači / telefonu dostane
/// někdo jiný.
class CoachPinGate extends StatefulWidget {
  final String pin;
  final Widget child;

  const CoachPinGate({super.key, required this.pin, required this.child});

  /// Odemčeno v tomto běhu aplikace.
  static bool unlocked = false;

  /// Zamkne trenérský režim (volá se při změně režimu).
  static void lock() => unlocked = false;

  @override
  State<CoachPinGate> createState() => _CoachPinGateState();
}

class _CoachPinGateState extends State<CoachPinGate> {
  final _ctrl = TextEditingController();
  String? _error;
  int _attempts = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _check() {
    if (_ctrl.text == widget.pin) {
      setState(() => CoachPinGate.unlocked = true);
      return;
    }
    _attempts++;
    setState(() {
      _error = _attempts >= 5
          ? 'Špatný PIN. Zapomněla jsi ho? Odhlas se a přihlas znovu.'
          : 'Špatný PIN';
      _ctrl.clear();
    });
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (CoachPinGate.unlocked || widget.pin.length != 4) return widget.child;
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_outline, size: 56, color: cs.primary),
                const SizedBox(height: 12),
                const Text(
                  'Trenérský režim',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  'Zadej svůj 4místný PIN',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _ctrl,
                  autofocus: true,
                  obscureText: true,
                  maxLength: 4,
                  textAlign: TextAlign.center,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(fontSize: 28, letterSpacing: 12),
                  decoration: InputDecoration(
                    counterText: '',
                    errorText: _error,
                    border: const OutlineInputBorder(),
                  ),
                  onChanged: (v) {
                    if (v.length == 4) _check();
                  },
                  onSubmitted: (_) => _check(),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _signOut,
                  child: const Text('Zapomněla jsem PIN – odhlásit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
