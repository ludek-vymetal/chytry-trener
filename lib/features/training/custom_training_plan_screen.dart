import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/nutrition/hollywood_prep.dart';
import '../../models/goal.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../core/training/exercises/exercise.dart';
import '../../core/training/exercises/exercise_db.dart';
import '../../models/custom_training_plan.dart';
import '../../models/shared_training_template.dart';
import '../../providers/coach/active_client_provider.dart';
import '../../providers/coach/custom_training_plan_provider.dart';
import '../../providers/shared_training_templates_provider.dart';
import 'training_plan_screen.dart';
import '../paywall/paywall_screen.dart';
import '../../providers/subscription/subscription_provider.dart';
import '../../services/pdf/training_plan_pdf_service.dart';
import '../../core/training/library/program_library.dart';

part 'custom_plan_prep_programs.dart';
part 'custom_plan_glute_bench.dart';
part 'custom_plan_classic_programs.dart';
part 'custom_plan_detail_screen.dart';

class CustomTrainingPlanScreen extends ConsumerWidget {
  const CustomTrainingPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final activeClientAsync = ref.watch(activeClientIdProvider);
    final allPlans = ref.watch(customTrainingPlanProvider);
    final sharedTemplates = ref.watch(sharedTrainingTemplatesProvider);

    return activeClientAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          title: Text(l10n.customTraining),
        ),
        body: Center(
          child: Text('${l10n.error}: $e'),
        ),
      ),
      data: (clientId) {
        if (clientId == null || clientId.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: Text(l10n.customTraining),
            ),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.selectActiveClientFirst,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final clientPlans =
            allPlans.where((p) => p.clientId == clientId).toList();

        final groupedTemplates =
            _groupTemplatesByCategory(sharedTemplates);

        final groupedPlans =
            _groupPlansByCategory(clientPlans);

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.customTraining),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                _createPlanDialog(context, ref, clientId),
            icon: const Icon(Icons.add),
            label: Text(l10n.newPlan),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _ProgramCatalogScreen(clientId: clientId),
                  ),
                ),
                icon: const Icon(Icons.auto_awesome),
                label: Text(l10n.programsButton),
              ),

              const SizedBox(height: 24),

              Text(
                l10n.sharedTemplates,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 10),

              if (sharedTemplates.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noSharedTemplatesYet,
                    ),
                  ),
                )
              else
                ...groupedTemplates.entries.map(
                  (entry) => _TemplateCategorySection(
                    category: entry.key,
                    templates: entry.value,
                    clientId: clientId,
                  ),
                ),

              const SizedBox(height: 24),

              Text(
                l10n.clientPlans,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),

              const SizedBox(height: 10),

              if (clientPlans.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      l10n.noCustomPlanYet,
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...groupedPlans.entries.map(
                  (entry) => _PlanCategorySection(
                    category: entry.key,
                    plans: entry.value,
                  ),
                ),

              const SizedBox(height: 80),
            ],
          ),
        );
      },
    );
  }
}

  Map<CustomTrainingCategory, List<SharedTrainingTemplate>>
      _groupTemplatesByCategory(List<SharedTrainingTemplate> templates) {
    final map = <CustomTrainingCategory, List<SharedTrainingTemplate>>{};

    for (final template in templates) {
      map.putIfAbsent(template.category, () => []);
      map[template.category]!.add(template);
    }

    return map;
  }

  Map<CustomTrainingCategory, List<CustomTrainingPlan>> _groupPlansByCategory(
    List<CustomTrainingPlan> plans,
  ) {
    final map = <CustomTrainingCategory, List<CustomTrainingPlan>>{};

    for (final plan in plans) {
      map.putIfAbsent(plan.category, () => []);
      map[plan.category]!.add(plan);
    }

    return map;
  }

  Future<void> _createPlanDialog(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final nameCtrl = TextEditingController();
    final descriptionCtrl = TextEditingController();
    CustomTrainingCategory selectedCategory = CustomTrainingCategory.custom;

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.newPlan),
          content: SingleChildScrollView(
            child: Column(
              children: [
                DropdownButtonFormField<CustomTrainingCategory>(
                  initialValue: selectedCategory,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.category,
                  ),
                  items: CustomTrainingCategory.values.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(_categoryLabel(context, category)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      selectedCategory = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.planName,
                    hintText: l10n.planNameHint,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionCtrl,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(),
                    labelText: l10n.planDescription,
                    hintText: l10n.planDescriptionHint,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.create),
            ),
          ],
        ),
      ),
    );

    if (ok == true && nameCtrl.text.trim().isNotEmpty) {
      await ref.read(customTrainingPlanProvider.notifier).createPlan(
            clientId: clientId,
            name: nameCtrl.text.trim(),
            description: descriptionCtrl.text.trim().isEmpty
                ? null
                : descriptionCtrl.text.trim(),
            category: selectedCategory,
          );
    }
  }

  Future<void> _insertConstantinCutPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      '90denní vyrýsování',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description: 'Shazovací plán zaměřený na spalování tuku a kondici.',
          category: CustomTrainingCategory.cut,
          type: CustomTrainingPlanType.cut90,
        );

    final updatedPlans = ref.read(customTrainingPlanProvider);
    CustomTrainingPlan? createdPlan;

    for (final plan in updatedPlans.reversed) {
      if (plan.clientId == clientId && plan.name == newName) {
        createdPlan = plan;
        break;
      }
    }

    if (createdPlan == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.planInserted),
        ),
      );
      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    final templateDays = _constantinPlanDays();

    for (final day in templateDays) {
      await notifier.addDay(
        planId: createdPlan.id,
        dayName: day.name,
      );
    }

    for (int dayIndex = 0; dayIndex < templateDays.length; dayIndex++) {
      final day = templateDays[dayIndex];
      for (final exercise in day.exercises) {
        await notifier.addExerciseToDay(
          planId: createdPlan.id,
          dayIndex: dayIndex,
          exercise: exercise,
        );
      }
    }

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plán "$newName" byl vložen mezi vlastní tréninky.'),
      ),
    );
  }

  Future<void> _insertPowerliftingMeetPrepPlan(
    BuildContext context,
    WidgetRef ref,
    String clientId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final maxes = await showDialog<_PowerliftingMaxes>(
      context: context,
      builder: (_) => const _PowerliftingMaxesDialog(),
    );

    if (maxes == null) return;

    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      'Příprava na závody – silový trojboj',
      plans.where((p) => p.clientId == clientId).toList(),
    );

    await ref.read(customTrainingPlanProvider.notifier).createPlan(
          clientId: clientId,
          name: newName,
          description:
              'Silový plán pro přípravu na závody v trojboji podle zadaných maximálek.',
          category: CustomTrainingCategory.powerlifting,
          type: CustomTrainingPlanType.powerliftingMeetPrep,
          meetDate: maxes.meetDate,
          maxes: CustomTrainingMaxes(
            squat1rm: maxes.squat1rm,
            bench1rm: maxes.bench1rm,
            deadlift1rm: maxes.deadlift1rm,
          ),
        );

    final updatedPlans = ref.read(customTrainingPlanProvider);
    CustomTrainingPlan? createdPlan;

    for (final plan in updatedPlans.reversed) {
      if (plan.clientId == clientId && plan.name == newName) {
        createdPlan = plan;
        break;
      }
    }

    if (createdPlan == null) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.planCreationFailed,
          ),
        ),
      );

      return;
    }

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    if (!context.mounted) return;
    final templateDays = _powerliftingMeetPrepDays(context, maxes);

    for (final day in templateDays) {
      await notifier.addDay(
        planId: createdPlan.id,
        dayName: day.name,
      );
    }

    for (int dayIndex = 0; dayIndex < templateDays.length; dayIndex++) {
      final day = templateDays[dayIndex];
      for (final exercise in day.exercises) {
        await notifier.addExerciseToDay(
          planId: createdPlan.id,
          dayIndex: dayIndex,
          exercise: exercise,
        );
      }
    }

    // Program = trénink i jídelníček: jídelníček se nastaví klientovi
    // automaticky (stejné datum a stejné fáze).
    final dietSet = await _applyProgramDiet(
      ref,
      clientId,
      (p) => p.copyWith(selectedPlan: StrengthPlan.planKey),
      restrictive: false,
    );

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Plán "$newName" byl vložen mezi vlastní tréninky.'
          '${dietSet ? '\nJídelníček nastaven: ${StrengthPlan.name}.' : ''}',
        ),
      ),
    );
  }

  /// Nastaví klientovi jídelníček programu (Hollywood, Bikini, Kulatý
  /// zadek, Silová příprava). Vrací `true`, když se nastavil.
  ///
  /// Jen když je načtený profil právě tohoto klienta. Přísné programy
  /// ([restrictive]) se nenastaví klientům s podporou při poruše příjmu
  /// potravy.
  Future<bool> _applyProgramDiet(
    WidgetRef ref,
    String clientId,
    UserProfile Function(UserProfile profile) update, {
    required bool restrictive,
  }) async {
    final profile = ref.read(userProfileProvider);
    if (profile == null || profile.clientId != clientId) return false;
    if (restrictive &&
        profile.goal?.reason == GoalReason.eatingDisorderSupport) {
      return false;
    }
    await ref.read(userProfileProvider.notifier).updateProfile(update(profile));
    return true;
  }

  /// Vloží hotový program z knihovny (kulturistika, běh, testy…)
  /// jako nový tréninkový plán klienta.
  Future<void> _insertLibraryProgram(
    BuildContext context,
    WidgetRef ref,
    String clientId,
    LibraryProgram program,
  ) async {
    final plans = ref.read(customTrainingPlanProvider);
    final newName = _buildUniquePlanName(
      program.title,
      plans.where((p) => p.clientId == clientId).toList(),
    );

    final notifier = ref.read(customTrainingPlanProvider.notifier);
    await notifier.createPlan(
      clientId: clientId,
      name: newName,
      description: '${program.description}\n${program.length} · ${program.level}',
      category: program.category,
    );

    CustomTrainingPlan? created;
    for (final p in ref.read(customTrainingPlanProvider).reversed) {
      if (p.clientId == clientId && p.name == newName) {
        created = p;
        break;
      }
    }
    if (created == null) return;

    final days = program.days();
    for (final day in days) {
      await notifier.addDay(planId: created.id, dayName: day.name);
    }
    for (var i = 0; i < days.length; i++) {
      for (final ex in days[i].exercises) {
        await notifier.addExerciseToDay(
          planId: created.id,
          dayIndex: i,
          exercise: ex,
        );
      }
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Plán "$newName" byl vložen mezi vlastní tréninky.')),
    );
  }

  String _buildUniquePlanName(
    String baseName,
    List<CustomTrainingPlan> existingPlans,
  ) {
    final used = existingPlans.map((e) => e.name.trim().toLowerCase()).toSet();

    if (!used.contains(baseName.trim().toLowerCase())) {
      return baseName;
    }

    var i = 2;
    while (true) {
      final candidate = '$baseName ($i)';
      if (!used.contains(candidate.trim().toLowerCase())) {
        return candidate;
      }
      i++;
    }
  }

