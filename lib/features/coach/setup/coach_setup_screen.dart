import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

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
  final _exportFolderController = TextEditingController();

  bool _isSaving = false;
  bool _pinObscured = true;
  bool _confirmPinObscured = true;

  @override
  void dispose() {
    _firstNameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    _exportFolderController.dispose();
    super.dispose();
  }

  Future<void> _pickExportFolder() async {
    try {
      final selectedPath = await getDirectoryPath(
        confirmButtonText: 'Vybrat složku',
      );

      if (selectedPath == null || selectedPath.trim().isEmpty) return;

      final dir = Directory(selectedPath);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      if (!mounted) return;

      setState(() {
        _exportFolderController.text = selectedPath.trim();
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Výběr složky selhal: $e'),
        ),
      );
    }
  }

  Future<void> _fillSuggestedDocumentsFolder() async {
    try {
      final home = Platform.environment['USERPROFILE'] ??
          Platform.environment['HOME'] ??
          '';
      if (home.trim().isEmpty) return;

      final suggested = p.join(home, 'Documents', 'Klienti');

      final dir = Directory(suggested);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      if (!mounted) return;

      setState(() {
        _exportFolderController.text = suggested;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nepodařilo se připravit složku Dokumenty/Klienti: $e'),
        ),
      );
    }
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
            exportFolderPath: _exportFolderController.text.trim(),
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

  String? validateExportFolder(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Vyber exportní složku pro archiv klientů.';
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
            constraints: const BoxConstraints(maxWidth: 640),
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
                          'Teď si nastavíme tvoje jméno, bezpečnostní kód a hlavně složku, kam se budou ukládat archivy klientů.',
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
                          textInputAction: TextInputAction.next,
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
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _exportFolderController,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Exportní složka klientů',
                            hintText: 'Vyber složku pro archiv klientů',
                            border: OutlineInputBorder(),
                          ),
                          validator: validateExportFolder,
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _isSaving ? null : _pickExportFolder,
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Vybrat vlastní složku'),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _isSaving ? null : _fillSuggestedDocumentsFolder,
                              icon: const Icon(Icons.folder),
                              label: const Text('Použít Dokumenty/Klienti'),
                            ),
                          ],
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
                            'Doporučení: vyber si vlastní archivní složku, ideálně v Google Drive nebo OneDrive synchronizované složce. Pak budeš mít klientské archivy dostupné i mimo tento počítač.',
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