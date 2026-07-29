import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/core/ui/app_feedback.dart';
import 'package:eventa/src/features/auth/data/google_sign_in_helper.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:eventa/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'email-already-in-use':
          return 'Этот email уже зарегистрирован. Войдите или восстановите пароль.';
        case 'invalid-email':
          return 'Некорректный email.';
        case 'weak-password':
          return 'Пароль слишком слабый (минимум 6 символов).';
        case 'operation-not-allowed':
          return 'Регистрация по email отключена в Firebase Console.';
        case 'network-request-failed':
          return 'Нет сети. Проверьте подключение.';
        case 'account-exists-with-different-credential':
          return error.message ??
              'Email уже занят другим способом входа. Войдите через email/пароль.';
        case 'google-sign-in-cancelled':
          return 'Регистрация через Google отменена.';
        case 'google-id-token-missing':
        case 'google-sign-in-failed':
          return error.message ?? googleSignInUserMessage(error);
        default:
          return error.message ?? 'Не удалось создать аккаунт.';
      }
    }
    return googleSignInUserMessage(error);
  }

  Future<void> _finishAuthSuccess() async {
    if (!mounted) return;
    context.read<AuthBloc>().add(AuthCheckRequested());
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);
    try {
      await getIt<AuthRepository>().registerWithEmailAndPassword(
        _emailController.text,
        _passwordController.text,
      );
      await _finishAuthSuccess();
    } catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          _errorMessage(e),
          isError: true,
          details: googleSignInErrorDetails(e),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await getIt<AuthRepository>().signInWithGoogle();
      await _finishAuthSuccess();
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
        } else if (e is FirebaseAuthException &&
            e.code == 'google-sign-in-cancelled') {
          showAppSnackBar(context, 'Регистрация через Google отменена');
        } else {
          showAppSnackBar(
            context,
            _errorMessage(e),
            isError: true,
            details: googleSignInErrorDetails(e),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Регистрация')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: AbsorbPointer(
                    absorbing: _isLoading,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                        Text(
                          'Создайте аккаунт',
                          style: Theme.of(context).textTheme.headlineSmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'После регистрации заполним профиль за минуту.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        OutlinedButton.icon(
                          onPressed: _registerWithGoogle,
                          icon: const Icon(Icons.g_mobiledata),
                          label: const Text('Продолжить с Google'),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                'или email',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(labelText: 'Email'),
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty || !v.contains('@')) {
                              return 'Введите корректный email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Пароль',
                            helperText: 'Минимум 6 символов',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscurePassword = !_obscurePassword,
                                );
                              },
                            ),
                          ),
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.newPassword],
                          validator: (value) {
                            if (value == null || value.length < 6) {
                              return 'Пароль не короче 6 символов';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _confirmController,
                          decoration: InputDecoration(
                            labelText: 'Повторите пароль',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () {
                                setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                );
                              },
                            ),
                          ),
                          obscureText: _obscureConfirm,
                          validator: (value) {
                            if (value != _passwordController.text) {
                              return 'Пароли не совпадают';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        if (_isLoading)
                          const Center(child: CircularProgressIndicator())
                        else
                          FilledButton(
                            onPressed: _register,
                            child: const Text('Зарегистрироваться'),
                          ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: () => Navigator.of(context).maybePop(),
                          child: const Text('Уже есть аккаунт? Войти'),
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
      ),
    );
  }
}
