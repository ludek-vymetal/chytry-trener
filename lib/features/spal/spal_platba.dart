import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'spal_service.dart';
import 'spal_styl.dart';

/// Online platba GoPay: připraví nákup (cenu spočítá server), otevře platební bránu
/// a počká, až GoPay potvrdí zaplacení. Vrací true, když je zaplaceno.
Future<bool> spalZaplatit(BuildContext context, WidgetRef ref, Map<String, dynamic> nakup) async {
  final messenger = ScaffoldMessenger.of(context);
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator(color: spalZluta)),
  );
  ({int id, String url, bool testovaci})? platba;
  try {
    platba = await SpalService.zalozitPlatbu(nakup);
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text(SpalService.chyba(e))));
  } finally {
    if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
  }
  final pl = platba;
  if (pl == null || !context.mounted) return false;

  final otevreno = await launchUrl(Uri.parse(pl.url), mode: LaunchMode.externalApplication);
  if (!otevreno) {
    messenger.showSnackBar(const SnackBar(content: Text('Nepodařilo se otevřít platební bránu')));
    return false;
  }
  if (!context.mounted) return false;

  final stav = await showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CekaniNaPlatbu(id: pl.id, testovaci: pl.testovaci),
  );
  if (stav == 'zaplacena') {
    spalObnovit(ref);
    messenger.showSnackBar(const SnackBar(content: Text('Zaplaceno, děkujeme! Najdeš to v Můj účet.')));
    return true;
  }
  if (stav == 'zrusena') {
    messenger.showSnackBar(const SnackBar(content: Text('Platba byla zrušena.')));
  }
  return false;
}

class _CekaniNaPlatbu extends StatefulWidget {
  const _CekaniNaPlatbu({required this.id, required this.testovaci});
  final int id;
  final bool testovaci;
  @override
  State<_CekaniNaPlatbu> createState() => _CekaniNaPlatbuState();
}

class _CekaniNaPlatbuState extends State<_CekaniNaPlatbu> with WidgetsBindingObserver {
  Timer? _casovac;
  final _start = DateTime.now();
  bool _ptam = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _casovac = Timer.periodic(const Duration(seconds: 3), (_) => _zkontrolovat());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _zkontrolovat(); // návrat z brány
  }

  Future<void> _zkontrolovat() async {
    if (_ptam || !mounted) return;
    _ptam = true;
    try {
      final s = await SpalService.stavPlatby(widget.id);
      if (!mounted) return;
      if (s == 'zaplacena' || s == 'zrusena') {
        Navigator.pop(context, s);
      } else if (DateTime.now().difference(_start) > const Duration(minutes: 20)) {
        Navigator.pop(context, 'nova');
      }
    } catch (_) {
      // bez internetu – zkusíme znovu
    } finally {
      _ptam = false;
    }
  }

  @override
  void dispose() {
    _casovac?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('Čekám na zaplacení…'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const LinearProgressIndicator(color: spalZluta),
          const SizedBox(height: 16),
          const Text('Dokonči platbu v prohlížeči a vrať se sem. Jakmile GoPay platbu potvrdí, '
              'nákup se ti sám zobrazí v Můj účet.'),
          if (widget.testovaci) ...[
            const SizedBox(height: 12),
            const Text('TESTOVACÍ PLATBA – žádné peníze se nestrhnou.',
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
          ],
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, 'nova'),
            child: const Text('Zavřít'),
          ),
        ],
      );
}