/// Katalog programů – každý program vytvoří tréninkový plán a (kde to
/// dává smysl) rovnou nastaví i jídelníček se stejným datem a fázemi.
class _ProgramCatalogScreen extends ConsumerWidget {
  final String clientId;

  const _ProgramCatalogScreen({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    Future<void> run(
      Future<void> Function(BuildContext, WidgetRef, String) insert,
    ) async {
      if (!await requireFull(context, ref, 'Kompletní program')) return;
      if (!context.mounted) return;
      int count() => ref
          .read(customTrainingPlanProvider)
          .where((p) => p.clientId == clientId)
          .length;

      final before = count();
      await insert(context, ref, clientId);
      // Plán se vytvořil (nebyl zrušen dialog) → zpět na seznam plánů.
      if (context.mounted && count() > before) Navigator.pop(context);
    }

    const programs = <_ProgramInfo>[
      _ProgramInfo(
        icon: Icons.movie_filter_outlined,
        title: HollywoodPrep.name,
        length: '12 týdnů k datu natáčení',
        description:
            'Příprava postavy na natáčení nebo focení: nízký tuk, důraz na '
            'partie viditelné na kameře, síla se udržuje.',
        diet: 'Jídelníček ${HollywoodPrep.name}',
        insert: _insertHollywoodPlan,
      ),
      _ProgramInfo(
        icon: Icons.emoji_events_outlined,
        title: BikiniPrep.name,
        length: '16 týdnů k datu závodu',
        description:
            'Kompletní příprava na závody: hýždě a ramena, útlý pas, pózování, '
            'peak week.',
        diet: 'Jídelníček ${BikiniPrep.name}',
        insert: _insertBikiniPlan,
      ),
      _ProgramInfo(
        icon: Icons.favorite_outline,
        title: GlutePlan.name,
        length: '12 týdnů od dneška',
        description:
            'Růst a tvar hýždí: 3 tréninky hýždí + 1 horní tělo týdně, '
            'progrese a odlehčovací týden.',
        diet: 'Jídelníček ${GlutePlan.name}',
        insert: _insertGlutePlan,
      ),
      _ProgramInfo(
        icon: Icons.fitness_center,
        title: 'Ruský cyklus – bench press',
        length: '12 týdnů k datu závodu',
        description:
            'Příprava na závody v benchi: váhy z aktuálního maxima, trénink '
            'nervové soustavy na konci, návrh pokusů na závod.',
        diet: 'Jídelníček ${StrengthPlan.name}',
        insert: _insertBenchRussianPlan,
      ),
      _ProgramInfo(
        icon: Icons.fitness_center,
        title: 'Silový trojboj – příprava na závody',
        length: '12 týdnů k datu závodu',
        description:
            'Dřep, bench a mrtvý tah z training maxu, objem → síla → '
            'intenzifikace → peak → taper.',
        diet: 'Jídelníček ${StrengthPlan.name}',
        insert: _insertPowerliftingMeetPrepPlan,
      ),
      _ProgramInfo(
        icon: Icons.local_fire_department,
        title: '90denní vyrýsování',
        length: '12 týdnů od dneška',
        description: 'Shazovací plán zaměřený na spalování tuku a kondici.',
        diet: null,
        insert: _insertConstantinCutPlan,
      ),
    ];

    Future<void> preview(LibraryProgram p) async {
      final insert = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _LibraryPreview(program: p),
      );
      if (insert == true && context.mounted) {
        await run((c, r, id) => _insertLibraryProgram(c, r, id, p));
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(l10n.programsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(l10n.programsHint),
          const SizedBox(height: 16),
          const _GroupTitle('Programy s jídelníčkem'),
          for (final p in programs)
            Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Icon(p.icon),
                title: Text(
                  p.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  '${p.length}\n${p.description}\n'
                  '${p.diet == null ? l10n.programDietByGoal : '${l10n.programIncludes}: ${p.diet}'}',
                ),
                isThreeLine: true,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => run(p.insert),
              ),
            ),
          for (final group in ProgramGroup.all) ...[
            const SizedBox(height: 8),
            _GroupTitle(group),
            for (final p in ProgramLibrary.inGroup(group))
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: Icon(_groupIcon(group)),
                  title: Text(
                    p.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${p.level} · ${p.length}\n${p.description}'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => preview(p),
                ),
              ),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

IconData _groupIcon(String group) => switch (group) {
      ProgramGroup.bodybuilding => Icons.fitness_center,
      ProgramGroup.strength => Icons.sports_gymnastics,
      ProgramGroup.running => Icons.directions_run,
      ProgramGroup.tests => Icons.local_police_outlined,
      _ => Icons.bolt_outlined,
    };

class _GroupTitle extends StatelessWidget {
  final String text;
  const _GroupTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w900),
      ),
    );
  }
}

