import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/coach/coach_auth_provider.dart';
import '../../../providers/coach/coach_setup_provider.dart';

class CoachSetupScreen extends ConsumerStatefulWidget {
  const CoachSetupScreen({super.key});

  @override
  ConsumerState<CoachSetupScreen> createState() =>
      _CoachSetupScreenState();
}

class _CoachSetupScreenState
    extends ConsumerState<CoachSetupScreen> {
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

  Future<String> _getIosClientsFolderPath() async {
    final appDir = await getApplicationDocumentsDirectory();

    final dir = Directory(
      p.join(appDir.path, 'Klienti'),
    );

    if (!dir.existsSync()) {
      await dir.create(recursive: true);
    }

    return dir.path;
  }

  Future<void> _pickExportFolder() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      String selectedPath;

      if (Platform.isIOS) {
        selectedPath =
            await _getIosClientsFolderPath();
      } else {
        final pickedPath = await getDirectoryPath(
          confirmButtonText: l10n.selectFolder,
        );

        if (pickedPath == null ||
            pickedPath.trim().isEmpty) {
          return;
        }

        final dir = Directory(pickedPath);

        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }

        selectedPath = pickedPath.trim();
      }

      if (!mounted) return;

      setState(() {
        _exportFolderController.text =
            selectedPath;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isIOS
                ? l10n.iosFolderInfo
                : l10n.exportFolderSaved,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.folderPickFailed(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  Future<void>
      _fillSuggestedDocumentsFolder() async {
    final l10n = AppLocalizations.of(context)!;

    try {
      String suggested;

      if (Platform.isIOS) {
        suggested =
            await _getIosClientsFolderPath();
      } else {
        final home =
            Platform.environment['USERPROFILE'] ??
                Platform.environment['HOME'] ??
                '';

        if (home.trim().isEmpty) return;

        suggested = p.join(
          home,
          'Documents',
          'Klienti',
        );

        final dir = Directory(suggested);

        if (!dir.existsSync()) {
          await dir.create(recursive: true);
        }
      }

      if (!mounted) return;

      setState(() {
        _exportFolderController.text =
            suggested;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            Platform.isIOS
                ? l10n.iosFolderInfo
                : l10n.customExportFolderRemoved,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.error}: $e',
          ),
        ),
      );
    }
  }

  Future<void> _saveSetup() async {
    final l10n = AppLocalizations.of(context)!;

    if (!(_formKey.currentState?.validate() ??
        false)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref
          .read(coachSetupProvider.notifier)
          .saveSetup(
            firstName:
                _firstNameController.text,
            securityPin:
                _pinController.text.trim(),
            exportFolderPath:
                _exportFolderController.text
                    .trim(),
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.coachSetupSaved,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n.error}: $e',
          ),
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
    final l10n = AppLocalizations.of(context)!;

    try {
      await ref
          .read(
            coachAuthControllerProvider
                .notifier,
          )
          .signOut();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.signOutFailed(
              e.toString(),
            ),
          ),
        ),
      );
    }
  }

  String? validateFirstName(
    BuildContext context,
    String? value,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return l10n.enterFirstName;
    }

    if (text.length < 2) {
      return l10n.firstNameTooShort;
    }

    return null;
  }

  String? validatePin(
    BuildContext context,
    String? value,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return l10n.enterSecurityPin;
    }

    if (!RegExp(r'^\d{4}$')
        .hasMatch(text)) {
      return l10n.pinMustHave4Digits;
    }

    return null;
  }

  String? validateConfirmPin(
    BuildContext context,
    String? value,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return l10n.confirmSecurityPin;
    }

    if (text !=
        _pinController.text.trim()) {
      return l10n.passwordsDoNotMatch;
    }

    return null;
  }

  String? validateExportFolder(
    BuildContext context,
    String? value,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return l10n
          .selectClientArchiveFolder;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final l10n =
        AppLocalizations.of(context)!;

    final email = FirebaseAuth
            .instance.currentUser?.email
            ?.trim() ??
        '';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l10n.coachSetup),
        actions: [
          TextButton(
            onPressed:
                _isSaving ? null : _signOut,
            child: Text(
              l10n.logoutCoach,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 640,
            ),
            child: SingleChildScrollView(
              padding:
                  const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    20,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          l10n.welcomeCoachApp,
                          style: theme
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight:
                                FontWeight
                                    .bold,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        if (email
                            .isNotEmpty) ...[
                          Text(
                            '${l10n.loggedAccount}: $email',
                            style: theme
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                              fontWeight:
                                  FontWeight
                                      .w600,
                            ),
                          ),
                          const SizedBox(
                            height: 12,
                          ),
                        ],
                        Text(
                          Platform.isIOS
                              ? l10n
                                  .coachSetupIosDescription
                              : l10n
                                  .coachSetupDesktopDescription,
                          style: theme
                              .textTheme
                              .bodyLarge,
                        ),
                        const SizedBox(
                          height: 24,
                        ),
                        TextFormField(
                          controller:
                              _firstNameController,
                          textInputAction:
                              TextInputAction
                                  .next,
                          decoration:
                              InputDecoration(
                            labelText:
                                l10n
                                    .firstName,
                            hintText:
                                l10n
                                    .firstNameExample,
                            border:
                                const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              validateFirstName(
                            context,
                            value,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                              _pinController,
                          keyboardType:
                              TextInputType
                                  .number,
                          textInputAction:
                              TextInputAction
                                  .next,
                          obscureText:
                              _pinObscured,
                          maxLength: 4,
                          decoration:
                              InputDecoration(
                            labelText:
                                l10n
                                    .securityPin,
                            hintText:
                                l10n
                                    .enter4DigitPin,
                            border:
                                const OutlineInputBorder(),
                            counterText:
                                '',
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  _pinObscured =
                                      !_pinObscured;
                                });
                              },
                              icon: Icon(
                                _pinObscured
                                    ? Icons
                                        .visibility_off
                                    : Icons
                                        .visibility,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              validatePin(
                            context,
                            value,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                              _confirmPinController,
                          keyboardType:
                              TextInputType
                                  .number,
                          textInputAction:
                              TextInputAction
                                  .next,
                          obscureText:
                              _confirmPinObscured,
                          maxLength: 4,
                          decoration:
                              InputDecoration(
                            labelText:
                                l10n
                                    .confirmPin,
                            hintText:
                                l10n
                                    .enterPinAgain,
                            border:
                                const OutlineInputBorder(),
                            counterText:
                                '',
                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  _confirmPinObscured =
                                      !_confirmPinObscured;
                                });
                              },
                              icon: Icon(
                                _confirmPinObscured
                                    ? Icons
                                        .visibility_off
                                    : Icons
                                        .visibility,
                              ),
                            ),
                          ),
                          validator: (value) =>
                              validateConfirmPin(
                            context,
                            value,
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        TextFormField(
                          controller:
                              _exportFolderController,
                          readOnly: true,
                          decoration:
                              InputDecoration(
                            labelText:
                                l10n
                                    .exportClientFolder,
                            hintText:
                                l10n
                                    .selectClientArchiveFolder,
                            border:
                                const OutlineInputBorder(),
                          ),
                          validator: (value) =>
                              validateExportFolder(
                            context,
                            value,
                          ),
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            OutlinedButton.icon(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : _pickExportFolder,
                              icon: const Icon(
                                Icons
                                    .folder_open,
                              ),
                              label: Text(
                                Platform.isIOS
                                    ? l10n
                                        .useAppFolder
                                    : l10n
                                        .selectCustomFolder,
                              ),
                            ),
                            TextButton.icon(
                              onPressed:
                                  _isSaving
                                      ? null
                                      : _fillSuggestedDocumentsFolder,
                              icon: const Icon(
                                Icons.folder,
                              ),
                              label: Text(
                                Platform.isIOS
                                    ? l10n
                                        .useClientsFolder
                                    : l10n
                                        .useDocumentsClients,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(14),
                          decoration:
                              BoxDecoration(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                            color: theme
                                .colorScheme
                                .surfaceContainerHighest,
                          ),
                          child: Text(
                            Platform.isIOS
                                ? l10n
                                    .iosFolderInfo
                                : l10n
                                    .desktopFolderRecommendation,
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        SizedBox(
                          width:
                              double.infinity,
                          child: FilledButton(
                            onPressed:
                                _isSaving
                                    ? null
                                    : _saveSetup,
                            child: _isSaving
                                ? const SizedBox(
                                    width:
                                        22,
                                    height:
                                        22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.4,
                                    ),
                                  )
                                : Text(
                                    l10n
                                        .finishSetup,
                                  ),
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