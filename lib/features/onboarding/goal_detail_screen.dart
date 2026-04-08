import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/goal.dart';
import '../../providers/user_profile_provider.dart';
import '../dashboard/dashboard_screen.dart';

class GoalDetailScreen extends ConsumerStatefulWidget {
  final GoalType type;
  final String title;

  const GoalDetailScreen({
    super.key,
    required this.type,
    required this.title,
  });

  @override
  ConsumerState<GoalDetailScreen> createState() => _GoalDetailScreenState();
}

class _GoalDetailScreenState extends ConsumerState<GoalDetailScreen> {
  GoalReason? _reason;

  /// ⚠️ jen pro POSTAVU jako preference (legacy)
  GoalPhase? _phase;

  DateTime _date = DateTime.now().add(const Duration(days: 90));
  final _noteController = TextEditingController();
  final _targetWeightCtrl = TextEditingController();

  String? _gainFocus; // "stability" | "energy" | "strength" | "pro"
  String? _mealRegularity; // "low" | "medium" | "high"
  String? _appetite; // "low" | "medium" | "high"
  bool _showTargetWeightForGain = false;

  bool get _isPhysique => widget.type == GoalType.physique;
  bool get _isGainSupport => widget.type == GoalType.weightGainSupport;

  @override
  void initState() {
    super.initState();

    if (_isGainSupport) {
      _date = DateTime.now().add(const Duration(days: 120));
      _showTargetWeightForGain = false;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _targetWeightCtrl.dispose();
    super.dispose();
  }

  double? _parseTargetWeightOrNull() {
    final raw = _targetWeightCtrl.text.trim();
    if (raw.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(raw.replaceAll(',', '.'));
    if (parsed == null) {
      return null;
    }
    if (parsed < 30 || parsed > 300) {
      return null;
    }
    return parsed;
  }

  void _snack(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  GoalPhase _defaultPhase() {
    switch (widget.type) {
      case GoalType.weightLoss:
        return GoalPhase.cut;
      case GoalType.strength:
        return GoalPhase.strength;
      case GoalType.endurance:
        return GoalPhase.maintain;
      case GoalType.physique:
        return GoalPhase.build;
      case GoalType.weightGainSupport:
        return GoalPhase.build;
    }
  }

  Future<void> _save() async {
    if (_isGainSupport) {
      if (_gainFocus == null) {
        _snack('Vyber prosím, na co se chceš zaměřit.');
        return;
      }

      const GoalReason safeReason = GoalReason.eatingDisorderSupport;

      double? targetWeight;
      if (_showTargetWeightForGain) {
        targetWeight = _parseTargetWeightOrNull();
        if (_targetWeightCtrl.text.trim().isNotEmpty && targetWeight == null) {
          _snack('Cílová váha musí být číslo 30–300 kg');
          return;
        }
      }

      final extra = <String>[
        'GAIN_SUPPORT',
        'focus=${_gainFocus ?? "-"}',
        'meal=${_mealRegularity ?? "-"}',
        'appetite=${_appetite ?? "-"}',
      ].join(';');

      final noteUser = _noteController.text.trim();
      final combinedNote = noteUser.isEmpty ? extra : '$noteUser\n$extra';

      final goal = Goal(
        type: widget.type,
        reason: safeReason,
        targetDate: _date,
        planMode: GoalPlanMode.normal,
        phase: GoalPhase.build,
        targetWeightKg: _showTargetWeightForGain ? targetWeight : null,
        note: combinedNote,
      );

      ref.read(userProfileProvider.notifier).setGoal(goal);

      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
        (_) => false,
      );
      return;
    }

    if (_reason == null) {
      _snack('Vyber důvod cíle');
      return;
    }

    if (_isPhysique && _phase == null) {
      _snack('Vyber co chceš s postavou');
      return;
    }

    final targetWeight = _parseTargetWeightOrNull();
    if (_targetWeightCtrl.text.trim().isNotEmpty && targetWeight == null) {
      _snack('Cílová váha musí být číslo 30–300 kg');
      return;
    }

    if (_isPhysique) {
      final ok = await _validatePhysiqueDateAndOfferModes();
      if (!ok) {
        return;
      }
    }

    final goal = Goal(
      type: widget.type,
      reason: _reason!,
      targetDate: _date,
      planMode: GoalPlanMode.auto,
      phase: _phase ?? _defaultPhase(),
      targetWeightKg: targetWeight,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    ref.read(userProfileProvider.notifier).setGoal(goal);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  void _saveWithPlanMode(GoalPlanMode mode) {
    if (_reason == null) {
      return;
    }

    final targetWeight = _parseTargetWeightOrNull();
    if (_targetWeightCtrl.text.trim().isNotEmpty && targetWeight == null) {
      _snack('Cílová váha musí být číslo 30–300 kg');
      return;
    }

    final goal = Goal(
      type: widget.type,
      reason: _reason!,
      targetDate: _date,
      planMode: mode,
      phase: _phase ?? _defaultPhase(),
      targetWeightKg: targetWeight,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
    );

    ref.read(userProfileProvider.notifier).setGoal(goal);

    if (!mounted) {
      return;
    }
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
      (_) => false,
    );
  }

  Future<bool> _validatePhysiqueDateAndOfferModes() async {
    final now = DateTime.now();
    final daysToTarget = _date.difference(now).inDays;

    final isWinter = now.month >= 11 || now.month <= 2;
    final userWantsCut = _phase == GoalPhase.cut;
    final targetSoon = daysToTarget < 90;

    if (isWinter && userWantsCut && targetSoon) {
      final result = await showDialog<_PhysiqueDecision>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Nereálné načasování'),
            content: const Text(
              'Teď je období nabírání (zima) a do cíle je málo času.\n\n'
              'V normální periodizaci by rýsování začalo až později.\n'
              'Chceš upravit datum, nebo zapnout zrychlený režim?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(
                  _PhysiqueDecision.editDate,
                ),
                child: const Text('Upravit datum'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(
                  _PhysiqueDecision.accelerated,
                ),
                child: const Text('Zrychlený režim'),
              ),
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(
                  _PhysiqueDecision.keepAnyway,
                ),
                child: const Text('Ponechat i tak'),
              ),
            ],
          );
        },
      );

