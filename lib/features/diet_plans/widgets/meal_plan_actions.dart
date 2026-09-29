import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/coach/coach_client.dart';
import '../../../providers/coach/active_client_provider.dart';
import '../../../providers/coach/app_role_provider.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/user_profile_provider.dart';
import '../../../services/pdf/diet_plan_pdf_service.dart';
import '../../coaching/workout_widgets.dart';
import '../logic/meal_plan_math.dart';
import '../logic/meal_plan_scaling_service.dart';
import '../models/carb_cycling_plan.dart';
import '../models/saved_meal_plan.dart';
import '../providers/diet_plan_provider.dart';
import '../providers/saved_meal_plans_provider.dart';
import '../screens/weekly_meal_plan_screen.dart';

/// Společné akce pro jídelníčky: uložení s vlastním názvem, přepočet
/// šablony na klienta, výběr klienta / šablony, otevření a tisk.
class MealPlanActions {
  MealPlanActions._();

  static bool isCoach(WidgetRef ref) =>
      ref.read(appRoleProvider) == AppRole.coach;

  /// Klient propojený s trenérem – jídelníčky od trenéra jen čte.
  static bool isLinkedClient(WidgetRef ref) =>
      ref.read(clientLinkProvider).valueOrNull != null;

  static String kcalText(double kcal) {
    final v = kcal.round().toString();
    if (v.length <= 3) return '$v kcal';
    return '${v.substring(0, v.length - 3)} ${v.substring(v.length - 3)} kcal';
  }

  static String summary(SavedMealPlan p) {
    final plan = p.plan;
    final days = plan.days.isEmpty ? p.durationDays : plan.days.length;
    return '${kcalText(MealPlanMath.planKcal(plan))} · '
        'B ${plan.protein.round()} · S ${plan.carbs.round()} · '
        'T ${plan.fats.round()} g · $days ${_dny(days)}';
  }

  static String _dny(int n) => n == 1 ? 'den' : (n >= 2 && n <= 4 ? 'dny' : 'dní');

  static String date(DateTime d) => '${d.day}. ${d.month}. ${d.year}';

  // ------------------------------------------------------------------
  // Klient
  // ------------------------------------------------------------------

  /// Nastaví klienta jako aktivního a načte jeho profil (cíle, váhu),
  /// aby se jídelníček počítal pro něj.
  static Future<void> activateClient(WidgetRef ref, CoachClient client) async {
    await ref.read(activeClientIdProvider.notifier).setActive(client.clientId);
    final notifier = ref.read(userProfileProvider.notifier);
    await notifier.switchToClient(client.clientId);
    final profile = ref.read(userProfileProvider);
    if (profile == null ||
        profile.clientId != client.clientId ||
        profile.height == 0 ||
        profile.weight == 0) {
      await notifier.setProfileBasics(
        clientId: client.clientId,
        firstName: client.firstName,
        lastName: client.lastName,
        age: client.age,
        gender: client.gender,
        heightCm: client.heightCm,
        weightKg: client.weightKg,
      );
    }
  }

  static Future<CoachClient?> pickClient(
    BuildContext context,
    WidgetRef ref, {
    String title = 'Pro kterého klienta?',
  }) async {
    final all = await ref.read(coachClientsControllerProvider.future);
    final clients = [
      for (final c in all)
        if (!c.client.isArchived && !c.client.isDeleted) c.client,
    ]..sort((a, b) => a.displayName.compareTo(b.displayName));
    if (!context.mounted) return null;
    if (clients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zatím nemáš žádné klienty.')),
      );
      return null;
    }

