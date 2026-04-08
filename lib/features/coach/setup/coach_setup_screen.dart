import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/coach/coach_auth_provider.dart';
import '../../../providers/coach/coach_setup_provider.dart';

class CoachSetupScreen extends ConsumerStatefulWidget {
  const CoachSetupScreen({super.key});

  @override
  ConsumerState<CoachSetupScreen> createState() => _CoachSetupScreenState();
}

class _CoachSetupScreenState extends ConsumerState<CoachSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  bool _isSaving = false;
  bool _pinObscured = true;
  bool _confirmPinObscured = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _saveSetup() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(coachSetupProvider.notifier).saveSetup(
            firstName: _firstNameController.text,
            securityPin: _pinController.text.trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nastavení trenéra bylo uloženo.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nepodařilo se uložit nastavení: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    try {
      await ref.read(coachAuthControllerProvider.notifier).signOut();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Odhlášení se nepodařilo: $e'),
        ),
      );
    }
  }

  String? validateFirstName(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Zadej své křestní jméno.';
    }
    if (text.length < 2) {
      return 'Jméno je příliš krátké.';
    }
    return null;
  }

  String? validatePin(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Zadej 4místný bezpečnostní kód.';
    }
    if (!RegExp(r'^\d{4}$').hasMatch(text)) {
      return 'Kód musí mít přesně 4 číslice.';
    }
    return null;
  }

  String? validateConfirmPin(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Potvrď bezpečnostní kód.';
    }
    if (text != _pinController.text.trim()) {
      return 'Kódy se neshodují.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final email = FirebaseAuth.instance.currentUser?.email?.trim() ?? '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Nastavení trenéra'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _signOut,
            child: const Text('Odhlásit'),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vítej v aplikaci pro trenéry',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (email.isNotEmpty) ...[
                          Text(
                            'Přihlášený účet: $email',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        Text(
                          'Teď si nastavíme tvoje jméno a bezpečnostní kód pro citlivé akce, například vymazání dat v zařízení.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _firstNameController,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'Křestní jméno',
                            hintText: 'Např. Luděk',
                            border: OutlineInputBorder(),
                          ),
                          validator: validateFirstName,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _pinController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.next,
                          obscureText: _pinObscured,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: 'Bezpečnostní kód',
                            hintText: 'Zadej 4 číslice',
                            border: const OutlineInputBorder(),
                            counterText: '',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _pinObscured = !_pinObscured;
                                });
                              },
                              icon: Icon(
                                _pinObscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: validatePin,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _confirmPinController,
                          keyboardType: TextInputType.number,
                          textInputAction: TextInputAction.done,
                          obscureText: _confirmPinObscured,
                          maxLength: 4,
                          decoration: InputDecoration(
                            labelText: 'Potvrzení kódu',
                            hintText: 'Zadej kód znovu',
                            border: const OutlineInputBorder(),
                            counterText: '',
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _confirmPinObscured =
                                      !_confirmPinObscured;
                                });
                              },
                              icon: Icon(
                                _confirmPinObscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: validateConfirmPin,
                          onFieldSubmitted: (_) {
                            if (!_isSaving) {
                              _saveSetup();
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            color: theme.colorScheme.surfaceContainerHighest,
                          ),
                          child: const Text(
                            'Po uložení budeš v aplikaci vystupovat jako „Trenér {jméno}“ a zadaný kód se bude používat pro potvrzení lokálního resetu zařízení.',
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSaving ? null : _saveSetup,
                            child: _isSaving
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text('Dokončit nastavení'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}