      if (result == null) {
        return false;
      }

      switch (result) {
        case _PhysiqueDecision.editDate:
          return false;
        case _PhysiqueDecision.accelerated:
          _saveWithPlanMode(GoalPlanMode.accelerated);
          return false;
        case _PhysiqueDecision.keepAnyway:
          return true;
      }
    }

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: _isGainSupport ? _buildGainSupportUi() : _buildStandardUi(),
      ),
    );
  }

  Widget _buildStandardUi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Proč tento cíl?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        RadioGroup<GoalReason>(
          groupValue: _reason,
          onChanged: (GoalReason? v) => setState(() => _reason = v),
          child: Column(
            children: [
              _reasonTile('Závody', GoalReason.competition),
              _reasonTile('Forma do léta', GoalReason.summerShape),
              _reasonTile('Zdraví', GoalReason.health),
              _reasonTile('Výkon', GoalReason.performance),
              _reasonTile('Vzhled', GoalReason.aesthetic),
            ],
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Do kdy chceš cíl splnit?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        ListTile(
          title: Text('${_date.day}.${_date.month}.${_date.year}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3 * 365)),
            );

            if (picked != null) {
              setState(() => _date = picked);
            }
          },
        ),
        const SizedBox(height: 24),
        if (_isPhysique) ...[
          const Text(
            'Co chceš s postavou?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          RadioGroup<GoalPhase>(
            groupValue: _phase,
            onChanged: (GoalPhase? v) => setState(() => _phase = v),
            child: Column(
              children: [
                _phaseTile('Nabrat svaly', GoalPhase.build),
                _phaseTile('Vyrýsovat', GoalPhase.cut),
                _phaseTile('Udržet', GoalPhase.maintain),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
        const Text(
          'Cílová váha (kg)',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Z této váhy budeme počítat bílkoviny a další doporučení.',
          style: TextStyle(color: Colors.grey[700]),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _targetWeightCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Např. 82',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Poznámka (nepovinné)',
            hintText: 'např. Mistrovství ČR v trojboji',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('Pokračovat'),
          ),
        ),
      ],
    );
  }

  Widget _buildGainSupportUi() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Podpora příjmu a energie',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Tahle volba je navržená tak, aby nešla “přes váhu za každou cenu”. '
              'Cíl je stabilita, energie a bezpečný progres.\n\n'
              'Pokud řešíš bulimii / anorexii nebo máš zdravotní rizika, '
              'je nejlepší to kombinovat s odborníkem (praktický lékař, nutriční terapeut, psycholog).',
              style: TextStyle(color: Colors.grey[800]),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Na co se chceš zaměřit?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        RadioGroup<String>(
          groupValue: _gainFocus,
          onChanged: (String? v) => setState(() => _gainFocus = v),
          child: Column(
            children: [
              _gainFocusTile(
                title: 'Stabilizovat příjem a režim',
                subtitle: 'Pravidelnost, klid, méně výkyvů.',
                value: 'stability',
              ),
              _gainFocusTile(
                title: 'Více energie během dne',
                subtitle: 'Únava, slabost, regenerace.',
                value: 'energy',
              ),
              _gainFocusTile(
                title: 'Bezpečně nabrat sílu / svaly',
                subtitle: 'Pozvolný progres bez extrémů.',
                value: 'strength',
              ),
              _gainFocusTile(
                title: 'Doporučení odborníka / zdravotní důvod',
                subtitle: 'Např. lékař / terapeut / nutriční terapeut.',
                value: 'pro',
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Krátký dotazník (pomůže přizpůsobit doporučení)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _mealRegularity,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Pravidelnost jídel',
          ),
          items: const [
            DropdownMenuItem(value: 'low', child: Text('Spíš nepravidelně')),
            DropdownMenuItem(
              value: 'medium',
              child: Text('Občas pravidelně'),
            ),
            DropdownMenuItem(
              value: 'high',
              child: Text('Většinou pravidelně'),
            ),
          ],
          onChanged: (v) => setState(() => _mealRegularity = v),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _appetite,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Chuť k jídlu',
          ),
          items: const [
            DropdownMenuItem(
              value: 'low',
              child: Text('Nízká / nechce se mi jíst'),
            ),
            DropdownMenuItem(value: 'medium', child: Text('Střední')),
            DropdownMenuItem(value: 'high', child: Text('Vysoká')),
          ],
          onChanged: (v) => setState(() => _appetite = v),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          value: _showTargetWeightForGain,
          title: const Text('Chci zadat cílovou váhu (volitelné)'),
          subtitle: const Text(
            'Doporučené nechat vypnuté, pokud je váha citlivé téma.',
          ),
          onChanged: (v) => setState(() => _showTargetWeightForGain = v),
        ),
        if (_showTargetWeightForGain) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _targetWeightCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cílová váha (kg) – volitelné',
              border: OutlineInputBorder(),
            ),
          ),
        ],
        const SizedBox(height: 16),
        TextField(
          controller: _noteController,
          decoration: const InputDecoration(
            labelText: 'Poznámka (nepovinné)',
            hintText: 'např. co je pro tebe největší problém / co chceš zlepšit',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Do kdy chceš vidět zlepšení?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        ListTile(
          title: Text('${_date.day}.${_date.month}.${_date.year}'),
          trailing: const Icon(Icons.calendar_today),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3 * 365)),
            );

            if (picked != null) {
              setState(() => _date = picked);
            }
          },
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            child: const Text('Pokračovat'),
          ),
        ),
      ],
    );
  }

  Widget _gainFocusTile({
    required String title,
    required String subtitle,
    required String value,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
    );
  }

  Widget _reasonTile(String title, GoalReason value) {
    return RadioListTile<GoalReason>(
      title: Text(title),
      value: value,
    );
  }

  Widget _phaseTile(String title, GoalPhase value) {
    return RadioListTile<GoalPhase>(
      title: Text(title),
      value: value,
    );
  }
}

enum _PhysiqueDecision {
  editDate,
  accelerated,
  keepAnyway,
}