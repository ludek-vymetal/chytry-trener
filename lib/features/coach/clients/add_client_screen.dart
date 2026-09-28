import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/coach/coach_client_details_controller.dart';

class AddClientScreen
    extends ConsumerStatefulWidget {
  const AddClientScreen({
    super.key,
  });

  @override
  ConsumerState<AddClientScreen>
      createState() =>
          _AddClientScreenState();
}

class _AddClientScreenState
    extends ConsumerState<AddClientScreen> {
  final firstNameCtrl =
      TextEditingController();

  final lastNameCtrl =
      TextEditingController();

  final emailCtrl =
      TextEditingController();

  final ageCtrl =
      TextEditingController();

  final heightCtrl =
      TextEditingController();

  final weightCtrl =
      TextEditingController();

  final allergiesCtrl = TextEditingController();
  final intolerancesCtrl = TextEditingController();

  String gender = 'male';

  bool eatingDisorderSupport =
      false;

  bool saving = false;

  @override
  void dispose() {
    firstNameCtrl.dispose();
    lastNameCtrl.dispose();
    emailCtrl.dispose();
    ageCtrl.dispose();
    heightCtrl.dispose();
    weightCtrl.dispose();
    allergiesCtrl.dispose();
    intolerancesCtrl.dispose();

    super.dispose();
  }

  bool get _emailValid {
    final email =
        emailCtrl.text.trim();

    if (email.isEmpty) {
      return true;
    }

    final emailRegex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    return emailRegex.hasMatch(
      email,
    );
  }

  bool get valid {
    return firstNameCtrl.text
            .trim()
            .isNotEmpty &&
        lastNameCtrl.text
            .trim()
            .isNotEmpty &&
        _emailValid &&
        int.tryParse(
              ageCtrl.text.trim(),
            ) !=
            null &&
        int.tryParse(
              heightCtrl.text.trim(),
            ) !=
            null &&
        double.tryParse(
              weightCtrl.text
                  .trim()
                  .replaceAll(',', '.'),
            ) !=
            null;
  }

  Future<void> save() async {
    final l10n =
        AppLocalizations.of(context)!;

    if (!valid || saving) {
      return;
    }

    setState(() {
      saving = true;
    });

    try {
      final newId = await ref
          .read(
            coachClientsControllerProvider
                .notifier,
          )
          .addClientManual(
            firstName:
                firstNameCtrl.text
                    .trim(),

            lastName:
                lastNameCtrl.text
                    .trim(),

            email:
                emailCtrl.text
                    .trim(),

            gender: gender,

            age: int.parse(
              ageCtrl.text.trim(),
            ),

            heightCm: int.parse(
              heightCtrl.text.trim(),
            ),

            weightKg: double.parse(
              weightCtrl.text
                  .trim()
                  .replaceAll(',', '.'),
            ),

            isEatingDisorderSupport:
                eatingDisorderSupport,
          );

      // Alergie hned do karty klienta – jídelníčky je vynechají.
      final allergies = allergiesCtrl.text.trim();
      final intolerances = intolerancesCtrl.text.trim();
      if (allergies.isNotEmpty || intolerances.isNotEmpty) {
        await ref
            .read(coachClientDetailsControllerProvider.notifier)
            .upsertForClient(
              clientId: newId,
              allergies: allergies,
              intolerances: intolerances,
            );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            l10n.failedToSaveClient(
              e.toString(),
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  String _nextClientIdFrom(
    List<CoachClientWithStats>
        clients,
  ) {
    int maxNum = 0;

    for (final c in clients) {
      final id =
          c.client.clientId;

      final n = CoachClientsController.clientIdNumber(id);
      if (n != null && n > maxNum) {
        maxNum = n;
      }
    }

    return 'C${(maxNum + 1).toString().padLeft(4, '0')}-…';
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    final clientsAsync = ref.watch(
      coachClientsControllerProvider,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.newClient,
        ),
      ),

      body: clientsAsync.when(
        loading: () => const Center(
          child:
              CircularProgressIndicator(),
        ),

        error: (e, _) => Center(
          child: Text(
            '${l10n.error}: $e',
          ),
        ),

        data: (clients) {
          final nextId =
              _nextClientIdFrom(
            clients,
          );

          return ListView(
            padding:
                const EdgeInsets.all(
              16,
            ),

            children: [
              Card(
                color: Theme.of(
                  context,
                )
                    .colorScheme
                    .surfaceContainerHighest,

                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  child: Row(
                    children: [
                      const Icon(
                        Icons.badge,
                      ),

                      const SizedBox(
                        width: 12,
                      ),

                      Text(
                        '${l10n.clientId}: $nextId',

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              Text(
                l10n.basicInformation,

                style:
                    const TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              TextField(
                controller:
                    firstNameCtrl,

                decoration:
                    InputDecoration(
                  labelText:
                      l10n.firstName,

                  border:
                      const OutlineInputBorder(),
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    lastNameCtrl,

                decoration:
                    InputDecoration(
                  labelText:
                      l10n.lastName,

                  border:
                      const OutlineInputBorder(),
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    emailCtrl,

                keyboardType:
                    TextInputType
                        .emailAddress,

                decoration:
                    InputDecoration(
                  labelText:
                      l10n.email,

                  hintText:
                      'napr. klient@email.cz',

                  border:
                      const OutlineInputBorder(),

                  errorText:
                      _emailValid
                          ? null
                          : l10n
                              .enterValidEmail,
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(
                height: 12,
              ),

              DropdownButtonFormField<
                  String>(
                initialValue:
                    gender,

                items: [
                  DropdownMenuItem(
                    value: 'male',

                    child: Text(
                      l10n.male,
                    ),
                  ),

                  DropdownMenuItem(
                    value: 'female',

                    child: Text(
                      l10n.female,
                    ),
                  ),

                  DropdownMenuItem(
                    value: 'other',

                    child: Text(
                      l10n.other,
                    ),
                  ),
                ],

                onChanged: (v) {
                  setState(() {
                    gender =
                        v ?? 'male';
                  });
                },

                decoration:
                    InputDecoration(
                  labelText:
                      l10n.gender,

                  border:
                      const OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller: ageCtrl,

                keyboardType:
                    TextInputType
                        .number,

                decoration:
                    InputDecoration(
                  labelText:
                      l10n.age,

                  border:
                      const OutlineInputBorder(),
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    heightCtrl,

                keyboardType:
                    TextInputType
                        .number,

                decoration:
                    InputDecoration(
                  labelText:
                      l10n.heightCm,

                  border:
                      const OutlineInputBorder(),
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(
                height: 12,
              ),

              TextField(
                controller:
                    weightCtrl,

                keyboardType:
                    const TextInputType
                        .numberWithOptions(
                  decimal: true,
                ),

                decoration:
                    InputDecoration(
                  labelText:
                      l10n.weightKg,

                  border:
                      const OutlineInputBorder(),
                ),

                onChanged: (_) {
                  setState(() {});
                },
              ),

              const SizedBox(height: 12),

              TextField(
                controller: allergiesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Alergie (nepovinné)',
                  hintText: 'např. ořechy, ryby, mléko',
                  helperText: 'Jídelníčky tyto potraviny vynechají.',
                  prefixIcon: Icon(Icons.warning_amber_rounded),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: intolerancesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nesnášenlivost (nepovinné)',
                  hintText: 'např. laktóza, lepek',
                  prefixIcon: Icon(Icons.no_food_outlined),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              SwitchListTile(
                title: Text(
                  l10n
                      .recoveryModeSupport,
                ),

                subtitle: Text(
                  l10n
                      .recoveryModeDescription,
                ),

                value:
                    eatingDisorderSupport,

                onChanged: (v) {
                  setState(() {
                    eatingDisorderSupport =
                        v;
                  });
                },
              ),

              const SizedBox(
                height: 18,
              ),

              SizedBox(
                width:
                    double.infinity,

                child:
                    ElevatedButton.icon(
                  icon: const Icon(
                    Icons.save,
                  ),

                  label: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth:
                                2,
                          ),
                        )
                      : Text(
                          l10n
                              .saveClient,
                        ),

                  onPressed:
                      valid && !saving
                          ? save
                          : null,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}