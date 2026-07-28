import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key, this.initialEmail = ''});

  final String initialEmail;

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _sending = false;

  static const _neutralSuccess =
      'Если аккаунт с таким email существует, письмо для сброса пароля отправлено.';

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (!appUsesFirebaseBackend) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Сброс пароля недоступен в демо-режиме')),
      );
      return;
    }

    final email = _emailController.text.trim();
    setState(() => _sending = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(_neutralSuccess)));
      Navigator.of(context).maybePop();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      if (e.code == 'invalid-email') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Некорректный email'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        return;
      }
      // Google-only / wrong provider — явное сообщение (не anti-enumeration риск).
      if (e.code == 'wrong-provider' ||
          e.code == 'account-exists-with-different-credential' ||
          (e.message?.toLowerCase().contains('google') ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Этот аккаунт использует вход через Google, сброс пароля не требуется',
            ),
          ),
        );
        return;
      }
      // user-not-found и прочие — нейтральный текст (anti-enumeration).
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(_neutralSuccess)));
      Navigator.of(context).maybePop();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text(_neutralSuccess)));
      Navigator.of(context).maybePop();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Сброс пароля')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Укажите email — мы отправим ссылку для сброса пароля.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
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
              const SizedBox(height: 24),
              if (_sending)
                const Center(child: CircularProgressIndicator())
              else
                FilledButton(
                  onPressed: _send,
                  child: const Text('Отправить письмо для сброса'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
