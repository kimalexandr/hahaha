import 'package:eventa/src/core/constants/google_oauth_config.dart';
import 'package:flutter/foundation.dart';
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

/// Сообщение для пользователя при типичных сбоях Google Sign-In на Android.
String googleSignInUserMessage(Object error) {
  final text = error.toString();
  if (_isGoogleDeveloperError(text)) {
    return 'Ошибка настройки Google Sign-In (код 10). Добавьте SHA-1/SHA-256 '
        'подписи APK в Firebase → Project settings → Your apps, скачайте '
        'новый google-services.json и пересоберите приложение. Детали: $text';
  }
  if (text.contains('certificate hash') ||
      text.contains('INVALID_CERT_HASH') ||
      text.contains('invalid cert')) {
    return 'Firebase не смог проверить подпись APK. Установите APK из последней '
        'сборки GitHub Actions (не старую), проверьте SHA CI в Firebase и '
        'google-services.json. Детали: $text';
  }
  if (_isGoogleReauthError(text)) {
    return 'Не удалось войти через Google (код 16). Проверьте SHA CI/debug в '
        'Firebase, актуальный google-services.json и переустановите APK. '
        'Детали: $text';
  }
  if (isGoogleSignInCancelled(error)) {
    return 'Вход через Google отменён.';
  }
  debugPrint('Google Sign-In error: $text');
  return 'Ошибка входа через Google: $text';
}
