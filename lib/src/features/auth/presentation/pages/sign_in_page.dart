import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/core/ui/app_feedback.dart';
import 'package:eventa/src/features/auth/data/google_sign_in_helper.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:eventa/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:eventa/src/features/auth/presentation/pages/register_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_formKey.currentState?.validate() ?? false) {
      await _performSignIn(
        () => getIt<AuthRepository>().signInWithEmailAndPassword(
          _emailController.text,
          _passwordController.text,
        ),
      );
    }
  }

  Future<void> _signInWithGoogle() async {
    await _performSignIn(() => getIt<AuthRepository>().signInWithGoogle());
  }

  String _signInErrorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return 'Неверный email или пароль.';
        case 'invalid-email':
          return 'Некорректный email.';
        case 'user-disabled':
          return 'Аккаунт отключён.';
        case 'too-many-requests':
          return 'Слишком много попыток. Подождите немного.';
        case 'network-request-failed':
          return 'Нет сети. Проверьте подключение.';
        case 'account-exists-with-different-credential':
          return error.message ?? 'Email уже занят другим способом входа.';
        case 'google-sign-in-cancelled':
          return 'Вход через Google отменён.';
        case 'google-id-token-missing':
        case 'google-sign-in-failed':
          return error.message ?? googleSignInUserMessage(error);
        default:
          if (error.message != null) return error.message!;
      }
    }
    return googleSignInUserMessage(error);
  }

  Future<void> _performSignIn(Future<void> Function() signInMethod) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await signInMethod();
      if (!mounted) return;
      context.read<AuthBloc>().add(AuthCheckRequested());
    } catch (e) {
      if (mounted) {
        final text = e.toString().toLowerCase();
        final isGoogleConfigError =
            (e is FirebaseAuthException &&
                (e.code == 'google-sign-in-failed' ||
                    e.code == 'google-id-token-missing')) ||
            text.contains('sign_in_failed') ||
            text.contains('apiexception') ||
            text.contains('developer_error') ||
            text.contains('reauth');
        if (isGoogleConfigError) {
          await showGoogleSignInErrorDialog(context, e);
        } else {
          showAppSnackBar(
            context,
            _signInErrorMessage(e),
            isError: true,
            details: googleSignInErrorDetails(e),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _openRegister() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const RegisterPage()));
  }

  void _openForgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (_) =>
                ForgotPasswordPage(initialEmail: _emailController.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: AbsorbPointer(
                absorbing: _isLoading,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      Text(
                        'Eventa',
                        style: Theme.of(context).textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Вход в аккаунт',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 26),
                      ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: const Icon(Icons.g_mobiledata),
                        label: const Text('Войти через Google'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: _openRegister,
                        child: const Text('Нет аккаунта? Зарегистрироваться'),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            child: Text(
                              'или email',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                              ),
                              keyboardType: TextInputType.emailAddress,
                              autofillHints: const [AutofillHints.email],
                              validator: (value) {
                                if (value == null || !value.contains('@')) {
                                  return 'Введите корректный email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Пароль',
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    );
                                  },
                                ),
                              ),
                              obscureText: _obscurePassword,
                              autofillHints: const [AutofillHints.password],
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Введите пароль';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else ...[
                        ElevatedButton(
                          onPressed: _signInWithEmail,
                          child: const Text('Войти'),
                        ),
                        const SizedBox(height: 8),
                        if (appUsesFirebaseBackend)
                          TextButton(
                            onPressed: _openForgotPassword,
                            child: const Text('Забыли пароль?'),
                          )
                        else
                          Text(
                            'Сброс пароля недоступен в демо-режиме',
                            textAlign: TextAlign.center,
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(
                              color:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
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