/// Náhled programu před vložením – všechny dny a cviky.
class _LibraryPreview extends StatelessWidget {
  final LibraryProgram program;
  const _LibraryPreview({required this.program});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final days = program.days();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scroll) => Column(
        children: [
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              children: [
                Text(
                  program.title,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  '${program.level} · ${program.length} · ${days.length} tréninků v plánu',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
                const SizedBox(height: 10),
                Text(program.description),
                const SizedBox(height: 16),
                for (final d in days)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            d.name,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 6),
                          for (final e in d.exercises)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Text(
                                '• ${e.customName} – ${e.sets} × ${e.reps}'
                                '${e.rir == '—' ? '' : ' (RIR ${e.rir})'}',
                                style: TextStyle(color: cs.onSurfaceVariant),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.add),
                  label: const Text('Vložit plán klientovi'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgramInfo {
  final IconData icon;
  final String title;
  final String length;
  final String description;
  final String? diet;
  final Future<void> Function(BuildContext, WidgetRef, String) insert;

  const _ProgramInfo({
    required this.icon,
    required this.title,
    required this.length,
    required this.description,
    required this.diet,
    required this.insert,
  });
}

class _TemplateCategorySection extends StatelessWidget {
  final CustomTrainingCategory category;
  final List<SharedTrainingTemplate> templates;
  final String clientId;

  const _TemplateCategorySection({
    required this.category,
    required this.templates,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          _categoryLabel(context, category),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...templates.map(
          (template) => _SharedTemplateCard(
            template: template,
            clientId: clientId,
          ),
        ),
      ],
    );
  }
}
String _categoryLabel(
  BuildContext context,
  CustomTrainingCategory category,
) {
  final l10n = AppLocalizations.of(context)!;

  switch (category) {
    case CustomTrainingCategory.strength:
      return l10n.strengthTrainings;

    case CustomTrainingCategory.bulk:
      return l10n.bulk;

    case CustomTrainingCategory.cut:
      return l10n.cut;

    case CustomTrainingCategory.recomp:
      return l10n.recomp;

    case CustomTrainingCategory.conditioning:
      return l10n.conditioning;

    case CustomTrainingCategory.powerlifting:
      return l10n.powerlifting;

    case CustomTrainingCategory.bodybuilding:
      return l10n.bodybuilding;

    case CustomTrainingCategory.hollywood:
      return l10n.hollywoodTitle;

    case CustomTrainingCategory.bikini:
      return l10n.bikiniTitle;

    case CustomTrainingCategory.glutes:
      return l10n.gluteTitle;

    case CustomTrainingCategory.custom:
      return l10n.other;
  }
}
class _PlanCategorySection extends StatelessWidget {
  final CustomTrainingCategory category;
  final List<CustomTrainingPlan> plans;

  const _PlanCategorySection({
    required this.category,
    required this.plans,
  });

  @override
  Widget build(BuildContext context) {
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(
          _categoryLabel(context, category),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        ...plans.map((plan) => _PlanCard(plan: plan)),
      ],
    );
  }
}

class _SharedTemplateCard extends ConsumerWidget {
  final SharedTrainingTemplate template;
  final String clientId;

  const _SharedTemplateCard({
    required this.template,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    return _ResponsivePlanCard(
      title: template.name,
      description: template.description ?? l10n.noDescription,
      daysLine: '${l10n.daysCount}: ${template.days.length}',
      actions: [
        FilledButton(
          onPressed: () async {
            await ref
                .read(sharedTrainingTemplatesProvider.notifier)
                .createPlanFromTemplate(
                  clientId: clientId,
                  template: template,
                  ref: ref,
                );

            if (!context.mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  l10n.templateInserted(template.name),
                ),
              ),
            );
          },
          child: Text(l10n.insert),
        ),
      ],
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final CustomTrainingPlan plan;

  const _PlanCard({
    required this.plan,
  });

  Future<void> _activateAndOpen(
    BuildContext context,
    WidgetRef ref,
  ) async {
    await ref
        .read(customTrainingPlanProvider.notifier)
        .setActivePlan(
          clientId: plan.clientId,
          planId: plan.id,
        );

    if (!context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const TrainingPlanScreen(),
      ),
    );
  }

  Future<void> _openPlanDetail(
    BuildContext context,
  ) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CustomPlanDetailScreen(
          planId: plan.id,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final l10n = AppLocalizations.of(context)!;

    return _ResponsivePlanCard(
      title: plan.name,
      description: plan.description ?? l10n.noDescription,
      daysLine: '${l10n.daysCount}: ${plan.days.length}',
      isActive: plan.isActive,
      activeLabel: l10n.active,
      onTap: () => _openPlanDetail(context),
      menu: PopupMenuButton<String>(
        tooltip: '',
        icon: const Icon(Icons.more_vert),
        onSelected: (value) async {
          if (value != 'delete') return;
          final ok = await showDialog<bool>(
            context: context,
            builder: (d) => AlertDialog(
              title: Text(l10n.deleteWholePlan),
              content: Text('${plan.name}\n\n${l10n.deletePlanWarning}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(d, false),
                  child: Text(l10n.cancel),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(d).colorScheme.error,
                    foregroundColor: Theme.of(d).colorScheme.onError,
                  ),
                  onPressed: () => Navigator.pop(d, true),
                  child: Text(l10n.deleteForever),
                ),
              ],
            ),
          );
          if (ok == true) {
            await ref
                .read(customTrainingPlanProvider.notifier)
                .deletePlan(plan.id);
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                const Icon(Icons.delete_outline),
                const SizedBox(width: 12),
                Text(l10n.delete),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => _activateAndOpen(context, ref),
          child: Text(l10n.open),
        ),
        if (!plan.isActive)
          OutlinedButton(
            onPressed: () {
              ref
                  .read(customTrainingPlanProvider.notifier)
                  .setActivePlan(
                    clientId: plan.clientId,
                    planId: plan.id,
                  );
            },
            child: Text(l10n.activate),
          ),
      ],
    );
  }
}

/// Karta plánu, která se vejde i na úzký telefon:
/// název a popis přes celou šířku, tlačítka pod nimi.
class _ResponsivePlanCard extends StatelessWidget {
  final String title;
  final String description;
  final String daysLine;
  final List<Widget> actions;
  final bool isActive;
  final String? activeLabel;
  final VoidCallback? onTap;
  final Widget? menu;

  const _ResponsivePlanCard({
    required this.title,
    required this.description,
    required this.daysLine,
    required this.actions,
    this.isActive = false,
    this.activeLabel,
    this.onTap,
    this.menu,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      clipBehavior: Clip.antiAlias,
      shape: isActive
          ? RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: scheme.primary, width: 1.5),
            )
          : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  if (isActive && activeLabel != null)
                    Container(
                      margin: const EdgeInsets.only(left: 8, top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        activeLabel!,
                        style: TextStyle(
                          fontSize: 12,
                          color: scheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (menu != null) menu!,
                  if (menu == null) const SizedBox(width: 8),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                daysLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: SizedBox(
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: actions,
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
