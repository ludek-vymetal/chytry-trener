import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/coach/coach_auth_provider.dart';
import '../../../providers/coach/coach_circumference_controller.dart';
import '../../../providers/coach/coach_clients_controller.dart';
import '../../../providers/coach/coach_diagnostic_controller.dart';
import '../../../providers/coach/coach_goal_controller.dart';
import '../../../providers/coach/coach_inbody_controller.dart';
import '../../../providers/coach/coach_notes_controller.dart';
import '../../../providers/coach/coach_setup_provider.dart';
import '../../../providers/daily_history_provider.dart';
import '../../../providers/daily_intake_provider.dart';
import '../../../providers/training_session_provider.dart';
import '../../../services/coach/coach_cloud_sync_service.dart';

class CoachAuthScreen extends ConsumerStatefulWidget {
  const CoachAuthScreen({super.key});

  @override
  ConsumerState<CoachAuthScreen> createState() => _CoachAuthScreenState();
}

class _CoachAuthScreenState extends ConsumerState<CoachAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isRegisterMode = false;
  bool _passwordObscured = true;
  bool _confirmPasswordObscured = true;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isRegisterMode) {
        await ref.read(coachAuthControllerProvider.notifier).register(
              email: _emailController.text,
              password: _passwordController.text,
            );
      } else {
        await ref.read(coachAuthControllerProvider.notifier).signIn(
              email: _emailController.text,
              password: _passwordController.text,
            );
      }

      await _postAuthBootstrap();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRegisterMode
                ? 'Účet trenéra byl vytvořen.'
                : 'Přihlášení proběhlo úspěšně.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _postAuthBootstrap() async {
    await CoachCloudSyncService.safePullMergeToLocal();

    ref.invalidate(coachClientsControllerProvider);
    ref.invalidate(coachNotesControllerProvider);
    ref.invalidate(coachInbodyControllerProvider);
    ref.invalidate(coachCircumferenceControllerProvider);
    ref.invalidate(coachDiagnosticControllerProvider);
    ref.invalidate(coachGoalControllerProvider);
    ref.invalidate(trainingSessionProvider);
    ref.invalidate(dailyHistoryProvider);
    ref.invalidate(dailyIntakeProvider);
    ref.invalidate(coachSetupProvider);
  }

  String? _validateEmail(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) {
      return 'Zadej e-mail.';
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(text)) {
      return 'Zadej platný e-mail.';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    final text = value ?? '';
    if (text.isEmpty) {
      return 'Zadej heslo.';
    }
    if (text.length < 6) {
      return 'Heslo musí mít alespoň 6 znaků.';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isRegisterMode) return null;

    final text = value ?? '';
    if (text.isEmpty) {
      return 'Potvrď heslo.';
    }
    if (text != _passwordController.text) {
      return 'Hesla se neshodují.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Registrace trenéra' : 'Přihlášení trenéra'),
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
                          _isRegisterMode
                              ? 'Vytvoř účet trenéra'
                              : 'Přihlas se do coach cloudu',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isRegisterMode
                              ? 'Každý trenér má vlastní účet a vlastní cloud prostor pro klienty, poznámky a měření.'
                              : 'Přihlas se svým e-mailem a heslem. Po přihlášení uvidíš jen svá vlastní coach data.',
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          decoration: const InputDecoration(
                            labelText: 'E-mail',
                            border: OutlineInputBorder(),
                          ),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _passwordObscured,
                          textInputAction: _isRegisterMode
                              ? TextInputAction.next
                              : TextInputAction.done,
                          decoration: InputDecoration(
                            labelText: 'Heslo',
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordObscured = !_passwordObscured;
                                });
                              },
                              icon: Icon(
                                _passwordObscured
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                          ),
                          validator: _validatePassword,
                          onFieldSubmitted: (_) {
                            if (!_isRegisterMode && !_isSubmitting) {
                              _submit();
                            }
                          },
                        ),
                        if (_isRegisterMode) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _confirmPasswordObscured,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: 'Potvrzení hesla',
                              border: const OutlineInputBorder(),
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _confirmPasswordObscured =
                                        !_confirmPasswordObscured;
                                  });
                                },
                                icon: Icon(
                                  _confirmPasswordObscured
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                              ),
                            ),
                            validator: _validateConfirmPassword,
                            onFieldSubmitted: (_) {
                              if (!_isSubmitting) {
                                _submit();
                              }
                            },
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting ? null : _submit,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : Text(
                                    _isRegisterMode
                                        ? 'Vytvořit účet'
                                        : 'Přihlásit se',
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(
                          child: TextButton(
                            onPressed: _isSubmitting
                                ? null
                                : () {
                                    setState(() {
                                      _isRegisterMode = !_isRegisterMode;
                                    });
                                  },
                            child: Text(
                              _isRegisterMode
                                  ? 'Už máš účet? Přihlásit se'
                                  : 'Nemáš účet? Vytvořit registraci',
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