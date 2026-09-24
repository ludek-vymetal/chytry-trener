import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';

import '../../../providers/coach/coach_auth_provider.dart';

class CoachAuthScreen
    extends ConsumerStatefulWidget {
  const CoachAuthScreen({
    super.key,
  });

  @override
  ConsumerState<CoachAuthScreen>
      createState() =>
          _CoachAuthScreenState();
}

class _CoachAuthScreenState
    extends ConsumerState<CoachAuthScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _emailController =
      TextEditingController();

  final _passwordController =
      TextEditingController();

  final _confirmPasswordController =
      TextEditingController();

  bool _isRegisterMode = false;

  bool _passwordObscured = true;

  bool _confirmPasswordObscured =
      true;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final l10n =
        AppLocalizations.of(context)!;

    if (!(_formKey.currentState
            ?.validate() ??
        false)) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      if (_isRegisterMode) {
        await ref
            .read(
              coachAuthControllerProvider
                  .notifier,
            )
            .register(
              email:
                  _emailController.text,
              password:
                  _passwordController
                      .text,
            );
      } else {
        await ref
            .read(
              coachAuthControllerProvider
                  .notifier,
            )
            .signIn(
              email:
                  _emailController.text,
              password:
                  _passwordController
                      .text,
            );
      }

      // Synchronizaci a obnovu dat po přihlášení řeší CoachSessionBootstrap
      // (app.dart), jakmile se změní stav přihlášení.

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            _isRegisterMode
                ? l10n
                    .coachAccountCreated
                : l10n
                    .loginSuccessful,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
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

  Future<void> _forgotPassword() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetEnterEmail)),
      );
      return;
    }

    try {
      await ref
          .read(coachAuthControllerProvider.notifier)
          .sendPasswordReset(email);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetSent(email))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.passwordResetFailed(e.toString()))),
      );
    }
  }

  String? _validateEmail(
    String? value,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    final text =
        value?.trim() ?? '';

    if (text.isEmpty) {
      return l10n.enterEmail;
    }

    if (!RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(text)) {
      return l10n.enterValidEmail;
    }

    return null;
  }

  String? _validatePassword(
    String? value,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    final text = value ?? '';

    if (text.isEmpty) {
      return l10n.enterPassword;
    }

    if (text.length < 6) {
      return l10n.passwordTooShort;
    }

    return null;
  }

  String? _validateConfirmPassword(
    String? value,
  ) {
    final l10n =
        AppLocalizations.of(context)!;

    if (!_isRegisterMode) {
      return null;
    }

    final text = value ?? '';

    if (text.isEmpty) {
      return l10n.confirmPassword;
    }

    if (text !=
        _passwordController.text) {
      return l10n.passwordsDoNotMatch;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n =
        AppLocalizations.of(context)!;

    final theme =
        Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isRegisterMode
              ? l10n.coachRegistration
              : l10n.coachLogin,
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 560,
            ),

            child:
                SingleChildScrollView(
              padding:
                  const EdgeInsets.all(
                16,
              ),

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
                          _isRegisterMode
                              ? l10n
                                  .createCoachAccount
                              : l10n
                                  .loginToCoachCloud,

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

                        Text(
                          _isRegisterMode
                              ? l10n
                                  .coachAccountDescription
                              : l10n
                                  .coachLoginDescription,

                          style: theme
                              .textTheme
                              .bodyLarge,
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        TextFormField(
                          controller:
                              _emailController,

                          keyboardType:
                              TextInputType
                                  .emailAddress,

                          textInputAction:
                              TextInputAction
                                  .next,

                          decoration:
                              InputDecoration(
                            labelText:
                                l10n.email,

                            border:
                                const OutlineInputBorder(),
                          ),

                          validator:
                              _validateEmail,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        TextFormField(
                          controller:
                              _passwordController,

                          obscureText:
                              _passwordObscured,

                          textInputAction:
                              _isRegisterMode
                                  ? TextInputAction
                                      .next
                                  : TextInputAction
                                      .done,

                          decoration:
                              InputDecoration(
                            labelText:
                                l10n.password,

                            border:
                                const OutlineInputBorder(),

                            suffixIcon:
                                IconButton(
                              onPressed: () {
                                setState(() {
                                  _passwordObscured =
                                      !_passwordObscured;
                                });
                              },

                              icon: Icon(
                                _passwordObscured
                                    ? Icons
                                        .visibility_off
                                    : Icons
                                        .visibility,
                              ),
                            ),
                          ),

                          validator:
                              _validatePassword,

                          onFieldSubmitted:
                              (_) {
                            if (!_isRegisterMode &&
                                !_isSubmitting) {
                              _submit();
                            }
                          },
                        ),

                        if (_isRegisterMode)
                          ...[
                            const SizedBox(
                              height: 16,
                            ),

                            TextFormField(
                              controller:
                                  _confirmPasswordController,

                              obscureText:
                                  _confirmPasswordObscured,

                              textInputAction:
                                  TextInputAction
                                      .done,

                              decoration:
                                  InputDecoration(
                                labelText:
                                    l10n
                                        .confirmPasswordLabel,

                                border:
                                    const OutlineInputBorder(),

                                suffixIcon:
                                    IconButton(
                                  onPressed:
                                      () {
                                    setState(
                                      () {
                                        _confirmPasswordObscured =
                                            !_confirmPasswordObscured;
                                      },
                                    );
                                  },

                                  icon:
                                      Icon(
                                    _confirmPasswordObscured
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                ),
                              ),

                              validator:
                                  _validateConfirmPassword,

                              onFieldSubmitted:
                                  (_) {
                                if (!_isSubmitting) {
                                  _submit();
                                }
                              },
                            ),
                          ],

                        const SizedBox(
                          height: 20,
                        ),

                        SizedBox(
                          width:
                              double.infinity,

                          child:
                              FilledButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : _submit,

                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth:
                                          2.4,
                                    ),
                                  )
                                : Text(
                                    _isRegisterMode
                                        ? l10n
                                            .createAccount
                                        : l10n
                                            .signIn,
                                  ),
                          ),
                        ),

                        const SizedBox(
                          height: 12,
                        ),

                        if (!_isRegisterMode)
                          Center(
                            child: TextButton(
                              onPressed:
                                  _isSubmitting ? null : _forgotPassword,
                              child: Text(l10n.forgotPassword),
                            ),
                          ),

                        Center(
                          child:
                              TextButton(
                            onPressed:
                                _isSubmitting
                                    ? null
                                    : () {
                                        setState(
                                          () {
                                            _isRegisterMode =
                                                !_isRegisterMode;
                                          },
                                        );
                                      },

                            child: Text(
                              _isRegisterMode
                                  ? l10n
                                      .alreadyHaveAccount
                                  : l10n
                                      .dontHaveAccount,
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