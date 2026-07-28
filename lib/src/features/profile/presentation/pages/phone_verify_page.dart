import 'package:eventa/src/core/app_runtime_config.dart';
import 'package:eventa/src/core/di/injection.dart';
import 'package:eventa/src/features/auth/domain/repositories/auth_repository.dart';
import 'package:eventa/src/features/profile/data/profile_persistence.dart';
import 'package:eventa/src/features/profile/domain/entities/user_profile.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Подтверждение телефона: Firebase Phone Auth или симуляция в демо.
class PhoneVerifyPage extends StatefulWidget {
  const PhoneVerifyPage({super.key, this.allowSkip = true});

  final bool allowSkip;

  @override
  State<PhoneVerifyPage> createState() => _PhoneVerifyPageState();
}

class _PhoneVerifyPageState extends State<PhoneVerifyPage> {
  final _phoneController = TextEditingController(text: '+7');
  final _codeController = TextEditingController();
  final _persistence = ProfilePersistence();

  String? _verificationId;
  bool _codeSent = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _markVerifiedLocally() async {
    final uid = await getIt<AuthRepository>().currentUserId() ?? 'user-1';
    final existing = await _persistence.read(uid);
    final now = DateTime.now();
    final profile =
        (existing ??
                UserProfile(
                  id: uid,
                  createdAt: now,
                  ownerId: uid,
                  name: 'Пользователь',
                  bio: '',
                  role: 'user',
                ))
            .copyWith(phoneVerified: true, phoneVerifiedAt: now);
    await _persistence.save(profile);
  }

  Future<void> _simulateDemoVerify() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _markVerifiedLocally();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sendCode() async {
    final phone = _phoneController.text.trim();
    if (phone.length < 10) {
      setState(() => _error = 'Введите номер в международном формате');
      return;
    }
    if (!appUsesFirebaseBackend) {
      await _simulateDemoVerify();
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: phone,
        verificationCompleted: (credential) async {
          await _linkOrSignIn(credential);
        },
        verificationFailed: (e) {
          if (!mounted) return;
          setState(() {
            _busy = false;
            _error = e.message ?? e.code;
          });
        },
        codeSent: (verificationId, _) {
          if (!mounted) return;
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _busy = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _confirmCode() async {
    final id = _verificationId;
    final code = _codeController.text.trim();
    if (id == null || code.isEmpty) {
      setState(() => _error = 'Введите код из SMS');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: code,
      );
      await _linkOrSignIn(credential);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _linkOrSignIn(PhoneAuthCredential credential) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await user.linkWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'credential-already-in-use' ||
            e.code == 'provider-already-linked') {
          // Уже привязан — считаем достаточным.
        } else {
          rethrow;
        }
      }
    } else {
      await FirebaseAuth.instance.signInWithCredential(credential);
    }
    await _markVerifiedLocally();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Подтверждение телефона')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            appUsesFirebaseBackend
                ? 'Подтвердите номер — так другим проще доверять встрече.'
                : 'Демо-режим: SMS недоступен. Можно симулировать подтверждение.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_codeSent,
            decoration: const InputDecoration(
              labelText: 'Телефон',
              hintText: '+7...',
              border: OutlineInputBorder(),
            ),
          ),
          if (_codeSent) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Код из SMS',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 24),
          if (_busy)
            const Center(child: CircularProgressIndicator())
          else ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _codeSent ? _confirmCode : _sendCode,
                child: Text(
                  !appUsesFirebaseBackend
                      ? 'Симулировать подтверждение'
                      : (_codeSent ? 'Подтвердить код' : 'Отправить SMS'),
                ),
              ),
            ),
            if (widget.allowSkip) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Пропустить'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