    var query = '';
    return showDialog<CoachClient>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final q = query.trim().toLowerCase();
          final shown = q.isEmpty
              ? clients
              : clients
                  .where((c) => c.displayName.toLowerCase().contains(q))
                  .toList();
          return AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 420,
              height: 440,
              child: Column(
                children: [
                  TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Hledat klienta',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setLocal(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final c in shown)
                          ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                '${c.firstName.isEmpty ? '' : c.firstName[0]}'
                                '${c.lastName.isEmpty ? '' : c.lastName[0]}',
                              ),
                            ),
                            title: Text(c.displayName),
                            subtitle: Text(
                              '${c.weightKg.toStringAsFixed(1)} kg · '
                              '${c.heightCm} cm · ${c.age} let',
                            ),
                            onTap: () => Navigator.pop(ctx, c),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Zrušit'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // Výběr šablony
  // ------------------------------------------------------------------

  static Future<SavedMealPlan?> pickPlan(
    BuildContext context,
    WidgetRef ref, {
    String title = 'Vyber šablonu jídelníčku',
  }) {
    final plans = ref.read(savedMealPlansProvider);
    if (plans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Knihovna je zatím prázdná. Ulož nějaký jídelníček '
            '(ikona diskety u jídelníčku) a pak ho můžeš použít tady.',
          ),
        ),
      );
      return Future.value(null);
    }

    var query = '';
    var templatesOnly = false;
    return showModalBottomSheet<SavedMealPlan>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final q = query.trim().toLowerCase();
          final shown = plans.where((p) {
            if (templatesOnly && !p.isTemplate) return false;
            if (q.isEmpty) return true;
            return p.name.toLowerCase().contains(q) ||
                (p.clientName ?? '').toLowerCase().contains(q);
          }).toList();
          return SizedBox(
            height: MediaQuery.of(ctx).size.height * 0.8,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(ctx).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Hledat podle názvu nebo klienta',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (v) => setLocal(() => query = v),
                  ),
                  const SizedBox(height: 6),
                  FilterChip(
                    label: const Text('Jen obecné šablony'),
                    selected: templatesOnly,
                    onSelected: (v) => setLocal(() => templatesOnly = v),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView.separated(
                      itemCount: shown.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (_, i) {
                        final p = shown[i];
                        return ListTile(
                          leading: Icon(
                            p.isTemplate
                                ? Icons.bookmark_outline
                                : Icons.person_outline,
                          ),
                          title: Text(p.name),
                          subtitle: Text(
                            '${p.isTemplate ? 'Šablona' : p.clientName ?? 'Klient'}'
                            ' · ${summary(p)}',
                          ),
                          onTap: () => Navigator.pop(ctx, p),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // Přepočet šablony
  // ------------------------------------------------------------------

  /// Přepočítá šablonu na aktuálně aktivní profil (klienta), uloží ji
  /// jako jeho jídelníček a vrátí ji.
  static Future<SavedMealPlan?> applyToActiveProfile(
    BuildContext context,
    WidgetRef ref,
    SavedMealPlan template,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final profile = ref.read(userProfileProvider);
    if (profile == null) return null;

    final from = MealPlanScalingService.templateCalories(template);
    final suggested = MealPlanScalingService.suggestedCalories(
      template: template,
      profile: profile,
      l10n: l10n,
    );
    final who = profile.displayName.trim().isEmpty
        ? 'klienta'
        : profile.displayName.trim();
    final firstName = profile.firstName.trim();
    final kcalCtrl = TextEditingController(text: suggested.round().toString());
    final nameCtrl = TextEditingController(
      text: firstName.isEmpty ? template.name : '${template.name} – $firstName',
    );

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Přepočítat pro $who'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Šablona „${template.name}“: ${kcalText(from)} / den'),
                const SizedBox(height: 14),
                TextField(
                  controller: kcalCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cílové kalorie klienta (kcal / den)',
                    helperText: profile.goal != null
                        ? 'Spočítáno z cíle klienta – můžeš upravit.'
                        : 'Klient nemá cíl – odhad podle váhy '
                            '(${profile.weight.toStringAsFixed(1)} kg).',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Název jídelníčku',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Porce se přepočítají a zaokrouhlí (vejce na celé kusy, '
                  'gramy po 5 g) a makroživiny se znovu spočítají '
                  'v celých gramech.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.calculate_outlined),
            label: const Text('Přepočítat a uložit'),
          ),
        ],
      ),
    );
    if (ok != true) return null;

    final target =
        double.tryParse(kcalCtrl.text.trim().replaceAll(',', '.')) ?? suggested;
    final scaled = MealPlanScalingService.scaleTemplateToProfile(
      template: template,
      profile: profile,
      l10n: l10n,
      targetCalories: target,
    );

    final clientId = profile.clientId;
    return ref.read(savedMealPlansProvider.notifier).saveTemplate(
          name: nameCtrl.text.trim().isEmpty ? template.name : nameCtrl.text,
          plan: scaled,
          baseWeight: profile.weight,
          baseCalories: MealPlanMath.planKcal(scaled),
          durationDays:
              scaled.days.isEmpty ? template.durationDays : scaled.days.length,
          trainerNote: template.trainerNote,
          clientId: clientId,
          clientName: (clientId ?? '').isEmpty ? null : profile.displayName,
          sourceId: template.id,
        );
  }

  /// Celý postup „Použít pro klienta“: výběr klienta (u trenéra),
  /// přepočet, uložení a otevření výsledku.
  static Future<void> useForClient(
    BuildContext context,
    WidgetRef ref,
    SavedMealPlan template, {
    CoachClient? client,
  }) async {
    if (isCoach(ref)) {
      final picked = client ?? await pickClient(context, ref);
      if (picked == null || !context.mounted) return;
      await activateClient(ref, picked);
      if (!context.mounted) return;
    }
    final saved = await applyToActiveProfile(context, ref, template);
    if (saved == null || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved.isTemplate
              ? 'Jídelníček „${saved.name}“ je přepočítaný a uložený.'
              : 'Jídelníček „${saved.name}“ je uložený u klienta '
                  '${saved.clientName ?? ''}.',
        ),
      ),
    );
    open(context, ref, saved);
  }

  // ------------------------------------------------------------------
  // Uložení s vlastním názvem
  // ------------------------------------------------------------------

  /// Dialog pro uložení jídelníčku. U trenéra lze jídelníček rovnou
  /// přiřadit aktivnímu klientovi; každý uložený jídelníček je zároveň
  /// šablona pro další klienty.
  static Future<SavedMealPlan?> saveDialog(
    BuildContext context,
    WidgetRef ref,
    DietMealPlan plan, {
    SavedMealPlan? existing,
    String? suggestedName,
  }) async {
    final profile = ref.read(userProfileProvider);
    final coach = isCoach(ref);
    final activeId = profile?.clientId;
    final canAssign = coach && (activeId ?? '').isNotEmpty;
    final activeName = profile?.displayName ?? '';

    final nameCtrl = TextEditingController(
      text: existing?.name ?? suggestedName ?? '',
    );
    final noteCtrl = TextEditingController(
      text: existing?.trainerNote ?? plan.note ?? '',
    );
    var forClient = existing != null ? !existing.isTemplate : canAssign;
    var asNew = existing == null;
    String? error;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? 'Uložit jídelníček' : 'Uložit změny'),
          content: SizedBox(
            width: 460,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: existing == null,
                    decoration: InputDecoration(
                      labelText: 'Název jídelníčku',
                      hintText: 'např. Redukce – 5 jídel, bez laktózy',
                      errorText: error,
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Poznámka pro klienta (nepovinné)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${kcalText(MealPlanMath.planKcal(plan))} / den · '
                    '${plan.days.length} ${_dny(plan.days.length)}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  if (canAssign ||
                      (existing != null && !existing.isTemplate)) ...[
                    const SizedBox(height: 4),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: forClient,
                      onChanged: (v) => setLocal(() => forClient = v),
                      title: Text(
                        'Jídelníček klienta: '
                        '${existing?.clientName ?? activeName}',
                      ),
                      subtitle: const Text(
                        'Zobrazí se u klienta (i online v jeho aplikaci). '
                        'Vypnuto = obecná šablona.',
                      ),
                    ),
                  ],
                  if (existing != null)
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      value: asNew,
                      onChanged: (v) => setLocal(() => asNew = v ?? false),
                      title: const Text('Uložit jako nový jídelníček'),
                      subtitle: const Text('Původní zůstane beze změny.'),
                    ),
                  const SizedBox(height: 6),
                  Text(
                    'Každý uložený jídelníček najdeš v knihovně a můžeš ho '
                    'přepočítat pro dalšího klienta.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Zrušit'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  setLocal(() => error = 'Zadej název jídelníčku');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Uložit'),
            ),
          ],
        ),
      ),
    );
    if (ok != true) return null;

    final notifier = ref.read(savedMealPlansProvider.notifier);
    final note = noteCtrl.text.trim();
    final withNote = plan.copyWith(note: note);

    if (existing != null && !asNew) {
      return notifier.update(
        existing.copyWith(
          name: nameCtrl.text.trim(),
          plan: withNote,
          trainerNote: note,
          durationDays: plan.days.isEmpty ? existing.durationDays : plan.days.length,
          clientId: forClient ? (existing.clientId ?? activeId) : null,
          clientName: forClient ? (existing.clientName ?? activeName) : null,
          clearClient: !forClient,
        ),
      );
    }

    final clientId = forClient ? (existing?.clientId ?? activeId) : null;
    final clientName =
        forClient ? (existing?.clientName ?? activeName) : null;
    return notifier.saveTemplate(
      name: nameCtrl.text,
      plan: withNote,
      baseWeight: profile?.weight ?? existing?.baseWeight ?? 0,
      baseCalories: MealPlanMath.planKcal(plan),
      durationDays: plan.days.isEmpty ? 7 : plan.days.length,
      trainerNote: note,
      clientId: clientId,
      clientName: clientName,
      sourceId: existing?.id,
    );
  }

  // ------------------------------------------------------------------
  // Otevření / tisk / přejmenování / smazání
  // ------------------------------------------------------------------

  static void open(BuildContext context, WidgetRef ref, SavedMealPlan p) {
    ref.read(dietPlanProvider.notifier).state = p.plan;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyMealPlanScreen(
          mealPlan: p.plan,
          titleOverride: p.name,
          savedTemplate: p,
        ),
      ),
    );
  }

  static Future<void> printPlan(
    BuildContext context,
    SavedMealPlan p, {
    bool share = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    final subtitle = p.clientName == null ? null : 'Pro: ${p.clientName}';
    return share
        ? DietPlanPdfService.sharePlan(
            p.plan,
            l10n,
            trainerNote: p.trainerNote,
            documentTitle: p.name,
            subtitle: subtitle,
          )
        : DietPlanPdfService.printPlan(
            p.plan,
            l10n,
            trainerNote: p.trainerNote,
            documentTitle: p.name,
            subtitle: subtitle,
          );
  }

  static Future<void> rename(
    BuildContext context,
    WidgetRef ref,
    SavedMealPlan p,
  ) async {
    final ctrl = TextEditingController(text: p.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Přejmenovat jídelníček'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Název',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Uložit'),
          ),
        ],
      ),
    );
    if (name == null || name.trim().isEmpty) return;
    await ref.read(savedMealPlansProvider.notifier).rename(p.id, name);
  }

  static Future<void> confirmDelete(
    BuildContext context,
    WidgetRef ref,
    SavedMealPlan p,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat jídelníček?'),
        content: Text(
          '„${p.name}“ se smaže${p.isTemplate ? '' : ' i u klienta'}. '
          'Tuto akci nejde vrátit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Zrušit'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(savedMealPlansProvider.notifier).deleteTemplate(p.id);
    }
  }
}
