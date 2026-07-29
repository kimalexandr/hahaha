import 'package:eventa/src/core/constants/google_oauth_config.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Google Sign-In 6.x + Firebase Auth (стабильнее, чем v7 Credential Manager на CI APK).
GoogleSignIn createGoogleSignIn() {
  return GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: kGoogleSignInWebClientId,
  );
}

/// Сообщение для пользователя при типичных сбоях Google Sign-In на Android.
String googleSignInUserMessage(Object error) {
  final text = error.toString();
  if (text.contains('ApiException: 10') ||
      text.contains('DEVELOPER_ERROR') ||
      text.contains('developer_error')) {
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
  if (text.contains('reauth') ||
      text.contains('[16]') ||
      text.contains('Account reauth failed')) {
    return 'Не удалось войти через Google. Проверьте SHA CI в Firebase, '
        'google-services.json и APK из последней сборки Actions. Детали: $text';
  }
  if (text.contains('sign_in_canceled') ||
      text.contains('canceled') ||
      text.contains('cancelled')) {
    return 'Вход через Google отменён.';
  }
  return 'Ошибка входа через Google: $text';
}
