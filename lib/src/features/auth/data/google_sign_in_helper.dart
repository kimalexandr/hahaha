import 'package:eventa/src/core/constants/google_oauth_config.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In 6.x + Firebase Auth (стабильнее, чем v7 Credential Manager на CI APK).
GoogleSignIn createGoogleSignIn() {
  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: kGoogleSignInWebClientId,
  );
}

bool _isGoogleDeveloperError(String text) {
  final lower = text.toLowerCase();
  // В release класс ApiException часто обфусцирован: "api.j: 10:".
  return lower.contains('developer_error') ||
      RegExp(r'(apiexception|api\.[a-z]):\s*10\b').hasMatch(lower) ||
      RegExp(r':\s*10:\s*,').hasMatch(lower) ||
      (lower.contains('sign_in_failed') &&
          RegExp(r'\b10\b').hasMatch(lower) &&
          !lower.contains('12501'));
}

bool _isGoogleReauthError(String text) {
  final lower = text.toLowerCase();
  return lower.contains('reauth') ||
      lower.contains('account reauth failed') ||
      RegExp(r'(apiexception|api\.[a-z]|\[):?\s*16\b').hasMatch(lower);
}

bool isGoogleSignInCancelled(Object error) {
  final text = error.toString().toLowerCase();
  if (_isGoogleReauthError(text) || _isGoogleDeveloperError(text)) {
    return false;
  }
  return text.contains('sign_in_canceled') ||
      text.contains('sign_in_cancelled') ||
      text.contains('canceled') ||
      text.contains('cancelled') ||
      text.contains('12501');
}

bool shouldFallbackToFirebaseGoogleProvider(Object error) {
  if (isGoogleSignInCancelled(error)) return false;
  final text = error.toString();
  return _isGoogleDeveloperError(text) ||
      _isGoogleReauthError(text) ||
      text.contains('google-id-token-missing') ||
      text.contains('idToken') ||
      text.contains('network_error') ||
      text.contains('sign_in_failed') ||
      text.contains('12500') ||
      RegExp(r'(ApiException|api\.[a-z]):\s*7\b').hasMatch(text);
}

class GoogleSignInErrorInfo {
  const GoogleSignInErrorInfo({
    required this.title,
    required this.cause,
    required this.fix,
    required this.raw,
  });

  final String title;
  final String cause;
  final String fix;
  final String raw;
}

GoogleSignInErrorInfo googleSignInErrorInfo(Object error) {
  final text = error.toString();
  if (_isGoogleDeveloperError(text)) {
    return GoogleSignInErrorInfo(
      title: 'Google Sign-In: код 10 (DEVELOPER_ERROR)',
      cause:
          'Причина: подпись APK (SHA-1) не совпадает с той, что зарегистрирована '
          'в Firebase / Google Cloud для package com.eventus.app.\n'
          'Чаще всего так бывает, если APK собран в GitHub Actions с новым '
          'keystore, а в Firebase остался старый отпечаток.',
      fix:
          'Что исправить:\n'
          '1) GitHub Actions → артефакт android-signing-report → скопируйте SHA1\n'
          '2) Firebase → Project settings → Android app → Add fingerprint\n'
          '3) Скачайте новый google-services.json в android/app/\n'
          '4) Закоммитьте, дождитесь новой сборки Actions\n'
          '5) Удалите старое приложение с телефона и поставьте новый APK',
      raw: text,
    );
  }
  if (text.contains('certificate hash') ||
      text.contains('INVALID_CERT_HASH') ||
      text.contains('invalid cert')) {
    return GoogleSignInErrorInfo(
      title: 'Google Sign-In: неверная подпись APK',
      cause:
          'Причина: Firebase/Google не смогли проверить certificate hash '
          'установленного приложения.',
      fix:
          'Что исправить:\n'
          'Установите APK из последней успешной сборки Actions, проверьте SHA '
          'в Firebase и актуальный google-services.json.',
      raw: text,
    );
  }
  if (_isGoogleReauthError(text)) {
    return GoogleSignInErrorInfo(
      title: 'Google Sign-In: код 16 (reauth failed)',
      cause:
          'Причина: сбой повторной авторизации Google — обычно из‑за неверного '
          'OAuth/SHA или устаревшего google-services.json.',
      fix:
          'Что исправить:\n'
          'Проверьте SHA CI и debug в Firebase, скачайте google-services.json, '
          'переустановите свежий APK.',
      raw: text,
    );
  }
  if (text.contains('google-id-token-missing') || text.contains('idToken')) {
    return GoogleSignInErrorInfo(
      title: 'Google Sign-In: нет idToken',
      cause:
          'Причина: Google не вернул idToken для Firebase Auth. Обычно неверный '
          'Web Client ID (serverClientId / default_web_client_id).',
      fix:
          'Что исправить:\n'
          'В google-services.json должен быть client_type: 3 (Web client), '
          'тот же ID в strings.xml default_web_client_id.',
      raw: text,
    );
  }
  if (isGoogleSignInCancelled(error)) {
    return const GoogleSignInErrorInfo(
      title: 'Вход через Google отменён',
      cause: 'Причина: вход закрыт на экране выбора аккаунта Google.',
      fix: 'Что сделать: нажмите «Войти через Google» ещё раз и выберите аккаунт.',
      raw: '',
    );
  }
  debugPrint('Google Sign-In error: $text');
  return GoogleSignInErrorInfo(
    title: 'Не удалось войти через Google',
    cause: 'Причина: неизвестная ошибка Google / Firebase Auth.',
    fix:
        'Что исправить:\n'
        'Проверьте интернет, SHA в Firebase, google-services.json и что '
        'провайдер Google включён в Authentication → Sign-in method.',
    raw: text,
  );
}

/// Короткий текст для SnackBar / message у FirebaseAuthException.
String googleSignInUserMessage(Object error) {
  final info = googleSignInErrorInfo(error);
  return '${info.title}. ${info.cause.split('\n').first}';
}

/// Полный текст (причина + исправление + raw) для диалога.
String googleSignInErrorDetails(Object error) {
  final info = googleSignInErrorInfo(error);
  final buf = StringBuffer()
    ..writeln(info.cause)
    ..writeln()
    ..writeln(info.fix);
  if (info.raw.isNotEmpty) {
    buf
      ..writeln()
      ..writeln('Технические детали:')
      ..writeln(info.raw);
  }
  return buf.toString();
}

/// Показывает ошибку Google понятным диалогом (причина + что исправить).
Future<void> showGoogleSignInErrorDialog(
  BuildContext context,
  Object error,
) async {
  final info = googleSignInErrorInfo(error);
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(info.title),
        content: SingleChildScrollView(
          child: SelectableText(
            [
              info.cause,
              '',
              info.fix,
              if (info.raw.isNotEmpty) ...['', 'Технические детали:', info.raw],
            ].join('\n'),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Понятно'),
          ),
        ],
      );
    },
  );
}
